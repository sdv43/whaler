class Widgets.Screens.Main.ContainersGrid : Gtk.Stack {
    public const string CODE = "main";

    private signal void container_cards_updated();

    public ContainersGrid () {
        var state = State.Root.get_instance ();

        this.add_named (this.build_loader (), "loader");
        this.add_named (this.build_notice (), "no-containers");
        this.add_named (this.build_grid (), "containers");

        state.notify["containers"].connect (() => {
            if (state.containers.size > 0) {
                this.set_visible_child_name ("containers");

                if (state.active_screen == ContainersGrid.CODE) {
                    this.container_cards_updated ();
                }
            } else {
                this.set_visible_child_name ("no-containers");
            }
        });

        state.notify["active-screen"].connect (() => {
            if (state.active_screen == ContainersGrid.CODE) {
                this.container_cards_updated ();
            }
        });
    }

    private Gtk.Widget build_grid () {
        var state = State.Root.get_instance ();
        var root = new Gtk.ScrolledWindow (null, null);

        var flow_box = new Gtk.FlowBox ();
        flow_box.get_style_context ().add_class ("docker-containers-grid");
        flow_box.homogeneous = true;
        flow_box.valign = Gtk.Align.START;
        flow_box.min_children_per_line = 2;
        flow_box.max_children_per_line = 7;
        flow_box.selection_mode = Gtk.SelectionMode.NONE;
        flow_box.activate_on_single_click = true;

        flow_box.child_activated.connect ((child) => {
            state.screen_docker_container.container = state.containers[child.get_index ()];
            state.next_screen (Widgets.ScreenDockerContainer.CODE);
        });
        root.add (flow_box);

        this.container_cards_updated.connect (() => {
            flow_box.foreach ((child) => {
                flow_box.remove (child);
            });

            foreach (var container in state.containers) {
                if (container.name.down (container.name.length).index_of (state.screen_main.search_term, 0) > -1) {
                    flow_box.add (new ContainerCard (container));
                }
            }

            flow_box.show_all ();
        });

        state.screen_main.notify["search-term"].connect (() => {
            flow_box.foreach ((child) => {
                flow_box.remove (child);
            });

            foreach (var container in state.containers) {
                if (container.name.down (container.name.length).index_of (state.screen_main.search_term, 0) > -1) {
                    flow_box.add (new ContainerCard (container));
                }
            }

            flow_box.show_all ();
        });

        return root;
    }

    private Gtk.Widget build_loader () {
        var loader = new Gtk.Spinner ();

        loader.width_request = 32;
        loader.height_request = 32;
        loader.halign = Gtk.Align.CENTER;
        loader.valign = Gtk.Align.CENTER;

        loader.start ();

        return loader;
    }

    private Gtk.Widget build_notice () {
        var label = new Gtk.Label (_ ("No containers"));

        label.get_style_context ().add_class ("h3");
        label.halign = Gtk.Align.CENTER;
        label.valign = Gtk.Align.CENTER;

        return label;
    }
}
