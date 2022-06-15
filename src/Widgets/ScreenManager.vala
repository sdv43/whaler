class Widgets.ScreenManager : Gtk.Overlay {
    private static ScreenManager? instance;
    private Granite.Widgets.OverlayBar overlay_bar;
    private bool overlay_bar_visible = false;

    private ScreenManager () {
        var state = State.Root.get_instance ();

        this.overlay_bar = new Granite.Widgets.OverlayBar (this);
        this.overlay_bar.active = true;

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.OVER_LEFT_RIGHT;
        stack.transition_duration = 300;
        stack.add_named (ScreenError.get_instance (), ScreenError.CODE);
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
        instance.overlay_bar.label = message;

        Timeout.add (delay, () => {
            instance.overlay_bar.visible = instance.overlay_bar_visible;
            instance.show_all ();

            return false;
        });
    }

    public static void overlay_bar_hide () {
        instance.overlay_bar_visible = false;
        instance.overlay_bar.visible = instance.overlay_bar_visible;
    }

    public static void dialog_error_show (string title, string description, string icon = "dialog-error") {}

    public static void screen_error_show (string error, string description) {}

    public static void screen_error_show_with_widget (string error, Gtk.Widget widget) {}

}
