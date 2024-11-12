/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils;

class Widgets.Screens.Container.SideBarItem : Gtk.ListBoxRow {
    public DockerContainer service;

    public SideBarItem (DockerContainer service) {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        this.service = service;
        this.activatable = false;
        this.selectable = true;
        this.get_style_context ().add_class ("side-bar-item");
        this.add (box);

        //
        var container_name = new Gtk.Label (service.name);

        container_name.get_style_context ().add_class ("primary");
        container_name.get_style_context ().add_class ("name");
        container_name.max_width_chars = 16;
        container_name.ellipsize = Pango.EllipsizeMode.END;
        container_name.halign = Gtk.Align.START;
        box.pack_start (container_name, false);

        //
        var container_image = new Gtk.Label (service.image);

        container_image.get_style_context ().add_class ("dim-label");
        container_image.get_style_context ().add_class ("image");
        container_image.max_width_chars = 16;
        container_image.ellipsize = Pango.EllipsizeMode.END;
        container_image.halign = Gtk.Align.START;
        box.pack_end (container_image, false);
    }
}
