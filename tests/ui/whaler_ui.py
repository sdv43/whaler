"""Helpers for driving Whaler through the accessibility (AT-SPI) tree.

Widgets are found by their role and accessible name instead of screen coordinates,
so the tests don't depend on the window size, the sorting or the theme.
"""

import time
import warnings

import gi

gi.require_version("Atspi", "2.0")
from gi.repository import Atspi, GLib  # noqa: E402

APP_NAME = "com.github.sdv43.whaler"
DEFAULT_TIMEOUT = 20


class WaitTimeout(AssertionError):
    pass


def wait_for(predicate, message, timeout=DEFAULT_TIMEOUT, interval=0.2):
    """Poll predicate until it returns a truthy value and return that value."""
    deadline = time.monotonic() + timeout
    last_error = None

    while True:
        try:
            result = predicate()
            if result:
                return result
        except GLib.Error as error:
            # the tree changes while it is walked, e.g. cards are rebuilt after a reload
            last_error = error

        if time.monotonic() > deadline:
            details = f" (last error: {last_error.message})" if last_error else ""
            raise WaitTimeout(f"Timed out after {timeout}s waiting for {message}{details}")

        time.sleep(interval)


def display_name(name):
    """Whaler shows container names with the first letter in upper case."""
    return name[:1].upper() + name[1:]


class Node:
    def __init__(self, accessible):
        self.accessible = accessible

    def __repr__(self):
        return f"<Node {self.role} {self.name!r}>"

    @property
    def role(self):
        role = self.accessible.get_role_name()
        # older libatspi versions call buttons "push button"
        return "button" if role == "push button" else role

    @property
    def name(self):
        return self.accessible.get_name()

    @property
    def children(self):
        result = []
        for i in range(self.accessible.get_child_count()):
            child = self.accessible.get_child_at_index(i)
            if child is not None:
                result.append(Node(child))
        return result

    @property
    def showing(self):
        return self.accessible.get_state_set().contains(Atspi.StateType.SHOWING)

    @property
    def sensitive(self):
        return self.accessible.get_state_set().contains(Atspi.StateType.SENSITIVE)

    def find_all(self, role=None, name=None, showing=True):
        """Depth-first search; hidden subtrees (e.g. inactive stack pages) are skipped."""
        found = []

        def walk(node):
            for child in node.children:
                if showing and not child.showing:
                    continue
                if (role is None or child.role == role) and (name is None or child.name == name):
                    found.append(child)
                walk(child)

        walk(self)
        return found

    def find(self, role=None, name=None, showing=True):
        nodes = self.find_all(role, name, showing)
        return nodes[0] if nodes else None

    def wait(self, role=None, name=None, timeout=DEFAULT_TIMEOUT):
        return wait_for(lambda: self.find(role, name), f"[{role}] {name!r}", timeout)

    def labels(self):
        return [node.name for node in self.find_all("label")]

    def action_names(self):
        if "Action" not in self.accessible.get_interfaces():
            return []
        with warnings.catch_warnings():
            # deprecated in newer libatspi, but its replacement is missing in older ones
            warnings.simplefilter("ignore", DeprecationWarning)
            return [Atspi.Action.get_action_name(self.accessible, i) for i in range(self.accessible.get_n_actions())]

    def do_action(self, action_name):
        names = self.action_names()
        assert action_name in names, f"{self} has no {action_name!r} action, only {names}"
        Atspi.Action.do_action(self.accessible, names.index(action_name))

    def click(self):
        """Activate the widget like a user would: via its action, or with the mouse."""
        if "click" in self.action_names():
            self.do_action("click")
        else:
            self.mouse_click()

    def mouse_click(self):
        extents = self.accessible.get_extents(Atspi.CoordType.SCREEN)
        x = extents.x + extents.width // 2
        y = extents.y + extents.height // 2
        assert Atspi.generate_mouse_event(x, y, "b1c"), f"Cannot click {self} at {x},{y}"

    @property
    def text(self):
        return Atspi.Text.get_text(self.accessible, 0, -1)

    def set_text(self, value):
        assert Atspi.EditableText.set_text_contents(self.accessible, value), f"Cannot set text of {self}"


class Card(Node):
    """A container or compose project card on the main screen."""

    @property
    def main_button(self):
        return next(b for b in self.find_all("button") if b.name != "More actions")

    @property
    def status(self):
        """'Running' or 'Paused'; stopped containers show their image instead."""
        labels = [label for label in self.labels() if label in ("Running", "Paused")]
        return labels[0] if labels else None


