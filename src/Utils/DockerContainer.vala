/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Docker;

namespace Utils {
    enum DockerContainerType {
        GROUP,
        CONTAINER
    }

    enum DockerContainerState {
        UNKNOWN,
        PAUSED,
        RUNNING,
        STOPPED,
    }

    class DockerContainer : Object {
        public Container? api_container {get; construct set;}

        public string id;
        public string name;
        public string image;
        public bool is_tty;
        public DockerContainerType type;
        public DockerContainerState state;

        public string? config_path;
        public Gee.ArrayList<DockerContainer>? services;

        public DockerContainer.from_docker_api_container (Container container) {
            this.api_container = container;

            this.id = container.id;
            this.name = this.format_name (container.name);
            this.image = container.image;
            this.type = DockerContainerType.CONTAINER;
            this.state = this.get_state (container.state);
            this.is_tty = false;
        }

        public string format_name (string name) {
            var value = name;

            if (value[0] == '/') {
                value = value.splice (0, 1);
            }

            return ucfirst (value);
        }

        public DockerContainerState get_state (string state) {
            if (state == "running") {
                return DockerContainerState.RUNNING;
            }
            if (state == "paused") {
                return DockerContainerState.PAUSED;
            }
            if (state == "exited") {
                return DockerContainerState.STOPPED;
            }

            return DockerContainerState.UNKNOWN;
        }

        public static bool equal (DockerContainer a, DockerContainer b) {
            return a.id == b.id;
        }
    }
}
