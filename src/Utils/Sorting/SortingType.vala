class Utils.Sorting.SortingType : Object, SortingInterface {
    public string code {
        get {
            return "type";
        }
    }

    public string name {
        get {
            return _ ("Type");
        }
    }

    public int compare (DockerContainer a, DockerContainer b) {
        if (this.weight (a) == this.weight (b)) {
            return strcmp (a.name, b.name);
        }

        return this.weight (a) < this.weight (b) ? -1 : +1;
    }

    private int weight (DockerContainer container) {
        var weight = 0;

        switch (container.type) {
            case DockerContainerType.GROUP:
                weight = 1;
                break;

            case DockerContainerType.CONTAINER:
                weight = 10;
                break;
        }

        return weight;
    }
}
