class Widgets.ScreenDockerContainer : Gtk.Box {
    public static string CODE = "docker-container";

    public ScreenDockerContainer () {
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.spacing = 0;

        this.get_style_context ().add_class ("screen-docker-container");
        this.prepend (new Screens.Container.SideBar ());
        this.append (this.build_log_output ());
    }

    private Gtk.Widget build_log_output () {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        box.prepend (new Screens.Container.TopBar ());
        box.append (new Screens.Container.Log ());

        return box;
    }
}
