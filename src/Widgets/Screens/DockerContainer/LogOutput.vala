/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils;
using Docker;

class Widgets.Screens.Container.LogOutput : Gtk.ScrolledWindow {
    public LogOutput () {
        var state_root = State.Root.get_instance ();
        var state_docker_container = state_root.screen_docker_container;
        var text_view = new Gtk.TextView ();
        var log_buffer = new Gtk.TextBuffer (null);

        this.get_style_context ().add_class ("log-output");

        text_view.get_style_context ().add_class ("terminal");
        text_view.editable = false;
        text_view.cursor_visible = false;
        text_view.buffer = log_buffer;
        this.add (text_view);

        this.vadjustment.changed.connect (() => {
            if (state_docker_container.is_auto_scroll_enable) {
                this.vadjustment.value = this.vadjustment.upper - this.vadjustment.page_size;
            }
        });

        ContainerLogWatcher? log_watcher = null;
        DockerContainer? selected_container = null;

        state_docker_container.notify["service"].connect (() => {
            var is_container_changed = true;

            if (selected_container != null) {
                is_container_changed = selected_container.id != state_docker_container.service.id;
            }

            selected_container = state_docker_container.service;

            if (is_container_changed) {
                if (log_watcher != null) {
                    log_watcher.watching_stop ();
                    log_buffer.text = "";
                }

                log_watcher = new ContainerLogWatcher (selected_container, log_buffer);
                log_watcher.watching_start ();
            } else {
                log_watcher.watching_start ();
            }
        });
    }
}
