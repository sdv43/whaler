using Utils;

class Widgets.Screens.Main.ContainerCardActions : Gtk.Box {
    private DockerContainer container;

    public ContainerCardActions (DockerContainer container) {
        this.container = container;
        this.get_style_context ().add_class ("docker-container-actions");
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.spacing = 0;
        this.hexpand = true;
        this.halign = Gtk.Align.END;
        this.pack_start (this.build_button_main_action (), false, false);
        this.pack_start (this.build_button_menu_action (), false, false);
    }

    private Gtk.Widget build_button_main_action () {
        var icon_name = "media-playback-start-symbolic";

        if (this.container.state == DockerContainerState.RUNNING) {
            icon_name = "media-playback-stop-symbolic";
        }

        var button = new Gtk.Button.from_icon_name (icon_name, Gtk.IconSize.MENU);

        button.valign = Gtk.Align.CENTER;
        button.clicked.connect (() => {
            this.button_main_action_handler.begin ();
        });

        return button;
    }

    private Gtk.Widget build_button_menu_action () {
        var menu = this.build_menu ();
        var button = new Gtk.Button.from_icon_name ("view-more-symbolic", Gtk.IconSize.BUTTON);

        button.valign = Gtk.Align.CENTER;
        button.clicked.connect ((widget) => {
            menu.popup_at_widget (
                widget,
                Gdk.Gravity.NORTH_WEST,
                Gdk.Gravity.NORTH_WEST,
                null
            );
        });

        return button;
    }

    protected Gtk.Menu build_menu () {
        var screen_error = ScreenError.get_instance ();
        var state = State.Root.get_instance ();
        var menu = new Gtk.Menu ();

        var item_pause = new Gtk.MenuItem.with_label (_ ("Pause"));
        item_pause.sensitive = this.container.state == DockerContainerState.RUNNING;
        item_pause.show ();
        item_pause.activate.connect (() => {
            var err_msg = _ ("Container pause error");

            state.container_pause.begin (this.container, (_, res) => {
                try{
                    state.container_pause.end (res);
                } catch (Docker.ApiClientError error) {
                    screen_error.show_error_dialog (err_msg, error.message);
                }
            });
        });

        var item_remove = new Gtk.MenuItem.with_label (_ ("Remove"));
        item_remove.show ();
        item_remove.activate.connect (() => {
            var confirm = new Utils.ConfirmationDialog (
                _ ("Do you really want to remove container?"),
                _ ("Yes, remove"),
                _ ("Cancel")
            );

            confirm.accept.connect (() => {
                var err_msg = _ ("Container remove error");

                state.container_remove.begin (this.container, (_, res) => {
                    try{
                        state.container_remove.end (res);
                    } catch (Docker.ApiClientError error) {
                        screen_error.show_error_dialog (err_msg, error.message);
                    }
                });
            });
        });

        menu.append (item_pause);
        menu.append (item_remove);

        return menu;
    }

    private async void button_main_action_handler () {
        var state = State.Root.get_instance ();
        var screen_error = ScreenError.get_instance ();

        try {
            this.sensitive = false;

            if (this.container.state == DockerContainerState.RUNNING) {
                yield state.container_stop(this.container);
            } else if (this.container.state == DockerContainerState.STOPPED) {
                yield state.container_start (this.container);
            } else if (this.container.state == DockerContainerState.PAUSED) {
                yield state.container_unpause (this.container);
            } else {
                screen_error.show_error_dialog ("Container action error", "Container state is unknown");
            }
        } catch (Docker.ApiClientError error) {
            screen_error.show_error_dialog ("Container action error", error.message);
        } finally {
            this.sensitive = true;
        }
    }
}
