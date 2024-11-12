/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

class Widgets.Utils.ConfirmationDialog : Granite.Dialog {
    public signal void cancel();
    public signal void accept();

    public ConfirmationDialog (string question, string yes, string no) {
        this.transient_for = Whaler.get_instance ().active_window;
        this.transient_for.sensitive = false;
        this.skip_taskbar_hint = true;
        this.add_button (no, Gtk.ResponseType.CANCEL);
        this.get_content_area ().add (this.build_question (question));

        var button_yes = this.add_button (yes, Gtk.ResponseType.ACCEPT);
        button_yes.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        this.response.connect ((resp_id) => {
            if (resp_id == Gtk.ResponseType.ACCEPT) {
                this.accept ();
            } else {
                this.cancel ();
            }

            this.transient_for.sensitive = true;
            this.destroy ();
        });

        this.show_all ();
    }

    private Gtk.Widget build_question (string question) {
        var label = new Gtk.Label (question);

        label.get_style_context ().add_class ("h3");
        label.get_style_context ().add_class ("confirmation-question");

        return label;
    }
}
