/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils;
using Utils.Constants;
using Widgets;
using Docker;

class State.Root : Object {
    private ApiClient api_client;
    private static Root? instance;
    private string? previuos_screen;

    public bool button_back_visible {get; set;}
    public string active_screen {get; set;}
    public Gee.ArrayList<DockerContainer> containers {get; set;}

    public ScreenMain screen_main {get; private set;}
    public ScreenDockerContainer screen_docker_container {get; private set;}

    private Root () {
        var settings = new Settings (APP_ID);

        this.api_client = new ApiClient ();
        this.button_back_visible = false;
        this.active_screen = Widgets.ScreenMain.CODE;
        this.containers = new Gee.ArrayList<DockerContainer> (DockerContainer.equal);
        this.screen_main = new ScreenMain (this);
        this.screen_docker_container = new ScreenDockerContainer (this);

        settings.bind ("docker-api-socket-path", this.api_client.http_client, "unix_socket_path", SettingsBindFlags.GET);
    }

    public static Root get_instance () {
        if (Root.instance == null) {
            Root.instance = new Root ();
        }

        return Root.instance;
    }

    public async void init () {
        try {
            yield this.containers_load();
        } catch (ApiClientError error) {
            var error_widget = ScreenError.build_error_docker_not_avialable (
                error is ApiClientError.ERROR_NO_ENTRY
            );

            ScreenManager.screen_error_show_widget (error_widget);
        }
    }

    public void prev_screen () {
        if (previuos_screen == null) {
            return;
        }

        this.active_screen = this.previuos_screen;
        this.previuos_screen = null;
        this.button_back_visible = false;
    }

    public void next_screen (string code) {
        this.previuos_screen = this.active_screen;
        this.active_screen = code;
        this.button_back_visible = true;
    }

    public async void containers_load () throws ApiClientError {
        this.containers.clear ();

        // grouping containers into applications
        var api_containers = yield this.api_client.list_containers ();
        string[] projects = {};

        for (var i = 0; i < api_containers.length; i++) {
            var container = api_containers[i];

            if (container.label_project == null) {
                // single container
                this.containers.add (new DockerContainer.from_docker_api_container (container));
            } else {
                // if the container has already been processed
                if (container.label_project in projects) {
                    continue;
                }

                // create group
                var container_group = new DockerContainer ();

                var full_config_path = Path.build_filename (
                    container.label_workdir,
                    Path.get_basename (container.label_config)
                );

                container_group.id = full_config_path;
                container_group.name = container_group.format_name (container.label_project);
                container_group.image = "";
                container_group.type = DockerContainerType.GROUP;
                container_group.state = DockerContainerState.UNKNOWN;
                container_group.config_path = full_config_path;
                container_group.services = new Gee.ArrayList<DockerContainer> (DockerContainer.equal);

                // search for containers with the same project
                var is_all_running = true;
                var is_all_paused = true;
                var is_all_stopped = true;

                for (var j = i; j < api_containers.length; j++) {
                    var service = api_containers[j];

                    if (service.label_project != null && service.label_project == container.label_project) {
                        var s = new DockerContainer.from_docker_api_container (service);
                        s.name = s.format_name (service.label_service);

                        is_all_running = is_all_running && s.state == DockerContainerState.RUNNING;
                        is_all_paused = is_all_paused && s.state == DockerContainerState.PAUSED;
                        is_all_stopped = is_all_stopped && s.state == DockerContainerState.STOPPED;

                        container_group.services.add (s);
                    }
                }

                // image
                string?[] services = {};

                foreach (var service in container_group.services) {
                    services += service.name;
                }

                // state
                if (is_all_running) {
                    container_group.state = DockerContainerState.RUNNING;
                }
                if (is_all_paused) {
                    container_group.state = DockerContainerState.PAUSED;
                }
                if (is_all_stopped) {
                    container_group.state = DockerContainerState.STOPPED;
                }

                container_group.image = string.joinv (", ", services);

                // mark that the application has already been processed
                projects += container.label_project;

                // saving the container to the resulting array
                this.containers.add (container_group);
            }
        }

        this.notify_property ("containers");
    }

    public async void container_start (DockerContainer container) throws ApiClientError {
        if (container.type == DockerContainerType.GROUP) {
            foreach (var service in container.services) {
                yield this.api_client.start_container (service.api_container);
            }
        } else {
            assert_true (container.api_container != null);
            yield this.api_client.start_container (container.api_container);
        }

        yield this.containers_load ();
    }

    public async void container_stop (DockerContainer container) throws ApiClientError {
        if (container.type == DockerContainerType.GROUP) {
            foreach (var service in container.services) {
                yield this.api_client.stop_container (service.api_container);
            }
        } else {
            assert_true (container.api_container != null);
            yield this.api_client.stop_container (container.api_container);
        }

        yield this.containers_load ();
    }

    public async void container_restart (DockerContainer container) throws ApiClientError {
        if (container.type == DockerContainerType.GROUP) {
            foreach (var service in container.services) {
                yield this.api_client.restart_container (service.api_container);
            }
        } else {
            assert_true (container.api_container != null);
            yield this.api_client.restart_container (container.api_container);
        }

        yield this.containers_load ();
    }

    public async void container_pause (DockerContainer container) throws ApiClientError {
        if (container.type == DockerContainerType.GROUP) {
            foreach (var service in container.services) {
                yield this.api_client.pause_container (service.api_container);
            }
        } else {
            assert_true (container.api_container != null);
            yield this.api_client.pause_container (container.api_container);
        }

        yield this.containers_load ();
    }

    public async void container_unpause (DockerContainer container) throws ApiClientError {
        if (container.type == DockerContainerType.GROUP) {
            foreach (var service in container.services) {
                yield this.api_client.unpause_container (service.api_container);
            }
        } else {
            assert_true (container.api_container != null);
            yield this.api_client.unpause_container (container.api_container);
        }

        yield this.containers_load ();
    }

    public async void container_remove (DockerContainer container) throws ApiClientError {
        if (container.type == DockerContainerType.GROUP) {
            foreach (var service in container.services) {
                yield this.api_client.remove_container (service.api_container);
            }
        } else {
            assert_true (container.api_container != null);
            yield this.api_client.remove_container (container.api_container);
        }

        yield this.containers_load ();
    }

    public async Gee.HashMap<DockerContainer, ContainerInspectInfo?> container_inspect (DockerContainer container) throws ApiClientError {
        var container_info = new Gee.HashMap<DockerContainer, ContainerInspectInfo?> ();

        if (container.type == DockerContainerType.GROUP) {
            foreach (var service in container.services) {
                container_info[service] = yield this.api_client.inspect_container (service.api_container);
            }
        } else {
            assert_true (container.api_container != null);
            container_info[container] = yield this.api_client.inspect_container (container.api_container);
        }

        return container_info;
    }
}
