using Utils.DataEntities;
using Widgets;

class State.Root : Object {
    private static Root? instance;
    private string? previuos_screen;

    public bool button_back_visible {get; set;}
    public string active_screen {get; set;}
    public Gee.ArrayList<Container> containers {get; set;}

    public ScreenMain screen_main {get; private set;}
    public ScreenDockerContainer screen_docker_container {get; private set;}

    private Root () {
        this.button_back_visible = false;
        this.active_screen = Widgets.ScreenMain.CODE;
        this.containers = new Gee.ArrayList<Container> ((a, b) => {
            return a.container_id == b.container_id;
        });

        this.screen_main = new ScreenMain (this);
        this.screen_docker_container = new ScreenDockerContainer (this);

        this.screen_main.notify["sorting"].connect (() => {
            this.containers.sort (this.screen_main.sorting.compare);
            this.notify_property ("containers");
        });
    }

    public static Root get_instance () {
        if (Root.instance == null) {
            Root.instance = new Root ();
        }

        return Root.instance;
    }

    public async void init () {
        var err_msg = _ ("Cannot get list of docker containers");

        try {
            yield this.containers_load();
        } catch (Docker.ClientError error) {
            Widgets.ScreenError.get_instance ().show_error_screen (err_msg, error.message);
        }
    }

    public void prev_screen () {
        if (previuos_screen == null) {
            return;
        }

        this.active_screen = this.previuos_screen;
        this.previuos_screen = null;
        this.button_back_visible = false;
    }

    public void next_screen (string code) {
        this.previuos_screen = this.active_screen;
        this.active_screen = code;
        this.button_back_visible = true;
    }

    public async void containers_load () throws Docker.ClientError {
        this.containers.clear ();
        this.containers.add_all_array (yield Docker.Client.container_ls_all ());
        this.containers.sort (this.screen_main.sorting.compare);
        this.notify_property ("containers");
    }

    public async void container_start (Container container) throws Docker.ClientError {
        yield Docker.Client.container_start (container);
        yield this.containers_load ();
    }

    public async void container_stop (Container container) throws Docker.ClientError {
        yield Docker.Client.container_stop (container);
        yield this.containers_load ();
    }

    public async void container_unpause (Container container) throws Docker.ClientError {
        yield Docker.Client.container_unpause (container);
        yield this.containers_load ();
    }

    public async void container_pause (Container container) throws Docker.ClientError {
        yield Docker.Client.container_pause (container);
        yield this.containers_load ();
    }

    public async void container_remove (Container container) throws Docker.ClientError {
        yield Docker.Client.container_remove  (container);
        yield this.containers_load ();
    }
}
