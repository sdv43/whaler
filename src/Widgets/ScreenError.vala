class Widgets.ScreenError : Gtk.Grid {
    public static string CODE = "error";

    public ScreenError () {
        this.get_style_context ().add_class ("screen-error");
        this.valign = Gtk.Align.CENTER;
        this.halign = Gtk.Align.CENTER;
    }

    //  public void show_error (string error, string description) {
    //      this.foreach ((child) => {
    //          this.remove (child);
    //      });

    //      var alert = new Granite.Widgets.AlertView (error, description, "dialog-error");
    //      alert.get_style_context ().add_class ("alert");
    //      this.add (alert);

    //      this.show_all ();
    //  }

    public void show_widget (Gtk.Widget widget) {
        this.foreach ((child) => {
            this.remove (child);
        });

        this.add (widget);
        this.show_all ();
    }

    public static Gtk.Widget build_error_docker_not_avialable (bool no_entry) {
        var description = _ (
            "It looks like Docker requires root rights to use it. Thus, the application " +
            "cannot connect to Docker Engine API. Find out how to run docker without root " +
            "rights in <a href=\"https://docs.docker.com/engine/install/linux-postinstall/" +
            "\">Docker Manuals</a>, otherwise the application cannot work correctly. " +
            "Or check your socket path to Docker API in Settings."
        );

        if (no_entry) {
            description = _ (
                "It looks like Docker is not installed on your system. " +
                "To find out how to install it, see <a href=\"https://docs.docker.com/engine/" +
                "install/\">Docker Manuals</a>. " +
                "Or check your socket path to Docker API in Settings."
            );
        }

        var alert = new Granite.Widgets.AlertView (
            _ ("The app cannot connect to Docker API"),
            description,
            "dialog-error"
        );

        alert.get_style_context ().add_class ("alert");
        alert.show_action (_ ("Open settings"));
        alert.action_activated.connect (() => {
            new Utils.SettingsDialog ();
        });

        return alert;
    }
}
