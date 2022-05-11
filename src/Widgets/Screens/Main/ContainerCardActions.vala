using Utils;

class Widgets.Screens.Main.ContainerCardActions : Gtk.Box {
    private DockerContainer container;

    public ContainerCardActions (DockerContainer container) {
        this.container = container;
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.spacing = 0;
        this.get_style_context ().add_class ("docker-container-actions");
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
            this.sensitive = false;

            ContainerCardActions.button_main_action_handler.begin (this.container, (_, res) => {
                ContainerCardActions.button_main_action_handler.end (res);
                this.sensitive = true;
            });
        });

        return button;
    }

    private Gtk.Widget build_button_menu_action () {
        var menu = ContainerCardActions.build_menu (this.container, this);

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

    public static Gtk.Menu build_menu (DockerContainer container, Gtk.Widget actions_widget) {
        var screen_error = ScreenError.get_instance ();
        var state = State.Root.get_instance ();

        var item_pause = new Gtk.MenuItem.with_label (_ ("Pause"));
        item_pause.sensitive = container.state == DockerContainerState.RUNNING;
        item_pause.activate.connect (() => {
            var err_msg = _ ("Container pause error");
            actions_widget.sensitive = false;

            state.container_pause.begin (container, (_, res) => {
                try {
                    state.container_pause.end (res);
                } catch (Docker.ApiClientError error) {
                    screen_error.show_error_dialog (err_msg, error.message);
                } finally {
                    actions_widget.sensitive = true;
                }
            });
        });
        item_pause.show ();

        var item_restart = new Gtk.MenuItem.with_label (_ ("Restart"));
        item_restart.activate.connect (() => {
            var err_msg = _ ("Container restart error");

            actions_widget.sensitive = false;
            state.overlay_bar_text = _ ("Restarting container");
            state.overlay_bar_visible = true;

            state.container_restart.begin (container, (_, res) => {
                try {
                    state.container_restart.end (res);
                } catch (Docker.ApiClientError error) {
                    screen_error.show_error_dialog (err_msg, error.message);
                } finally {
                    actions_widget.sensitive = true;
                    state.overlay_bar_visible = false;
                }
            });
        });
        item_restart.show ();

        var item_remove = new Gtk.MenuItem.with_label (_ ("Remove"));
        item_remove.activate.connect (() => {
            var confirm = new Utils.ConfirmationDialog (
                _ ("Do you really want to remove container?"),
                _ ("Yes, remove"),
                _ ("Cancel")
            );

            actions_widget.sensitive = false;

            confirm.accept.connect (() => {
                var err_msg = _ ("Container remove error");

                state.overlay_bar_text = _ ("Removing container");
                state.overlay_bar_visible = true;

                state.container_remove.begin (container, (_, res) => {
                    try {
                        state.container_remove.end (res);
                    } catch (Docker.ApiClientError error) {
                        screen_error.show_error_dialog (err_msg, error.message);
                    } finally {
                        actions_widget.sensitive = true;
                        state.overlay_bar_visible = false;
                    }
                });
            });

            confirm.cancel.connect (() => {
                actions_widget.sensitive = true;
            });
        });
        item_remove.show ();

        var item_info = new Gtk.MenuItem.with_label (_ ("Info"));
        item_info.activate.connect (() => {
            var err_msg = _ ("Cannot get information");

            state.container_inspect.begin (container, (_, res) => {
                try {
                    new Utils.ContainerInfoDialog (state.container_inspect.end (res));
                } catch (Docker.ApiClientError error) {
                    screen_error.show_error_dialog (err_msg, error.message);
                }
            });
        });
        item_info.show ();

        var menu = new Gtk.Menu ();
        menu.append (item_pause);
        menu.append (item_restart);
        menu.append (item_remove);
        menu.append (item_info);

        return menu;
    }

    public static async void button_main_action_handler (DockerContainer container) {
        var state = State.Root.get_instance ();
        var screen_error = ScreenError.get_instance ();
        var err_msg = _ ("Container action error");

        try {
            switch (container.state) {
                case DockerContainerState.RUNNING:
                    err_msg = _ ("Container stop error");
                    state.overlay_bar_text = _ ("Stopping container");
                    state.overlay_bar_visible = true;
                    yield state.container_stop(container);
                    break;

                case DockerContainerState.STOPPED:
                    err_msg = _ ("Container start error");
                    state.overlay_bar_text = _ ("Starting container");
                    state.overlay_bar_visible = true;
                    yield state.container_start(container);
                    break;

                case DockerContainerState.PAUSED:
                    err_msg = _ ("Container unpause error");
                    yield state.container_unpause(container);
                    break;

                case DockerContainerState.UNKNOWN:
                    screen_error.show_error_dialog (err_msg, _ ("Container state is unknown"));
                    break;
            }
        } catch (Docker.ApiClientError error) {
            screen_error.show_error_dialog (err_msg, error.message);
        } finally {
            state.overlay_bar_visible = false;
        }
    }
}
