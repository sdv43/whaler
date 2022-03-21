class Utils.Theme : Object {
    public Gtk.CssProvider style_provider;

    public Theme () {
        this.style_provider = new Gtk.CssProvider ();
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
        var distro = this.get_distro ();
        var mode = this.is_dark_mode () ? "dark" : "light";

        this.style_provider.load_from_resource (@"$RESOURCE_BASE/style/dist/$distro-$mode.css");

        Gtk.StyleContext.add_provider_for_screen (
            screen,
            this.style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
}
