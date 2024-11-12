/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils;

class State.ScreenDockerContainer : Object {
    private Root root;

    public bool is_auto_scroll_enable;
    public DockerContainer? container {get; set;}
    public DockerContainer? service {get; set;}

    public ScreenDockerContainer (Root root) {
        this.root = root;
        this.is_auto_scroll_enable = false;
        this.container = null;
        this.service = null;

        this.root.notify["containers"].connect (() => {
            if (this.container == null) {
                return;
            }

            var index = root.containers.index_of (this.container);

            if (index != -1) {
                this.container = root.containers[index];
            }
        });

        this.notify["container"].connect (() => {
            if (this.container.type == DockerContainerType.GROUP) {
                if (this.service == null) {
                    this.service = this.container;
                } else {
                    var index = this.container.services.index_of (this.service);

                    if (index != -1) {
                        this.service = this.container.services[index];
                    } else {
                        this.service = this.container;
                    }
                }
            } else {
                this.service = this.container;
            }
        });
    }
}
