/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

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

        this.add (label);
    }
}
