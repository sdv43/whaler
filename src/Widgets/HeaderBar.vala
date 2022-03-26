class Widgets.HeaderBar : Gtk.HeaderBar {
    public HeaderBar () {
        this.show_close_button = true;
        this.title = APP_NAME;

        this.pack_start (this.build_button_back ());
        this.pack_end (this.build_button_refresh ());
    }

    private Gtk.Widget build_button_back () {
        var state = State.Root.get_instance ();
        var button_back = new Gtk.Button.with_label (_ ("Back"));

        button_back.get_style_context ().add_class ("back-button");
        button_back.valign = Gtk.Align.CENTER;

        button_back.clicked.connect ((button) => {
            state.prev_screen ();
        });
        button_back.show.connect (() => {
            button_back.visible = state.button_back_visible;
        });

        state.notify["button-back-visible"].connect (() => {
            button_back.visible = state.button_back_visible;
        });

        return button_back;
    }

    private Gtk.Widget build_button_refresh () {
        var state = State.Root.get_instance ();
        var button_refresh = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.MENU);

        button_refresh.valign = Gtk.Align.CENTER;
        button_refresh.focus_on_click = false;
        button_refresh.set_tooltip_text (_ ("Update docker container list"));
        button_refresh.get_style_context ().add_class ("refresh-button");

        var err_msg = _ ("Update error");

        button_refresh.clicked.connect ((button) => {
            button_refresh.get_style_context ().add_class ("refresh-animation");

            Timeout.add (600, () => {
                button_refresh.get_style_context ().remove_class ("refresh-animation");

                return false;
            }, Priority.LOW);

            state.containers_load.begin ((_, res) => {
                try {
                    state.containers_load.end (res);
                } catch (Docker.ApiClientError e) {
                    ScreenError.get_instance ().show_error_screen (err_msg, e.message);
                }
            });
        });
        button_refresh.show.connect (() => {
            button_refresh.sensitive = state.active_screen == ScreenMain.CODE;
        });

        state.notify["active-screen"].connect (() => {
            button_refresh.sensitive = state.active_screen == ScreenMain.CODE;
        });

        return button_refresh;
    }
}
