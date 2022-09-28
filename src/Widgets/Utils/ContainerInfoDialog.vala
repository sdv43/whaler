using Utils;
using Docker;

class Widgets.Utils.ContainerInfoDialog : Granite.Dialog {
    Gee.HashMap<DockerContainer, ContainerInspectInfo?> containers_info;

    public ContainerInfoDialog (Gee.HashMap<DockerContainer, ContainerInspectInfo?> containers_info) {
        this.default_width = 460;
        this.default_height = 400;
        this.containers_info = containers_info;
        //  this.skip_taskbar_hint = true;
        this.transient_for = Whaler.get_instance ().active_window;
        this.add_button (_ ("Close"), Gtk.ResponseType.CANCEL);
        this.get_content_area ().prepend (this.build_content_area ());

        this.response.connect ((resp_id) => {
            this.destroy ();
        });

        //  this.show_all ();
    }

    private Gtk.Widget build_content_area () {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        //  box.expand = true;

        var stack = new Gtk.Stack ();
        foreach (var entry in this.containers_info) {
            var container = entry.key;
            var info = entry.value;

            stack.add_titled (this.build_tab (info), container.id, container.name);
        }
        box.append (stack);

        if (this.containers_info.size > 1) {
            var switcher = new Gtk.StackSwitcher ();
            switcher.get_style_context ().add_class ("container-info-dialog-switcher");
            switcher.stack = stack;
            switcher.halign = Gtk.Align.CENTER;
            box.prepend (switcher);
        }

        return box;
    }

    private Gtk.Widget build_tab (ContainerInspectInfo info) {
        var scrolled_window = new Gtk.ScrolledWindow ();
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        box.get_style_context ().add_class ("container-info-dialog-tab");
        box.prepend (this.build_row (_ ("Name"), {info.name}));
        box.prepend (this.build_row (_ ("Image"), {info.image}));
        box.prepend (this.build_row (_ ("Status"), {info.status}));

        if (info.ports != null) {
            box.prepend (this.build_row (_ ("Ports"), info.ports));
        }

        if (info.binds != null) {
            box.prepend (this.build_row (_ ("Binds"), info.binds));
        }

        if (info.envs != null) {
            box.prepend (this.build_row (_ ("Env"), info.envs));
        }

        scrolled_window.child = box;

        return scrolled_window;
    }

    private Gtk.Widget build_row (string label, string[] values) {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        box.get_style_context ().add_class ("container-info-dialog-row");
        box.prepend (this.build_label (label));
        box.prepend (this.build_values (values));

        return box;
    }

    private Gtk.Widget build_label (string text) {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.width_request = 140;

        var label = new Gtk.Label (text);
        label.get_style_context ().add_class ("container-info-dialog-label");
        label.halign = Gtk.Align.END;
        label.valign = Gtk.Align.START;

        box.append (label);

        return box;
    }

    private Gtk.Widget build_values (string[] values) {
        if (values.length == 1) {
            return this.build_value (values[0]);
        }

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        foreach (var value in values) {
            box.append (this.build_value (value));
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
