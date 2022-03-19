using Utils.DataEntities;

namespace Widgets.Screens.DockerContainer {
    class TopBar : Gtk.Box {
        private Gtk.Widget box_actions;

        public TopBar () {
            this.orientation = Gtk.Orientation.HORIZONTAL;
            this.spacing = 0;

            this.get_style_context ().add_class ("top-bar");
            this.pack_start (this.build_top_bar_container_name (), false);
            this.pack_end (this.build_top_bar_actions (), false);
        }

        private Gtk.Widget build_top_bar_container_name () {
            var state_docker_container = State.Root.get_instance ().screen_docker_container;
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            //
            var container_name = new Gtk.Label ("");

            container_name.get_style_context ().add_class ("primary");
            container_name.get_style_context ().add_class ("container-name");
            container_name.halign = Gtk.Align.START;
            box.pack_start (container_name, false);

            //
            var container_image = new Gtk.Label ("");

            container_image.get_style_context ().add_class ("dim-label");
            container_image.halign = Gtk.Align.START;
            box.pack_end (container_image, false);

            //
            state_docker_container.notify["service"].connect (() => {
                container_name.set_text (state_docker_container.service.name);
                container_image.set_text (state_docker_container.service.container_image ?? "n\\a");
            });

            return box;
        }

        private Gtk.Widget build_top_bar_actions () {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            this.box_actions = box;

            box.valign = Gtk.Align.CENTER;
            box.pack_start (this.build_button_main_action (), false);
            box.pack_end (this.build_button_menu (), false);

            return box;
        }

        private Gtk.Widget build_button_main_action () {
            var state_docker_container = State.Root.get_instance ().screen_docker_container;

            //
            var button = new Gtk.Button ();
            button.get_style_context ().add_class ("button-main-action");

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            button.add (box);

            var icon = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.BUTTON);
            box.pack_start (icon, false);

            var label = new Gtk.Label (_ ("Start"));
            box.pack_end (label, false);

            //
            state_docker_container.notify["service"].connect (() => {
                switch (state_docker_container.service.state) {
                    case ContainerState.RUNNING:
                        icon.icon_name = "media-playback-stop-symbolic";
                        label.set_text (_ ("Stop"));
                        break;

                    case ContainerState.PAUSED:
                        icon.icon_name = "media-playback-start-symbolic";
                        label.set_text (_ ("Unpause"));
                        break;

                    case ContainerState.STOPPED:
                    case ContainerState.UNKNOWN:
                        icon.icon_name = "media-playback-start-symbolic";
                        label.set_text (_ ("Start"));
                        break;
                }
            });

            button.clicked.connect (() => {
                this.button_main_action_handler.begin (state_docker_container.service, (_, res) => {
                    this.button_main_action_handler.end (res);
                });
            });

            return button;
        }

        private Gtk.Widget build_button_menu () {
            var button = new Gtk.Button ();
            var menu = this.build_menu ();

            button.get_style_context ().add_class ("button-menu");
            button.valign = Gtk.Align.FILL;
            button.clicked.connect ((widget) => {
                menu.popup_at_widget (
                    widget,
                    Gdk.Gravity.NORTH_WEST,
                    Gdk.Gravity.NORTH_WEST,
                    null
                );
            });

            var icon = new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.BUTTON);
            button.add (icon);

            return button;
        }

        private Gtk.Menu build_menu () {
            var screen_error = ScreenError.get_instance ();
            var state = State.Root.get_instance ();
            var state_docker_container = state.screen_docker_container;

            var menu = new Gtk.Menu ();

            //
            var item_pause = new Gtk.MenuItem.with_label (_ ("Pause"));
            var err_msg_pause = _ ("Container pause error");

            menu.append (item_pause);
            item_pause.show ();
            item_pause.activate.connect (() => {
                state.container_pause.begin (state_docker_container.service, (_, res) => {
                    try{
                        state.container_pause.end (res);
                    } catch (Docker.ClientError e) {
                        screen_error.show_error_dialog (err_msg_pause, e.message);
                    }
                });
            });

            //
            var item_remove = new Gtk.MenuItem.with_label (_ ("Remove"));
            var err_msg_remove = _ ("Container remove error");

            menu.append (item_remove);
            item_remove.show ();
            item_remove.activate.connect (() => {
                item_remove.sensitive = false;

                var confirm = new Utils.ConfirmationDialog (
                    _ ("Do you really want to remove container?"),
                    _ ("Yes, remove"),
                    _ ("Cancel")
                );

                confirm.accept.connect (() => {
                    state.container_remove.begin (state_docker_container.service, (_, res) => {
                        try{
                            state.container_remove.end (res);
                            state.active_screen = ScreenMain.CODE;
                        } catch (Docker.ClientError e) {
                            screen_error.show_error_dialog (err_msg_remove, e.message);
                        } finally {
                            item_remove.sensitive = true;
                        }
                    });
                });

                confirm.cancel.connect (() => {
                    item_remove.sensitive = true;
                });
            });

            //
            state_docker_container.notify["service"].connect (() => {
                item_pause.sensitive = state_docker_container.service.state == ContainerState.RUNNING;
            });

            return menu;
        }

        private async void button_main_action_handler (Container service) {
            var state = State.Root.get_instance ();
            var err_msg = _ ("Container action error");

            try{
                this.box_actions.sensitive = false;

                switch (service.state) {
                    case ContainerState.RUNNING:
                        err_msg = _ ("Container stop error");
                        yield state.container_stop(service);
                        break;

                    case ContainerState.PAUSED:
                        err_msg = _ ("Container unpause error");
                        yield state.container_unpause(service);
                        break;

                    case ContainerState.STOPPED:
                    case ContainerState.UNKNOWN:
                        err_msg = _ ("Container start error");
                        yield state.container_start(service);
                        break;
                }

            } catch (Docker.ClientError e) {
                ScreenError.get_instance ().show_error_dialog (err_msg, e.message);
            } finally {
                this.box_actions.sensitive = true;
            }
        }
    }
}
