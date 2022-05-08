using Utils;
using Docker;

class Widgets.Utils.ContainerInfoDialog : Granite.Dialog {
    Gee.HashMap<DockerContainer, ContainerInspectInfo?> containers_info;

    public ContainerInfoDialog (Gee.HashMap<DockerContainer, ContainerInspectInfo?> containers_info) {
        this.default_width = 460;
        this.default_height = 400;
        this.containers_info = containers_info;
        this.skip_taskbar_hint = true;
        this.transient_for = Whaler.get_instance ().active_window;
        this.add_button (_ ("Close"), Gtk.ResponseType.CANCEL);
        this.get_content_area ().add (this.build_content_area ());

        this.response.connect ((resp_id) => {
            this.destroy ();
        });

        this.show_all ();
    }

    private Gtk.Widget build_content_area () {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;

        var stack = new Gtk.Stack ();
        foreach (var entry in this.containers_info) {
            var container = entry.key;
            var info = entry.value;

            stack.add_titled (this.build_tab (info), container.id, container.name);
        }
        box.pack_end (stack);

        if (this.containers_info.size > 1) {
            var switcher = new Gtk.StackSwitcher ();
            switcher.get_style_context ().add_class ("container-info-dialog-switcher");
            switcher.stack = stack;
            switcher.halign = Gtk.Align.CENTER;
            box.pack_start (switcher, false);
        }

        return box;
    }

    private Gtk.Widget build_tab (ContainerInspectInfo info) {
        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        box.get_style_context ().add_class ("container-info-dialog-tab");
        box.pack_start (this.build_row (_ ("Name"), {info.name}), false);
        box.pack_start (this.build_row (_ ("Image"), {info.image}), false);
        box.pack_start (this.build_row (_ ("Status"), {info.status}), false);

        if (info.ports != null) {
            box.pack_start (this.build_row (_ ("Ports"), info.ports), false);
        }

        if (info.binds != null) {
            box.pack_start (this.build_row (_ ("Binds"), info.binds), false);
        }

        if (info.envs != null) {
            box.pack_start (this.build_row (_ ("Env"), info.envs), false);
        }

        scrolled_window.add (box);

        return scrolled_window;
    }

    private Gtk.Widget build_row (string label, string[] values) {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        box.get_style_context ().add_class ("container-info-dialog-row");
        box.pack_start (this.build_label (label), false);
        box.pack_start (this.build_values (values), false);

        return box;
    }

    private Gtk.Widget build_label (string text) {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.width_request = 140;

        var label = new Gtk.Label (text);
        label.get_style_context ().add_class ("container-info-dialog-label");
        label.halign = Gtk.Align.END;
        label.valign = Gtk.Align.START;

        box.pack_end (label, false);

        return box;
    }

    private Gtk.Widget build_values (string[] values) {
        if (values.length == 1) {
            return this.build_value (values[0]);
        }

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        foreach (var value in values) {
            box.pack_end (this.build_value (value), false);
        }

        return box;
    }

    private Gtk.Widget build_value (string value) {
        var label = new Gtk.Label (value);

        label.get_style_context ().add_class ("container-info-dialog-value");
        label.halign = Gtk.Align.START;
        label.selectable = true;
        label.single_line_mode = false;
        label.wrap = true;
        label.wrap_mode = Pango.WrapMode.CHAR;

        return label;
    }
}
