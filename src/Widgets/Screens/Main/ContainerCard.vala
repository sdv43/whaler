using Utils;

class Widgets.Screens.Main.ContainerCard : Gtk.FlowBoxChild {
    private DockerContainer container;

    public ContainerCard (DockerContainer container) {
        var grid = new Gtk.Grid ();

        this.container = container;
        this.get_style_context ().add_class ("docker-container");
        this.add (grid);

        grid.attach (this.build_container_icon (), 1, 1, 1, 2);
        grid.attach (this.build_container_name (), 2, 1, 1, 1);
        grid.attach (this.build_container_image (), 2, 2, 1, 1);
        grid.attach (new ContainerCardActions (container), 3, 1, 1, 2);

        if (container.state == DockerContainerState.UNKNOWN) {
            this.sensitive = false;
        }
    }

    private Gtk.Widget build_container_name () {
        var label = new Gtk.Label (this.container.name);

        label.get_style_context ().add_class ("primary");
        label.get_style_context ().add_class ("docker-container-name");
        label.max_width_chars = 16;
        label.ellipsize = Pango.EllipsizeMode.END;
        label.halign = Gtk.Align.START;
        label.valign = Gtk.Align.END;

        return label;
    }

    private Gtk.Widget build_container_image () {
        var label = new Gtk.Label (this.container.image);

        label.get_style_context ().add_class ("dim-label");
        label.max_width_chars = 16;
        label.ellipsize = Pango.EllipsizeMode.END;
        label.halign = Gtk.Align.START;
        label.valign = Gtk.Align.START;

        return label;
    }

    private Gtk.Widget build_container_icon () {
        var icon_name = "docker-container-symbolic";

        if (this.container.type == DockerContainerType.GROUP) {
            icon_name = "docker-container-group-symbolic";
        }

        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        image.get_style_context ().add_class ("docker-container-preview-image");
        image.set_pixel_size (56);

        return image;
    }
}
