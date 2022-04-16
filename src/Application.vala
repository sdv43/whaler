using Widgets;
using Utils.Sorting;

public class Whaler : Gtk.Application {
    private static Whaler? instance;

    private Whaler () {
        this.application_id = APP_ID;
        this.flags |= ApplicationFlags.FLAGS_NONE;
    }

    public static Whaler get_instance () {
        if (Whaler.instance == null) {
            Whaler.instance = new Whaler ();
        }

        return Whaler.instance;
    }

    public static int main (string[] args) {
        return Whaler.get_instance ().run (args);
    }

    protected override void activate () {
        var window = new Gtk.ApplicationWindow (this) {
            default_height = 800,
            default_width = 1200,
            title = APP_NAME
        };

        window.set_titlebar (new HeaderBar ());
        window.add (new ScreenManager ());

        this.styles (window);
        this.window_state (window);

        window.show_all ();

        State.Root.get_instance ().init.begin ();
    }

    private void window_state (Gtk.Window window) {
        var settings = new Settings (APP_ID);
        int window_x, window_y, window_width, window_height;

        settings.get ("window-position", "(ii)", out window_x, out window_y);
        settings.get ("window-size", "(ii)", out window_width, out window_height);

        window.set_default_size (window_width, window_height);

        if (window_x != -1 || window_y != -1) {
            window.move (window_x, window_y);
        } else {
            window.set_position (Gtk.WindowPosition.CENTER);
        }

        if (settings.get_boolean ("window-is-maximized")) {
            window.maximize ();
        }

        window.delete_event.connect (event => {
            settings.set_boolean ("window-is-maximized", window.is_maximized);

            window.get_position (out window_x, out window_y);
            window.get_size (out window_width, out window_height);

            settings.set ("window-position", "(ii)", window_x, window_y);
            settings.set ("window-size", "(ii)", window_width, window_height);

            return false;
        });
    }

    private void styles (Gtk.Window window) {
        var settings_granite = Granite.Settings.get_default ();
        var theme = new Utils.Theme ();

        try{
            theme.apply_styles (window.screen);

            settings_granite.notify["prefers-color-scheme"].connect (() => {
                try{
                    theme.apply_styles (window.screen);
                } catch (Error e) {
                    warning ("Cannot load app styles: %s", e.message);
                }
            });
        } catch (Error e) {
            warning ("Cannot load app styles: %s", e.message);
        }
    }
}