class WhalerApp:
    def __init__(self, process):
        self.process = process
        self.root = Node(wait_for(self._find_accessible_app, "Whaler to appear in the accessibility tree"))

    def _find_accessible_app(self):
        assert self.process.poll() is None, f"Whaler exited with code {self.process.returncode}"

        desktop = Atspi.get_desktop(0)
        for i in range(desktop.get_child_count()):
            app = desktop.get_child_at_index(i)
            if app is not None and app.get_name() == APP_NAME and app.get_process_id() == self.process.pid:
                return app
        return None

    # windows and dialogs

    @property
    def window(self):
        return wait_for(lambda: self.root.find("frame", showing=False), "the main window")

    def wait_dialog(self, timeout=DEFAULT_TIMEOUT):
        return wait_for(lambda: self.root.find("dialog"), "a dialog", timeout)

    def wait_no_dialog(self, timeout=DEFAULT_TIMEOUT):
        wait_for(lambda: self.root.find("dialog") is None, "the dialog to close", timeout)

    def click_menu_item(self, name):
        self.root.wait("menu item", name).click()

    # main screen

    def wait_loaded(self):
        """Wait until the container list is loaded and the filter is enabled."""
        wait_for(lambda: self.search_entry.sensitive, "the container list to load")

    @property
    def search_entry(self):
        return self.window.wait("text", "Search")

    def search(self, text):
        self.search_entry.set_text(text)

    def cards(self):
        return [Card(node.accessible) for node in self.window.find_all("list item")]

    def card_names(self):
        return [card.name for card in self.cards()]

    def card(self, name, timeout=DEFAULT_TIMEOUT):
        title = display_name(name)
        node = wait_for(lambda: self.window.find("list item", title), f"the card {title!r}", timeout)
        return Card(node.accessible)

    def wait_card_gone(self, name, timeout=DEFAULT_TIMEOUT):
        title = display_name(name)
        wait_for(lambda: self.window.find("list item", title) is None, f"the card {title!r} to disappear", timeout)

    def wait_card_status(self, name, status, timeout=DEFAULT_TIMEOUT):
        """Wait until the card shows the status (None for stopped) and its actions are enabled again."""
        return wait_for(
            lambda: (card := self.card(name)).status == status and card.main_button.sensitive and card,
            f"{display_name(name)!r} to have status {status!r}",
            timeout,
        )

    def container_menu(self, name, item):
        self.card(name).wait("button", "More actions").click()
        self.click_menu_item(item)

    def sorting(self):
        return self.window.wait("combo box").name

    def sort_by(self, name):
        combo = self.window.wait("combo box")
        combo.do_action("press")
        wait_for(lambda: combo.find("menu item", name), f"the {name!r} sorting option").click()
        wait_for(lambda: self.sorting() == name, f"sorting by {name!r}")

    def refresh(self):
        self.window.wait("button", "Update docker container list").click()

    def open_settings(self):
        self.window.wait("button", "Open settings").click()
        return self.wait_dialog()

    def open_card(self, name):
        # cards have no accessible action, click on the title like a user
        self.card(name).wait("label", display_name(name)).mouse_click()
        wait_for(lambda: self.back_button() is not None, "the container screen to open")

    # container screen

    def back_button(self):
        return self.window.find("button", "Back")

    def back(self):
        self.back_button().click()
        wait_for(lambda: self.back_button() is None, "the main screen")

    def log_view(self):
        return wait_for(
            lambda: next((n for n in self.window.find_all("text") if n.name != "Search"), None),
            "the log view",
        )

    def log_lines(self):
        # splitlines() also handles the \r\n line ends of TTY output
        return [line for line in self.log_view().text.splitlines() if line]

    def wait_log(self, predicate, message, timeout=DEFAULT_TIMEOUT):
        return wait_for(lambda: predicate(lines := self.log_lines()) and lines, message, timeout)

    def screen_button(self, name):
        """The Start/Stop/Unpause button of the container screen."""
        return self.window.wait("button", name)

    def screen_menu(self, item):
        self.window.wait("button", "More actions").click()
        self.click_menu_item(item)

    def side_bar(self):
        """Rows of the compose project side bar: the project, the "Services" header, then the services."""
        return [item.labels()[0] for item in self.window.find_all("list item") if item.labels()]

    def select_side_bar_item(self, name):
        title = display_name(name)
        item = wait_for(
            lambda: next((i for i in self.window.find_all("list item") if title in i.labels()), None),
            f"the side bar item {title!r}",
        )
        item.find("label", title).mouse_click()

    def close(self):
        """Close the window with the title bar button, so the window state is saved."""
        self.window.wait("button", "Close").click()
