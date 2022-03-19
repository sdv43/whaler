using Utils.DataEntities;

class Widgets.Screens.DockerContainer.SideBar : Gtk.ScrolledWindow {
    public SideBar () {
        var state = State.Root.get_instance ().screen_docker_container;
        var list_box = new Gtk.ListBox ();

        this.width_request = 300;
        this.get_style_context ().add_class ("side-bar");
        this.add (list_box);

        list_box.activate_on_single_click = false;
        list_box.selection_mode = Gtk.SelectionMode.SINGLE;
        list_box.row_selected.connect ((row) => {
            if (row.get_index () == -1) {
                return;
            }

            var side_bar_item = row as SideBarItem;
            assert_nonnull (side_bar_item);

            state.service = side_bar_item.service;
        });

        state.notify["container"].connect (() => {
            this.visible = state.container.type == ContainerType.APP;

            if (!this.visible) {
                state.service = state.container;

                return;
            }

            list_box.foreach ((child) => {
                list_box.remove (child);
            });

            //
            var main_container_item = new SideBarItem (state.container);
            var separator_item = new SideBarSeparator (_ ("Services"));

            list_box.add (main_container_item);
            list_box.add (separator_item);

            var selected_item = main_container_item;

            foreach (var service in state.container.containers) {
                var item = new SideBarItem (service);

                list_box.add (item);
                debug ("added");

                if (state.service != null && state.service.container_id == service.container_id) {
                    selected_item = item;
                }
            }

            state.service = selected_item.service;
            list_box.select_row (selected_item);
            list_box.show_all ();

            debug ("list box rebuilded");
        });
    }
}
