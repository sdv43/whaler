/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

class Widgets.ScreenDockerContainer : Gtk.Box {
    public static string CODE = "docker-container";

    public ScreenDockerContainer () {
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.spacing = 0;

        this.get_style_context ().add_class ("screen-docker-container");
        this.pack_start (new Screens.Container.SideBar (), false);
        this.pack_end (this.build_log_output (), true, true);
    }

    private Gtk.Widget build_log_output () {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        box.pack_start (new Screens.Container.TopBar (), false);
        box.pack_end (new Screens.Container.Log (), true, true);

        return box;
    }
}
