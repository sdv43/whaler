using Utils.DataEntities;

class Docker.ContainerLogWatcher {
    public Gtk.TextBuffer buffer;
    public Container container;
    public Subprocess? watcher_process;
    public bool is_watching;

    public ContainerLogWatcher (Gtk.TextBuffer buffer, Container container) {
        this.container = container;
        this.buffer = buffer;
        this.watcher_process = null;
        this.is_watching = false;
    }

    private string[] get_argv (bool is_follow = false) {
        string[] argv = new string[0];

        if (this.container.type == ContainerType.APP) {
            argv += "docker-compose";
            argv += "-f";
            argv += container.app_config;
            argv += "logs";
            argv += "--no-color";

            if (is_follow) {
                argv += "--follow";
                argv +=  "--tail";
                argv +=  "0";
            }
        } else {
            argv += "docker";
            argv += "container";
            argv += "logs";

            if (is_follow) {
                argv += "--follow";
                argv +=  "--tail";
                argv +=  "0";
            }

            argv += this.container.container_name;
        }

        return argv;
    }

    public async void read_tail () throws IOError, Error {
        var subprocess = new Subprocess.newv (this.get_argv (), SubprocessFlags.STDERR_MERGE | SubprocessFlags.STDOUT_PIPE);
        var stdout = new DataInputStream (subprocess.get_stdout_pipe ());

        string? line = null;

        while ((line = yield stdout.read_line_async (Priority.DEFAULT)) != null) {
            line = line + "\n";
            this.buffer.insert_at_cursor (line, line.length);
        }
    }

    public async void watch_start () throws IOError, Error {
        this.watcher_process = new Subprocess.newv (this.get_argv (true), SubprocessFlags.STDERR_MERGE | SubprocessFlags.STDOUT_PIPE);
        var stdout = new DataInputStream (this.watcher_process.get_stdout_pipe ());

        this.is_watching = true;
        string? line = null;

        while ((line = yield stdout.read_line_async (Priority.DEFAULT)) != null) {
            line = line + "\n";
            this.buffer.insert_at_cursor (line, line.length);
        }

        yield this.watcher_process.wait_async (null);
        this.is_watching = false;
    }

    public async void watch_stop () throws Error {
        if (this.watcher_process == null) {
            return;
        }

        this.watcher_process.force_exit ();
        yield this.watcher_process.wait_async (null);

        this.watcher_process = null;
        this.is_watching = false;
    }
}
