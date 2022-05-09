class Widgets.ScreenManager : Gtk.Overlay {

    public ScreenManager () {
        var state = State.Root.get_instance ();
        var stack = new Gtk.Stack ();
        var overlay_bar = new Granite.Widgets.OverlayBar (this);

        stack.transition_type = Gtk.StackTransitionType.OVER_LEFT_RIGHT;
        stack.transition_duration = 300;

        stack.add_named (ScreenError.get_instance (), ScreenError.CODE);
        stack.add_named (new ScreenMain (), ScreenMain.CODE);
        stack.add_named (new ScreenDockerContainer (), ScreenDockerContainer.CODE);

        overlay_bar.active = true;

        stack.show.connect (() => {
            stack.set_visible_child_name (state.active_screen);
        });

        state.notify["active-screen"].connect (() => {
            stack.set_visible_child_name (state.active_screen);
        });

        state.notify["overlay-bar-visible"].connect (() => {
            overlay_bar.label = state.overlay_bar_text;

            Timeout.add (1000, () => {
                overlay_bar.visible = state.overlay_bar_visible;

                return false;
            });
        });

        this.show.connect (() => {
            overlay_bar.visible = false;
        });

        this.add (stack);
    }
}
