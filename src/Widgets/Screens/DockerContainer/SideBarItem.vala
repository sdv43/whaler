using Utils;

class Widgets.Screens.Container.SideBarItem : Gtk.ListBoxRow {
    public DockerContainer service;

    public SideBarItem (DockerContainer service) {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        this.service = service;
        this.activatable = false;
        this.selectable = true;
        this.get_style_context ().add_class ("side-bar-item");
        this.child = box;

        //
        var container_name = new Gtk.Label (service.name);

        container_name.get_style_context ().add_class ("primary");
        container_name.get_style_context ().add_class ("name");
        container_name.max_width_chars = 16;
        container_name.ellipsize = Pango.EllipsizeMode.END;
        container_name.halign = Gtk.Align.START;
        box.prepend (container_name);

        //
        var container_image = new Gtk.Label (service.image);

        container_image.get_style_context ().add_class ("dim-label");
        container_image.get_style_context ().add_class ("image");
        container_image.max_width_chars = 16;
        container_image.ellipsize = Pango.EllipsizeMode.END;
        container_image.halign = Gtk.Align.START;
        box.append (container_image);
    }
}
