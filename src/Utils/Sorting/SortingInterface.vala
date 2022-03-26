interface Utils.Sorting.SortingInterface : Object {
    public abstract string code { get; }
    public abstract string name { get; }

    public abstract int compare (DockerContainer a, DockerContainer b);
}
