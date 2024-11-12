/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

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
