using Utils.DataEntities;

class State.ScreenDockerContainer : Object {
    private Root root;

    public bool is_auto_scroll_enable;
    public Container? container {get; set;}
    public Container? service {get; set;}

    public ScreenDockerContainer (Root root) {
        this.root = root;
        this.is_auto_scroll_enable = false;
        this.container = null;
        this.service = null;

        this.root.notify["containers"].connect (() => {
            if (this.container == null) {
                return;
            }

            foreach (var container in this.root.containers) {
                if (this.container.container_id == container.container_id) {
                    this.container = container;

                    if (this.service != null && container.containers != null) {
                        foreach (var service in container.containers) {
                            if (this.service.container_id == service.container_id) {
                                this.service = service;
                            }
                        }
                    }
                }
            }
        });
    }
}
