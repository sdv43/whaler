/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils.Constants;

class Widgets.Utils.SettingsDialog : Granite.Dialog {
    public SettingsDialog () {
        this.default_width = 500;
        this.default_height = 300;
        this.transient_for = Whaler.get_instance ().active_window;
        this.transient_for.sensitive = false;
        this.skip_taskbar_hint = true;
        this.get_style_context ().add_class ("dialog-settings");
        this.add_button (_ ("Close"), Gtk.ResponseType.CANCEL);
        this.get_content_area ().add (this.build_content_area ());

        this.response.connect ((resp_id) => {
            this.transient_for.sensitive = true;
            this.destroy ();
        });

        this.show_all ();
    }

    private Gtk.Widget build_content_area () {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;

        var title = new Gtk.Label (_ ("Settings"));
        title.get_style_context ().add_class ("h4");
        title.get_style_context ().add_class ("dialog-settings-title");

        box.pack_start (title, false);
        box.pack_end (this.build_section (), true);

        return box;
    }

    private Gtk.Widget build_section () {
        var scrolled_window = new Gtk.ScrolledWindow (null, null);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.get_style_context ().add_class ("dialog-settings-section");
        box.pack_start (this.build_row_with_widget (_ ("API socket path:"), new SocketPathEntry ()), false);

        scrolled_window.add (box);

        return scrolled_window;
    }

    private Gtk.Widget build_row_with_widget (string label, Gtk.Widget value) {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        box.get_style_context ().add_class ("dialog-settings-row");
        box.pack_start (this.build_label (label), false);
        box.pack_start (value, false);

        return box;
    }

    private Gtk.Widget build_label (string text) {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.width_request = 140;

        var label = new Gtk.Label (text);
        label.get_style_context ().add_class ("dialog-settings-row-label");
        label.height_request = 27; // entry height
        label.halign = Gtk.Align.END;
        label.valign = Gtk.Align.START;

        box.pack_end (label, false);

        return box;
    }
}

class SocketPathEntry : Gtk.Box {
    private Gtk.Entry entry_socket_path;
    private Gtk.Widget notice;

    public SocketPathEntry () {
        this.get_style_context ().add_class ("docker-socket-path");
        this.orientation = Gtk.Orientation.VERTICAL;
        this.spacing = 0;

        this.pack_start (this.build_entry (), false);
        this.pack_start (this.build_button_check (), false);
    }

    private Gtk.Widget build_entry () {
        var entry = new Gtk.Entry ();
        entry.width_request = 240;
        entry.placeholder_text = "/run/docker.sock";
        this.entry_socket_path = entry;

        var settings = new Settings (APP_ID);
        settings.bind ("docker-api-socket-path", entry, "text", SettingsBindFlags.DEFAULT);

        return entry;
    }

    private Gtk.Widget build_button_check () {

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.get_style_context ().add_class ("button-check");

        var button = new Gtk.Button.with_label (_ ("Check connection"));
        button.halign = Gtk.Align.START;
        button.clicked.connect (() => {
            button.sensitive = false;

            this.button_check_handler.begin ((_, res) => {
                this.button_check_handler.end (res);
                button.sensitive = true;
            });
        });
        box.pack_start (button, false);

        return box;
    }

    private Gtk.Widget build_notice (string message, bool successful) {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.get_style_context ().add_class ("notice");
        box.get_style_context ().add_class (successful ? "successfull" : "failed");

        var title = new Gtk.Label (successful ? _ ("Success") : _ ("Error"));
        title.get_style_context ().add_class ("h4");
        title.halign = Gtk.Align.START;
        box.pack_start (title, false);

        var msg = new Gtk.Label (message);
        msg.halign = Gtk.Align.START;
        msg.wrap = true;

        box.pack_end (msg, false);

        return box;
    }

    private async void button_check_handler () {
        var settings = new Settings (APP_ID);
        var state = State.Root.get_instance ();
        var api_client = new Docker.ApiClient ();
        var err_msg = _ ("Incorrect socket path \"%s\"");

        if (this.notice != null) {
            this.remove (this.notice);
        }

        try {
            //
            api_client.http_client.unix_socket_path = this.entry_socket_path.text;
            yield api_client.ping();

            //
            var engine = settings.get_string ("docker-api-socket-path").contains ("podman.sock")
                         ? "Podman"
                         : "Docker";

            var docker_version_info = yield api_client.version ();
            this.notice = this.build_notice (
                @"$engine v$(docker_version_info.version), API v$(docker_version_info.api_version)",
                true
            );

            yield state.containers_load ();
            state.active_screen = Widgets.ScreenMain.CODE;
        } catch (Docker.ApiClientError error) {
            this.notice = this.build_notice (err_msg.printf (this.entry_socket_path.text), false);
        } finally {
            this.pack_start (this.notice, false);
            this.show_all ();
        }
    }
}
