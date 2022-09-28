using Widgets.Screens.Main;

class Widgets.ScreenMain : Gtk.Box {
    public const string CODE = "main";

    public ScreenMain () {
        this.orientation = Gtk.Orientation.VERTICAL;
        this.spacing = 0;

        this.get_style_context ().add_class ("screen-main");
        this.prepend (new ContainersGridFilter ());
        this.prepend (new ContainersGrid ());
    }
}
