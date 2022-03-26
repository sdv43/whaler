using Utils;

class State.ScreenDockerContainer : Object {
    private Root root;

    public bool is_auto_scroll_enable;
    public DockerContainer? container {get; set;}
    public DockerContainer? service {get; set;}

    public ScreenDockerContainer (Root root) {
        this.root = root;
        this.is_auto_scroll_enable = false;
        this.container = null;
        this.service = null;

        this.root.notify["containers"].connect (() => {
            if (this.container == null) {
                return;
            }

            var index = root.containers.index_of (this.container);

            if (index != -1) {
                this.container = root.containers[index];
            }
        });

        this.notify["container"].connect (() => {
            if (this.container.type == DockerContainerType.GROUP) {
                if (this.service == null) {
                    this.service = this.container;
                } else {
                    var index = this.container.services.index_of (this.service);

                    if (index != -1) {
                        this.service = this.container.services[index];
                    } else {
                        this.service = this.container;
                    }
                }
            } else {
                this.service = this.container;
            }
        });
    }
}
