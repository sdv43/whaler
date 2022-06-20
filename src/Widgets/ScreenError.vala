class Widgets.ScreenError : Gtk.Grid {
    public static string CODE = "error";

    public ScreenError () {
        this.get_style_context ().add_class ("screen-error");
        this.valign = Gtk.Align.CENTER;
        this.halign = Gtk.Align.CENTER;
    }

    public void show_error (string error, string description) {
        this.foreach ((child) => {
            this.remove (child);
        });

        var alert = new Granite.Widgets.AlertView (error, description, "dialog-error");
        alert.get_style_context ().add_class ("alert");
        this.add (alert);

        this.show_all ();
    }
}
