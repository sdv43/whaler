using Utils.DataEntities;

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

    public int compare (Container a, Container b) {
        if (this.weight (a) == this.weight (b)) {
            return strcmp (a.name, b.name);
        }

        return this.weight (a) < this.weight (b) ? -1 : +1;
    }

    private int weight (Container container) {
        var weight = 0;

        switch (container.type) {
            case ContainerType.APP:
                weight = 1;
                break;

            case ContainerType.CONTAINER:
                weight = 10;
                break;
        }

        return weight;
    }
}
