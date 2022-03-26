using Utils;

class Widgets.Screens.Main.ContainerCard : Gtk.FlowBoxChild {
    private DockerContainer container;

    public ContainerCard (DockerContainer container) {
        var grid = new Gtk.Grid ();

        this.container = container;
        this.get_style_context ().add_class ("docker-container");
        this.add (grid);

        grid.attach (this.build_preview_image (), 1, 1, 1, 2);
        grid.attach (this.build_container_name (), 2, 1, 1, 1);
        grid.attach (this.build_container_image (), 2, 2, 1, 1);
        grid.attach (this.build_actions (), 3, 1, 1, 2);

        if (container.state == DockerContainerState.UNKNOWN) {
            this.sensitive = false;
        }
    }

    private Gtk.Widget build_container_name () {
        var label = new Gtk.Label (this.container.name);

        label.get_style_context ().add_class ("primary");
        label.get_style_context ().add_class ("docker-container-name");
        label.max_width_chars = 16;
        label.ellipsize = Pango.EllipsizeMode.END;
        label.halign = Gtk.Align.START;
        label.valign = Gtk.Align.END;

        return label;
    }

    private Gtk.Widget build_container_image () {
        var label = new Gtk.Label (this.container.image);

        label.get_style_context ().add_class ("dim-label");
        label.max_width_chars = 16;
        label.ellipsize = Pango.EllipsizeMode.END;
        label.halign = Gtk.Align.START;
        label.valign = Gtk.Align.START;

        return label;
    }

    private Gtk.Widget build_preview_image () {
        var image = new Gtk.Image.from_icon_name ("image-missing", Gtk.IconSize.DIALOG);

        try {
            var pixbuf_image = new Gdk.Pixbuf.from_resource_at_scale (
                this.get_preview_image_path (),
                56, 56,
                true
            );

            image = new Gtk.Image.from_pixbuf (pixbuf_image);
        } catch (Error error) {
            warning ("Error on container image creation: %s", error.message);
        }

        image.get_style_context ().add_class ("docker-container-preview-image");
        image.style_updated.connect (() => {
            try {
                var pixbuf_image = new Gdk.Pixbuf.from_resource_at_scale (
                    this.get_preview_image_path (),
                    56, 56,
                    true
                );

                image.set_from_pixbuf (pixbuf_image);
            } catch (Error error) {
                warning ("Error on container image creation: %s", error.message);
            }
        });

        return image;
    }

    private string get_preview_image_path () {
        var settings_granite = Granite.Settings.get_default ();
        var is_dark = settings_granite.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        var file = this.container.type == DockerContainerType.GROUP ? "app" : "container";
        var variant = is_dark ? "-dark" : "";

        return @"$RESOURCE_BASE/images/icons/docker-$file$variant.svg";
    }

    private Gtk.Widget build_actions () {
        var screen_error = ScreenError.get_instance ();
        var state = State.Root.get_instance ();
        var actions = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        actions.get_style_context ().add_class ("docker-container-actions");
        actions.hexpand = true;
        actions.halign = Gtk.Align.END;

        switch (this.container.state) {
            case DockerContainerState.RUNNING:
                var action_stop = new Gtk.Button.from_icon_name (
                    "media-playback-stop-symbolic",
                    Gtk.IconSize.MENU
                );

                action_stop.valign = Gtk.Align.CENTER;
                actions.pack_start (action_stop, false, false);

                action_stop.clicked.connect (() => {
                this.sensitive = false;

                var err_msg = _ ("Container stop error");

                state.container_stop.begin (this.container, (_, res) => {
                    try{
                        state.container_stop.end (res);
                    } catch (Docker.ApiClientError e) {
                        screen_error.show_error_dialog (err_msg, e.message);
                    } finally {
                        this.sensitive = true;
                    }
                });
            });

                break;

            case DockerContainerState.PAUSED:
                var action_unpause = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.MENU);

                action_unpause.valign = Gtk.Align.CENTER;
                actions.pack_start (action_unpause, false, false);

                action_unpause.clicked.connect (() => {
                this.sensitive = false;

                var err_msg = _ ("Container unpause error");

                state.container_unpause.begin (this.container, (_, res) => {
                    try{
                        state.container_unpause.end (res);
                    } catch (Docker.ApiClientError e) {
                        screen_error.show_error_dialog (err_msg, e.message);
                    } finally {
                        this.sensitive = true;
                    }
                });
            });
                break;

            case DockerContainerState.UNKNOWN:
            case DockerContainerState.STOPPED:
                var action_start = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.MENU);

                action_start.valign = Gtk.Align.CENTER;
                actions.pack_start (action_start, false, false);

                action_start.clicked.connect (() => {
                this.sensitive = false;

                var err_msg = _ ("Container start error");

                state.container_start.begin (this.container, (_, res) => {
                    try{
                        state.container_start.end (res);
                    } catch (Docker.ApiClientError e) {
                        screen_error.show_error_dialog (err_msg, e.message);
                    } finally {
                        this.sensitive = true;
                    }
                });
            });
                break;
        }

        var menu = this.build_menu ();
        var action_menu = new Gtk.Button.from_icon_name ("view-more-symbolic", Gtk.IconSize.BUTTON);

        action_menu.valign = Gtk.Align.CENTER;
        actions.pack_start (action_menu, false, false);

        action_menu.clicked.connect ((widget) => {
            menu.popup_at_widget (
                widget,
                Gdk.Gravity.NORTH_WEST,
                Gdk.Gravity.NORTH_WEST,
                null
            );
        });

        return actions;
    }

    protected Gtk.Menu build_menu () {
        var screen_error = ScreenError.get_instance ();
        var state = State.Root.get_instance ();
        var menu = new Gtk.Menu ();

        var item_pause = new Gtk.MenuItem.with_label (_ ("Pause"));
        item_pause.sensitive = this.container.state == DockerContainerState.RUNNING;
        item_pause.show ();
        menu.append (item_pause);

        item_pause.activate.connect (() => {
            item_pause.sensitive = false;

            var err_msg = _ ("Container pause error");

            state.container_pause.begin (this.container, (_, res) => {
                try{
                    state.container_pause.end (res);
                } catch (Docker.ApiClientError e) {
                    screen_error.show_error_dialog (err_msg, e.message);
                } finally {
                    item_pause.sensitive = true;
                }
            });
        });

        var item_remove = new Gtk.MenuItem.with_label (_ ("Remove"));
        item_remove.show ();
        menu.append (item_remove);

        item_remove.activate.connect (() => {
            item_remove.sensitive = false;
            var err_msg = _ ("Container remove error");
            var confirm = new Utils.ConfirmationDialog (
                _ ("Do you really want to remove container?"),
                _ ("Yes, remove"),
                _ ("Cancel")
            );

            confirm.accept.connect (() => {
                state.container_remove.begin (this.container, (_, res) => {
                    try{
                        state.container_remove.end (res);
                    } catch (Docker.ApiClientError e) {
                        screen_error.show_error_dialog (err_msg, e.message);
                    } finally {
                        item_remove.sensitive = true;
                    }
                });
            });

            confirm.cancel.connect (() => {
                item_remove.sensitive = true;
            });
        });

        return menu;
    }
}
