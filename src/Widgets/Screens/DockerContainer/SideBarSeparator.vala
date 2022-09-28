class Widgets.Screens.Container.SideBarSeparator : Gtk.ListBoxRow {
    public SideBarSeparator (string text) {
        this.can_focus = false;
        this.activatable = false;
        this.selectable = false;
        this.get_style_context ().add_class ("side-bar-separator");
        this.get_style_context ().add_class ("h4");

        //
        var label = new Gtk.Label (text);

        label.max_width_chars = 16;
        label.ellipsize = Pango.EllipsizeMode.END;
        label.halign = Gtk.Align.START;

        this.child = label;
    }
}
