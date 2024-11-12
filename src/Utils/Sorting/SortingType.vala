/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

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
