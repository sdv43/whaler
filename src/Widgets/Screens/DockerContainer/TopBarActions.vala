using Utils;
using Widgets.Screens.Main;

namespace Widgets.Screens.Container {
    class TopBarActions : Gtk.Box {
        private DockerContainer container;

        public TopBarActions (DockerContainer container) {
            this.container = container;
            this.sensitive = container.state != DockerContainerState.UNKNOWN;
            this.orientation = Gtk.Orientation.HORIZONTAL;
            this.spacing = 0;
            this.pack_start (this.build_button_main_action (), false);
            this.pack_end (this.build_button_menu_action (), false);
        }

        private Gtk.Widget build_button_main_action () {
            var icon_name = "media-playback-start-symbolic";
            var label_text = _ ("Start");

            if (this.container.state == DockerContainerState.RUNNING) {
                icon_name = "media-playback-stop-symbolic";
                label_text = _ ("Stop");
            } else if (this.container.state == DockerContainerState.PAUSED) {
                label_text = _ ("Unpause");
            }

            var icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.BUTTON);
            var label = new Gtk.Label (label_text);

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start (icon, false);
            box.pack_end (label, false);

            var button = new Gtk.Button ();
            button.get_style_context ().add_class ("button-main-action");
            button.add (box);
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
            var button = new Gtk.Button ();
            var menu = ContainerCardActions.build_menu (this.container, this);

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
    }
}
