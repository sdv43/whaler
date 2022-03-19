class Widgets.ScreenManager : Gtk.Overlay {

    public ScreenManager () {
        var state = State.Root.get_instance ();
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

        this.add (stack);
    }
}
