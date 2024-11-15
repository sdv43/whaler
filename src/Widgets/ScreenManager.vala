/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

class Widgets.ScreenManager : Gtk.Overlay {
    private static ScreenManager? instance;
    private ScreenError screen_error;
    private Granite.Widgets.OverlayBar overlay_bar;
    private bool overlay_bar_visible = false;

    private ScreenManager () {
        var state = State.Root.get_instance ();

        this.overlay_bar = new Granite.Widgets.OverlayBar (this);
        this.overlay_bar.active = true;

        this.screen_error = new ScreenError ();

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.OVER_LEFT_RIGHT;
        stack.transition_duration = 300;
        stack.add_named (this.screen_error, ScreenError.CODE);
        stack.add_named (new ScreenMain (), ScreenMain.CODE);
        stack.add_named (new ScreenDockerContainer (), ScreenDockerContainer.CODE);

        stack.show.connect (() => {
            stack.set_visible_child_name (state.active_screen);
        });

        state.notify["active-screen"].connect (() => {
            stack.set_visible_child_name (state.active_screen);
        });

        this.show.connect (() => {
            this.overlay_bar.visible = this.overlay_bar_visible;
        });

        this.add (stack);
    }

    public static ScreenManager get_instance () {
        if (ScreenManager.instance == null) {
            ScreenManager.instance = new ScreenManager ();
        }

        return ScreenManager.instance;
    }

    public static void overlay_bar_show (string message, int delay = 1000) {
        instance.overlay_bar_visible = true;
        instance.overlay_bar.label = message;

        Timeout.add (delay, () => {
            instance.overlay_bar.visible = instance.overlay_bar_visible;

            return false;
        });
    }

    public static void overlay_bar_hide () {
        instance.overlay_bar_visible = false;
        instance.overlay_bar.visible = instance.overlay_bar_visible;
    }

    public static void dialog_error_show (string title, string description, string icon = "dialog-error") {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            title,
            description,
            icon,
            Gtk.ButtonsType.CLOSE
        );

        message_dialog.transient_for = Whaler.get_instance ().active_window;
        message_dialog.run ();
        message_dialog.destroy ();
    }

    //  public static void screen_error_show (string error, string description) {
    //      instance.screen_error.show_error (error, description);
    //      State.Root.get_instance ().active_screen = ScreenError.CODE;
    //  }

    public static void screen_error_show_widget (Gtk.Widget widget) {
        instance.screen_error.show_widget (widget);
        State.Root.get_instance ().active_screen = ScreenError.CODE;
    }
}
