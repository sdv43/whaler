class Utils.Theme : Object {
    public Gtk.CssProvider style_provider;

    public Theme () {
        this.style_provider = new Gtk.CssProvider ();
    }

    private string get_css () {
        Value property_value = Value (typeof(string));
        var distro = this.get_distro ();
        var mode = this.is_dark_mode () ? "_dark" : "_light";
        var property_name = distro + mode;

        var css_styles = new CssStyles ();
        css_styles.get_property (property_name, ref property_value);

        return property_value.get_string ();
    }

    private string get_distro () {
        return "elementary";
    }

    private bool is_dark_mode () {
        var settings_granite = Granite.Settings.get_default ();
        var settings_gtk = Gtk.Settings.get_default ();

        assert_nonnull (settings_gtk);

        var is_dark = settings_granite.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        settings_gtk.gtk_application_prefer_dark_theme = is_dark;

        return is_dark;
    }

    public void apply_styles (Gdk.Screen screen) throws Error {
        var css = this.get_css ();

        this.style_provider.load_from_data (css, css.length);
        Gtk.StyleContext.add_provider_for_screen (
            screen,
            this.style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
}
