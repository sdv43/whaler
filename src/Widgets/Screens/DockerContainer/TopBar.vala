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

                this.pack_start (this.build_container_block (), false);
                this.pack_end (this.build_container_actions (), false);
                this.show_all ();
            });
        }

        private Gtk.Widget build_container_block () {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            box.pack_start (this.build_container_name (), false);
            box.pack_end (this.build_container_status_label () ?? this.build_container_image (), false);

            return box;
        }

        private Gtk.Widget build_container_name () {
            var container_name = new Gtk.Label (this.container.name);
            container_name.get_style_context ().add_class ("primary");
            container_name.get_style_context ().add_class ("container-name");
            container_name.halign = Gtk.Align.START;

            return container_name;
        }

        private Gtk.Widget? build_container_status_label () {
            var label = Utils.DockerContainerStatusLabel.create_by_container (this.container);
            label.halign = Gtk.Align.START;

            return label;
        }

        private Gtk.Widget build_container_image () {
            var label = new Gtk.Label (this.container.image);
            label.get_style_context ().add_class ("container-image");
            label.halign = Gtk.Align.START;

            return label;
        }

        private Gtk.Widget build_container_actions () {
            var actions = new TopBarActions (this.container);
            actions.valign = Gtk.Align.CENTER;

            return actions;
        }
    }
}
