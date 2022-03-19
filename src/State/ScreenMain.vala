using Utils.DataEntities;
using Utils.Sorting;

class State.ScreenMain : Object {
    public string search_term {get; set;}
    public SortingInterface? sorting {get; set;}

    public ScreenMain (Root root) {
        this.search_term = "";
        this.sorting = new SortingName ();
    }
}
