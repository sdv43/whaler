/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils.Constants;

class Widgets.Screens.Container.Log : Gtk.Overlay {
    public Log () {
        this.add (new LogOutput ());
        this.add_overlay (this.build_switcher_container ());
    }

    private Gtk.Widget build_switcher_container () {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.get_style_context ().add_class ("auto-scroll");
        box.valign = Gtk.Align.CENTER;
        box.halign = Gtk.Align.CENTER;
        box.pack_start (this.build_switcher_label (), false);
        box.pack_end (this.build_switcher (box), false);

        var event_box = new Gtk.EventBox ();
        event_box.valign = Gtk.Align.START;
        event_box.halign = Gtk.Align.END;
        event_box.set_events (box.get_events () | Gdk.EventMask.ENTER_NOTIFY_MASK);
        event_box.add (box);

        event_box.enter_notify_event.connect ((e) => {
            box.get_style_context ().add_class ("visible");

            return false;
        });

        event_box.leave_notify_event.connect ((e) => {
            box.get_style_context ().remove_class ("visible");

            return false;
        });

        return event_box;
    }

    private Gtk.Widget build_switcher_label () {
        var label = new Gtk.Label (_ ("Autoscroll") + ":");
        label.valign = Gtk.Align.CENTER;
        label.halign = Gtk.Align.END;

        return label;
    }

    private Gtk.Widget build_switcher (Gtk.Widget box) {
        var switcher = new Gtk.Switch ();
        switcher.valign = Gtk.Align.CENTER;
        switcher.halign = Gtk.Align.START;
        switcher.get_style_context ().add_class ("auto-scroll-switcher");
        switcher.set_tooltip_text (_ ("Enable autoscroll to bottom border"));

        var settings = new Settings (APP_ID);
        settings.bind ("screen-docker-container-autoscroll", switcher, "active", SettingsBindFlags.DEFAULT);

        switcher.enter_notify_event.connect ((e) => {
            box.get_style_context ().add_class ("visible");

            return false;
        });

        switcher.leave_notify_event.connect ((e) => {
            box.get_style_context ().remove_class ("visible");

            return false;
        });

        var state_root = State.Root.get_instance ();
        state_root.screen_docker_container.is_auto_scroll_enable = switcher.active;

        switcher.notify["active"].connect (() => {
            state_root.screen_docker_container.is_auto_scroll_enable = switcher.active;
        });

        return switcher;
    }
}
