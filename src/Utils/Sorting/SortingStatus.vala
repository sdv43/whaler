class Utils.Sorting.SortingStatus : Object, SortingInterface {
    public string code {
        get {
            return "status";
        }
    }

    public string name {
        get {
            return _ ("Status");
        }
    }

    public int compare (DockerContainer a, DockerContainer b) {
        if (this.weight (a) == this.weight (b)) {
            return strcmp (a.name, b.name);
        }

        return this.weight (a) < this.weight (b) ? +1 : -1;
    }

    private int weight (DockerContainer container) {
        var weight = 0;

        switch (container.state) {
            case DockerContainerState.RUNNING:
                weight = 3;
                break;

            case DockerContainerState.PAUSED:
                weight = 2;
                break;

            case DockerContainerState.STOPPED:
                weight = 1;
                break;

            case DockerContainerState.UNKNOWN:
                weight = 0;
                break;
        }

        return weight;
    }
}
