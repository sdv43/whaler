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
