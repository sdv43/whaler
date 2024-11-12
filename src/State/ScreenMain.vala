/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

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
