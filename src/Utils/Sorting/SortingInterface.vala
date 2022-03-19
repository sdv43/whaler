using Utils.DataEntities;

interface Utils.Sorting.SortingInterface : Object {
    public abstract string code { get; }
    public abstract string name { get; }

    public abstract int compare (Container a, Container b);
}
