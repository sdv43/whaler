using Utils.DataEntities;

class Utils.Sorting.SortingName : Object, SortingInterface {
    public string code {
        get {
            return "name";
        }
    }

    public string name {
        get {
            return _ ("Name");
        }
    }

    public int compare (Container a, Container b) {
        return strcmp (a.name, b.name);
    }
}
