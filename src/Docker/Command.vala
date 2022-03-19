errordomain Docker.CommandError {
    ERROR
}

class Docker.Command {
    private string[] argv;
    private Subprocess subprocess;
    private DataInputStream stdout;
    private DataInputStream stderr;

    public int? status;
    public string[] stdout_lines;
    public string[] stderr_lines;

    public Command (string[] argv) {
        this.status = null;
        this.stdout_lines = new string[0];
        this.stderr_lines = new string[0];
        this.argv = argv;
    }

    public async string[] run () throws CommandError {
        try{
            this.subprocess = new Subprocess.newv (
                this.argv,
                SubprocessFlags.STDERR_PIPE | SubprocessFlags.STDOUT_PIPE
            );
            this.stdout = new DataInputStream (this.subprocess.get_stdout_pipe ());
            this.stderr = new DataInputStream (this.subprocess.get_stderr_pipe ());

            string? stdout_read_error = null;
            string? stderr_read_error = null;

            this.read_all_lines.begin (this.stderr, (_, res) => {
                try{
                    this.stderr_lines = this.read_all_lines.end (res);
                } catch (IOError error) {
                    warning ("Stderr read error: %s", error.message);
                    stderr_read_error = error.message;
                } finally {
                    this.run.callback ();
                }
            });

            this.read_all_lines.begin (this.stdout, (_, res) => {
                try{
                    this.stdout_lines = this.read_all_lines.end (res);
                } catch (IOError error) {
                    warning ("Stdout read error: %s", error.message);
                    stdout_read_error = error.message;
                } finally {
                    this.run.callback ();
                }
            });

            yield; yield;
            yield this.subprocess.wait_async (null);

            this.status = this.subprocess.get_status ();

            if (stderr_read_error != null) {
                throw new CommandError.ERROR (stderr_read_error);
            }

            if (stdout_read_error != null) {
                throw new CommandError.ERROR (stdout_read_error);
            }

            return stdout_lines;
        } catch (Error error) {
            warning ("Spawn process error: %s", error.message);
            throw new CommandError.ERROR (error.message);
        }
    }

    private async string[] read_all_lines (DataInputStream stream) throws IOError {
        string? line = null;
        string[] lines = new string[0];

        while ((line = yield stream.read_line_async (Priority.DEFAULT)) != null) {
            lines += line;
        }

        return lines;
    }
}
