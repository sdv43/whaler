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
    private Gtk.TextBuffer log_buffer;
    private ContainerLogWatcher? log_watcher = null;
    private DockerContainer? selected_container = null;

    public LogOutput () {
        var state_root = State.Root.get_instance ();
        var state_docker_container = state_root.screen_docker_container;
        var text_view = new Gtk.TextView ();

        this.log_buffer = new Gtk.TextBuffer (null);
        this.get_style_context ().add_class ("log-output");

        text_view.get_style_context ().add_class ("terminal");
        text_view.editable = false;
        text_view.cursor_visible = false;
        text_view.buffer = this.log_buffer;
        this.add (text_view);

        this.vadjustment.changed.connect (() => {
            if (state_docker_container.is_auto_scroll_enable) {
                this.vadjustment.value = this.vadjustment.upper - this.vadjustment.page_size;
            }
        });

        // logs are streamed only while the screen is shown
        this.map.connect (this.watching_start);
        this.unmap.connect (this.watching_stop);

        state_docker_container.notify["service"].connect (() => {
            if (this.get_mapped ()) {
                this.watching_start ();
            }
        });
    }

    private void watching_start () {
        var service = State.Root.get_instance ().screen_docker_container.service;
        assert_nonnull (service);

        if (this.log_watcher != null && this.selected_container.id == service.id) {
            // the same container was reloaded, e.g. restarted: resume the stream if it has ended
            this.log_watcher.watching_start ();
            return;
        }

        this.watching_stop ();
        this.log_buffer.text = "";

        this.selected_container = service;
        this.log_watcher = new ContainerLogWatcher (service, this.log_buffer);
        this.log_watcher.watching_start ();
    }

    private void watching_stop () {
        if (this.log_watcher != null) {
            this.log_watcher.watching_stop ();
            this.log_watcher = null;
            this.selected_container = null;
        }
    }
}
