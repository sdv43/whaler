using Utils.Constants;

class Widgets.Utils.SettingsDialog : Granite.Dialog {
    public SettingsDialog () {
        this.default_width = 500;
        this.default_height = 300;
        this.transient_for = Whaler.get_instance ().active_window;
        this.transient_for.sensitive = false;
        //  this.skip_taskbar_hint = true;
        this.get_style_context ().add_class ("dialog-settings");
        this.add_button (_ ("Close"), Gtk.ResponseType.CANCEL);
        this.get_content_area ().prepend (this.build_content_area ());

        this.response.connect ((resp_id) => {
            this.transient_for.sensitive = true;
            this.destroy ();
        });

        //  this.show_all ();
    }

    private Gtk.Widget build_content_area () {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        //  box.expand = true;

        var title = new Gtk.Label (_ ("Settings"));
        title.get_style_context ().add_class ("h4");
        title.get_style_context ().add_class ("dialog-settings-title");

        box.prepend (title);
        box.append (this.build_section ());

        return box;
    }

    private Gtk.Widget build_section () {
        var scrolled_window = new Gtk.ScrolledWindow ();

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.get_style_context ().add_class ("dialog-settings-section");
        box.prepend (this.build_row_with_widget (_ ("API socket path:"), new SocketPathEntry ()));

        scrolled_window.child = box;

        return scrolled_window;
    }

    private Gtk.Widget build_row_with_widget (string label, Gtk.Widget value) {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        box.get_style_context ().add_class ("dialog-settings-row");
        box.prepend (this.build_label (label));
        box.prepend (value);

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

        box.append (label);

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

        this.prepend (this.build_entry ());
        this.prepend (this.build_button_check ());
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
        box.prepend (button);

        return box;
    }

    private Gtk.Widget build_notice (string message, bool successful) {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.get_style_context ().add_class ("notice");
        box.get_style_context ().add_class (successful ? "successfull" : "failed");

        var title = new Gtk.Label (successful ? _ ("Success") : _ ("Error"));
        title.get_style_context ().add_class ("h4");
        title.halign = Gtk.Align.START;
        box.prepend (title);

        var msg = new Gtk.Label (message);
        msg.halign = Gtk.Align.START;
        msg.wrap = true;

        box.append (msg);

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
            this.prepend (this.notice);
            //  this.show_all ();
        }
    }
}
