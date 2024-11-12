/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils;

namespace Widgets.Utils {
    class DockerContainerStatusLabel : Gtk.Label {
        private DockerContainerStatusLabel(DockerContainer container) {
            this.get_style_context ().add_class ("docker-container-status-label");

            switch (container.state) {
                case DockerContainerState.RUNNING:
                    this.get_style_context ().add_class ("running");
                    this.set_text (_ ("Running"));
                    break;

                case DockerContainerState.PAUSED:
                    this.get_style_context ().add_class ("paused");
                    this.set_text (_ ("Paused"));
                    break;

                case DockerContainerState.STOPPED:
                    this.get_style_context ().add_class ("stopped");
                    this.set_text (_ ("Stopped"));
                    break;

                case DockerContainerState.UNKNOWN:
                    this.get_style_context ().add_class ("unknown");
                    this.set_text (_ ("Unknown"));
                    break;
            }
        }

        public static Gtk.Widget? create_by_container (DockerContainer container) {
            var is_running = container.state == DockerContainerState.RUNNING;
            var is_paused = container.state == DockerContainerState.PAUSED;

            if (is_running || is_paused) {
                return new DockerContainerStatusLabel (container);
            }

            return null;
        }
    }
}
