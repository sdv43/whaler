using Utils;

namespace Widgets.Screens.Container {
    class TopBar : Gtk.Box {
        private DockerContainer container;

        public TopBar () {
            var state_docker_container = State.Root.get_instance ().screen_docker_container;

            this.orientation = Gtk.Orientation.HORIZONTAL;
            this.spacing = 0;

            this.get_style_context ().add_class ("top-bar");

            state_docker_container.notify["service"].connect (() => {
                this.foreach ((child) => {
                    this.remove (child);
                });

                this.container = state_docker_container.service;
                assert_nonnull (this.container);

                var actions = new TopBarActions (this.container);
                actions.valign = Gtk.Align.CENTER;

                this.pack_start (this.build_container_name (), false);
                this.pack_end (actions, false);
                this.show_all ();
            });
        }

        private Gtk.Widget build_container_name () {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            var container_name = new Gtk.Label (this.container.name);
            container_name.get_style_context ().add_class ("primary");
            container_name.get_style_context ().add_class ("container-name");
            container_name.halign = Gtk.Align.START;
            box.pack_start (container_name, false);

            var container_image = new Gtk.Label (this.container.image);
            container_image.get_style_context ().add_class ("dim-label");
            container_image.halign = Gtk.Align.START;
            box.pack_end (container_image, false);

            return box;
        }
    }
}
