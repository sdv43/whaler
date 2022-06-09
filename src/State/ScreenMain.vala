using Utils;
using Utils.Sorting;

class State.ScreenMain : Object {
    public string search_term {get; set;}
    public SortingInterface? sorting {get; set;}
    public Gee.ArrayList<DockerContainer> containers_prepared {get; private set;}

    public ScreenMain (Root root) {
        this.search_term = "";
        this.sorting = new SortingName ();
        this.containers_prepared = new Gee.ArrayList<DockerContainer> (DockerContainer.equal);

        root.notify["containers"].connect (() => {
            if (root.containers.size == 0) {
                return;
            }

            this.containers_prepared.clear ();
            this.containers_prepared.add_all_iterator (root.containers.filter ((container) => {
                return container.name.down (container.name.length).index_of (this.search_term, 0) > -1;
            }));
            this.containers_prepared.sort (this.sorting.compare);

            this.notify_property ("containers-prepared");
        });

        this.notify["search-term"].connect (() => {
            this.containers_prepared.clear ();
            this.containers_prepared.add_all_iterator (root.containers.filter ((container) => {
                return container.name.down (container.name.length).index_of (this.search_term, 0) > -1;
            }));
            this.containers_prepared.sort (this.sorting.compare);

            this.notify_property ("containers-prepared");
        });

        this.notify["sorting"].connect (() => {
            this.containers_prepared.sort (this.sorting.compare);

            this.notify_property ("containers-prepared");
        });
    }
}
