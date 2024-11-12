/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils.Sorting;
using Utils.Constants;

class Widgets.Screens.Main.ContainersGridFilter : Gtk.Box {
    public ContainersGridFilter () {
        var first_launch = true;
        var state = State.Root.get_instance ();
        var search_entry = this.build_search_entry ();

        this.sensitive = false;
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.spacing = 0;

        this.get_style_context ().add_class ("docker-containers-filter");
        this.pack_start (search_entry, false, false);
        this.pack_end (this.build_sorting_combobox (), false, false);

        state.notify["containers"].connect (() => {
            this.sensitive = state.containers.size > 0;

            if (this.sensitive && first_launch) {
                search_entry.grab_focus ();
                first_launch = false;
            }
        });
    }

    private Gtk.Widget build_search_entry () {
        var state = State.Root.get_instance ();
        var entry = new Gtk.SearchEntry ();
        var settings = new Settings (APP_ID);

        entry.width_request = 240;
        entry.search_changed.connect (() => {
            state.screen_main.search_term = entry.text.down (entry.text.length);
        });

        settings.bind ("main-screen-search-term", entry, "text", SettingsBindFlags.DEFAULT);

        return entry;
    }

    private Gtk.Widget build_sorting_combobox () {
        SortingInterface[] sortings = {
            new SortingStatus (),
            new SortingName (),
            new SortingType ()
        };

        var state = State.Root.get_instance ();
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        var label = new Gtk.Label (_ ("Sort by:"));
        box.pack_start (label, false, false, 12);

        var combo = new Gtk.ComboBoxText ();
        foreach (var sorting in sortings) {
            combo.append_text (sorting.name);
        }
        box.pack_end (combo, false, false);

        combo.changed.connect ((combo) => {
            state.screen_main.sorting = sortings[combo.active];
        });

        var settings = new Settings (APP_ID);
        settings.bind ("main-screen-sorting", combo, "active", SettingsBindFlags.DEFAULT);

        return box;
    }

}
