class Widgets.ScreenDockerContainer : Gtk.Box {
    public static string CODE = "docker-container";

    public ScreenDockerContainer () {
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.spacing = 0;

        this.get_style_context ().add_class ("screen-docker-container");
        this.pack_start (new Screens.Container.SideBar (), false);
        this.pack_end (this.build_log_output (), true, true);
    }

    private Gtk.Widget build_log_output () {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        box.pack_start (new Screens.Container.TopBar (), false);
        box.pack_end (new Screens.Container.Log (), true, true);

        return box;
    }
}
