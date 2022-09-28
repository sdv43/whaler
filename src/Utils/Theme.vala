using Utils.Constants;

class Utils.Theme : Object {
    public Gtk.CssProvider style_provider;

    public Theme () {
        this.style_provider = new Gtk.CssProvider ();
    }

    private string get_stylesheet () {
        var settings_gtk = Gtk.Settings.get_default ();
        var current_icon_theme = settings_gtk.gtk_icon_theme_name;
        var target_theme = "";

        assert_nonnull (settings_gtk);

        switch (current_icon_theme) {
            //  case "Adwaita":
            //      target_theme = "adwaita";
            //      break;

            //  case "Yura":
            //      target_theme = "yura";
            //      break;

            case "elementary":
                target_theme = "elementary";
                break;

            default:
                target_theme = "elementary";
                settings_gtk.gtk_theme_name = "io.elementary.stylesheet.blueberry";
                settings_gtk.gtk_icon_theme_name = "elementary";
                break;
        }

        return target_theme;
    }

    private bool is_dark_mode () {
        var settings_granite = Granite.Settings.get_default ();
        var settings_gtk = Gtk.Settings.get_default ();

        assert_nonnull (settings_gtk);

        var is_dark = settings_granite.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        settings_gtk.gtk_application_prefer_dark_theme = is_dark;

        return is_dark;
    }

    public void apply_styles (Gdk.Display display) {
        var stylesheet = this.get_stylesheet ();
        var mode = this.is_dark_mode () ? "dark" : "light";

        this.style_provider.load_from_resource (@"$RESOURCE_BASE/style/dist/$stylesheet-$mode.css");

        Gtk.StyleContext.add_provider_for_display (
            display,
            this.style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
}
