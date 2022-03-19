class Widgets.ScreenError : Gtk.Grid {
    public static ScreenError? instance;
    public static string CODE = "error";

    private ScreenError () {
        this.get_style_context ().add_class ("screen-error");
        this.valign = Gtk.Align.CENTER;
        this.halign = Gtk.Align.CENTER;
    }

    public static ScreenError get_instance () {
        if (ScreenError.instance == null) {
            ScreenError.instance = new ScreenError ();
        }

        return ScreenError.instance;
    }

    public void show_error_screen (string error, string description) {
        this.foreach ((child) => {
            this.remove (child);
        });

        var alert = new Granite.Widgets.AlertView (error, description, "dialog-error");
        alert.get_style_context ().add_class ("alert");

        this.add (alert);
        this.show_all ();

        State.Root.get_instance ().active_screen = ScreenError.CODE;
    }

    public void show_error_dialog (string title, string description, string icon = "dialog-error") {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            title,
            description,
            icon,
            Gtk.ButtonsType.CLOSE
        );

        message_dialog.run ();
        message_dialog.destroy ();
    }
}
