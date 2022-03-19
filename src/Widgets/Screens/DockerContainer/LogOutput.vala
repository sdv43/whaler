using Utils.DataEntities;
using Docker;

class Widgets.Screens.DockerContainer.LogOutput : Gtk.ScrolledWindow {
    private Gtk.TextView log_text_view;
    private Container? current_service;
    private ContainerLogWatcher? watcher;

    public LogOutput () {
        var state_root = State.Root.get_instance ();
        var state_docker_container = state_root.screen_docker_container;
        var text_view = new Gtk.TextView ();
        var log_buffer = new Gtk.TextBuffer (null);

        text_view.get_style_context ().add_class ("terminal");
        text_view.editable = false;
        text_view.cursor_visible = false;
        text_view.buffer = log_buffer;

        this.log_text_view = text_view;
        this.current_service = null;
        this.watcher = null;
        this.get_style_context ().add_class ("log-output");
        this.add (text_view);

        this.vadjustment.changed.connect (() => {
            if (state_docker_container.is_auto_scroll_enable) {
                this.vadjustment.value = this.vadjustment.upper - this.vadjustment.page_size;
            }
        });

        state_docker_container.notify["service"].connect (() => {
            var err_msg = _ ("Cannot get container logs");

            this.update_service.begin (state_docker_container.service, (_, res) => {
                try {
                    this.update_service.end (res);
                } catch (Error e) {
                    ScreenError.get_instance ().show_error_dialog (err_msg, e.message);
                }
            });
        });
    }

    public async void update_service (Container service) throws Error {
        var is_service_changed = this.current_service != null
                                 ? this.current_service.container_id != service.container_id
                                 : true;

        if (is_service_changed) {
            if (this.watcher != null) {
                yield this.watcher.watch_stop ();
            }

            this.watcher = new ContainerLogWatcher (this.log_text_view.buffer, service);
            this.log_text_view.buffer.text = "";

            yield this.watcher.read_tail ();

            if (service.state == ContainerState.RUNNING) {
                yield this.watcher.watch_start ();
            }
        } else {
            if (service.state == ContainerState.RUNNING && !this.watcher.is_watching) {
                yield this.watcher.watch_start ();
            }
        }

        this.current_service = service;
    }
}
