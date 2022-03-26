using Utils;

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

    public int compare (DockerContainer a, DockerContainer b) {
        return strcmp (a.name, b.name);
    }
}
