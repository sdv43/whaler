import os
import shutil
import subprocess
import uuid
from pathlib import Path

import pytest
from gi.repository import GLib

import docker_helpers
from docker_helpers import Containers
from whaler_ui import APP_NAME, Atspi, WhalerApp

ROOT = Path(__file__).resolve().parents[2]
ARTIFACTS = Path(__file__).resolve().parent / "artifacts"
SETTINGS_GROUP = "com/github/sdv43/whaler"


def pytest_configure(config):
    if not os.environ.get("DISPLAY") or not os.environ.get("DBUS_SESSION_BUS_ADDRESS"):
        raise pytest.UsageError("Run the UI tests with tests/ui/run.sh, it starts Xvfb and a D-Bus session")


def pytest_unconfigure(config):
    # disconnect from the accessibility bus before the D-Bus session ends
    Atspi.exit()


@pytest.fixture(scope="session", autouse=True)
def docker_session():
    docker_helpers.pull_images()
    docker_helpers.remove_leftovers()
    yield
    docker_helpers.remove_leftovers()


@pytest.fixture(scope="session")
def schema_dir(tmp_path_factory):
    path = tmp_path_factory.mktemp("schemas")
    shutil.copy(ROOT / "data" / "gschema.xml", path / f"{APP_NAME}.gschema.xml")
    subprocess.run(["glib-compile-schemas", str(path)], check=True)
    return path


@pytest.fixture
def containers(tmp_path):
    """Throwaway containers of the test, named '<prefix>-<suffix>'."""
    containers = Containers(f"{docker_helpers.PREFIX}-{uuid.uuid4().hex[:6]}", tmp_path)
    yield containers
    containers.cleanup()


class Settings:
    """Whaler settings stored in a keyfile of the test, so the user's settings are not touched."""

    def __init__(self, config_dir):
        self.path = config_dir / "glib-2.0" / "settings" / "keyfile"

    def write(self, values):
        keyfile = GLib.KeyFile()
        for key, value in values.items():
            keyfile.set_value(SETTINGS_GROUP, key, self._to_variant(value).print_(False))
        self.path.parent.mkdir(parents=True, exist_ok=True)
        keyfile.save_to_file(str(self.path))

    def read(self):
        keyfile = GLib.KeyFile()
        keyfile.load_from_file(str(self.path), GLib.KeyFileFlags.NONE)
        keys, _ = keyfile.get_keys(SETTINGS_GROUP)
        return {key: GLib.Variant.parse(None, keyfile.get_value(SETTINGS_GROUP, key), None, None).unpack() for key in keys}

    @staticmethod
    def _to_variant(value):
        if isinstance(value, bool):
            return GLib.Variant("b", value)
        if isinstance(value, int):
            return GLib.Variant("i", value)
        if isinstance(value, tuple):
            return GLib.Variant("(ii)", value)
        return GLib.Variant("s", value)


@pytest.fixture
def settings(tmp_path):
    return Settings(tmp_path / "config")


@pytest.fixture
def launch(schema_dir, settings, containers, tmp_path, request):
    """Start Whaler showing only the containers of the test; returns a WhalerApp."""
    binary = os.environ.get("WHALER_BIN", str(ROOT / "build" / APP_NAME))
    processes = []

    def start(**values):
        if not settings.path.exists():
            settings.write({
                "window-position": (0, 0),
                "window-size": (1000, 700),
                "main-screen-search-term": containers.prefix,
                "docker-api-socket-path": os.environ.get("WHALER_TEST_DOCKER_SOCKET", "/run/docker.sock"),
            })
        if values:
            settings.write({**settings.read(), **{key.replace("_", "-"): value for key, value in values.items()}})

        env = dict(
            os.environ,
            GSETTINGS_BACKEND="keyfile",
            GSETTINGS_SCHEMA_DIR=str(schema_dir),
            XDG_CONFIG_HOME=str(tmp_path / "config"),
            GDK_BACKEND="x11",
            LC_ALL="C.UTF-8",
            LANGUAGE="en",
        )
        log = open(tmp_path / f"whaler-{len(processes) + 1}.log", "w")
        process = subprocess.Popen([binary], env=env, stdout=log, stderr=subprocess.STDOUT)
        processes.append(process)

        app = WhalerApp(process)
        app.wait_loaded()
        return app

    yield start

    for process in processes:
        if process.poll() is None:
            process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()

    if report.when == "call" and report.failed:
        ARTIFACTS.mkdir(exist_ok=True)
        name = item.nodeid.replace("/", "_").replace("::", "-")

        if shutil.which("import"):
            subprocess.run(["import", "-window", "root", str(ARTIFACTS / f"{name}.png")], check=False)

        tmp_path = item.funcargs.get("tmp_path")
        for log in sorted(tmp_path.glob("whaler-*.log")) if tmp_path else []:
            shutil.copy(log, ARTIFACTS / f"{name}-{log.name}")
