/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils;

class Widgets.Screens.Main.ContainerCard : Gtk.FlowBoxChild {
    private DockerContainer container;

    public ContainerCard (DockerContainer container) {
        this.container = container;

        var card_actions = new ContainerCardActions (container);
        card_actions.hexpand = true;
        card_actions.halign = Gtk.Align.END;

        var grid = new Gtk.Grid ();
        grid.attach (this.build_container_icon (), 1, 1, 1, 2);
        grid.attach (this.build_container_name (), 2, 1, 1, 1);
        grid.attach (this.build_container_status_label () ?? this.build_container_image (), 2, 2, 1, 1);
        grid.attach (card_actions, 3, 1, 1, 2);

        this.get_style_context ().add_class ("docker-container");
        this.add (grid);

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

    private Gtk.Widget? build_container_status_label () {
        var info = Utils.DockerContainerStatusLabel.create_by_container (this.container);

        if (info == null) {
            return null;
        }

        info.halign = Gtk.Align.START;
        info.valign = Gtk.Align.START;

        return info;
    }

    private Gtk.Widget build_container_image () {
        var label = new Gtk.Label (this.container.image);

        label.get_style_context ().add_class ("docker-container-image");
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
