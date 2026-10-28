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

namespace Docker {
    errordomain ApiClientError {
        ERROR,
        ERROR_JSON,
        ERROR_ACCESS,
        ERROR_NO_ENTRY,
    }

    struct Container {
        public string id;
        public string name;
        public string image;
        public string state;
        public string? label_project;
        public string? label_service;
        public string? label_config;
        public string? label_workdir;
    }

    struct ContainerInspectInfo {
        public string name;
        public string image;
        public string status;
        public string[]? binds;
        public string[]? envs;
        public string[]? ports;
    }

    struct DockerVersionInfo {
        public string version;
        public string api_version;
    }

    class ApiClient : Object {
        public HttpClient http_client;

        public ApiClient () {
            this.http_client = new HttpClient ();
            this.http_client.verbose = false;
            this.http_client.base_url = @"http://localhost/v$(DOCKER_ENIGINE_API_VERSION)";
            this.http_client.unix_socket_path = DOCKER_ENGINE_SOCKET_PATH;
        }

        private static Json.Node parse_json (HttpClientResponse resp) throws ApiClientError {
            try {
                var parser = new Json.Parser ();
                parser.load_from_stream (resp.body_data_stream);

                var node = parser.get_root ();

                if (node == null) {
                    throw new ApiClientError.ERROR_JSON ("Empty json response");
                }

                return node;
            } catch (Error error) {
                throw new ApiClientError.ERROR_JSON (error.message);
            }
        }

        private static Json.Object? get_object_member_or_null (Json.Object object, string member_name) {
            var node = object.get_member (member_name);

            if (node == null || node.get_node_type () != Json.NodeType.OBJECT) {
                return null;
            }

            return node.get_object ();
        }

        // Formats port bindings like `docker ps` does: "0.0.0.0:8080 -> 80/tcp"
        private static string[]? format_ports (Json.Object? bindings_object) {
            if (bindings_object == null) {
                return null;
            }

            string[] ports = {};

            bindings_object.foreach_member ((obj, key, binding_node) => {
                if (binding_node.get_node_type () != Json.NodeType.ARRAY) {
                    return;
                }

                foreach (var port_node in binding_node.get_array ().get_elements ()) {
                    var port_object = port_node.get_object ();
                    assert_nonnull (port_object);

                    var ip = port_object.get_string_member_with_default ("HostIp", "");
                    var port = port_object.get_string_member_with_default ("HostPort", "");

                    var host_addr = ip.length > 0 ? ip : "0.0.0.0";
                    if (host_addr.contains (":")) {
                        host_addr = @"[$host_addr]";
                    }

                    // the host port is empty when docker picks it on start
                    ports += port.length > 0 ? @"$host_addr:$port -> $key" : @"$host_addr -> $key";
                }
            });

            return ports.length > 0 ? ports : null;
        }

        public async Container[] list_containers () throws ApiClientError {
            try {
                var container_list = new Container[0];
                var resp = yield this.http_client.r_get ("/containers/json?all=true");

                //
                if (resp.code == 400) {
                    throw new ApiClientError.ERROR ("Bad parameter");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }

                //
                var root_node = parse_json (resp);
                var root_array = root_node.get_array ();
                assert_nonnull (root_array);

                foreach (var container_node in root_array.get_elements ()) {
                    var container = Container ();
                    var container_object = container_node.get_object ();
                    assert_nonnull (container_object);

                    //
                    container.id = container_object.get_string_member ("Id");
                    container.image = container_object.get_string_member ("Image");
                    container.state = container_object.get_string_member ("State");

                    //
                    var name_array = container_object.get_array_member ("Names");

                    foreach (var name_node in name_array.get_elements ()) {
                        container.name = name_node.get_string ();
                        assert_nonnull (container.name);
                        break;
                    }

                    //
                    var labels_object = container_object.get_object_member ("Labels");
                    assert_nonnull (labels_object);

                    if (labels_object.has_member ("com.docker.compose.project")) {
                        container.label_project = labels_object.get_string_member ("com.docker.compose.project");
                    }
                    if (labels_object.has_member ("com.docker.compose.service")) {
                        container.label_service = labels_object.get_string_member ("com.docker.compose.service");
                    }
                    if (labels_object.has_member ("com.docker.compose.project.config_files")) {
                        container.label_config = labels_object.get_string_member ("com.docker.compose.project.config_files");
                    }
                    if (labels_object.has_member ("com.docker.compose.project.working_dir")) {
                        container.label_workdir = labels_object.get_string_member ("com.docker.compose.project.working_dir");
                    }

                    //
                    container_list += container;
                }

                return container_list;
            } catch (HttpClientError error) {
                if (error is HttpClientError.ERROR_NO_ENTRY) {
                    throw new ApiClientError.ERROR_NO_ENTRY (error.message);
                } else if (error is HttpClientError.ERROR_ACCESS) {
                    throw new ApiClientError.ERROR_ACCESS (error.message);
                } else {
                    throw new ApiClientError.ERROR (error.message);
                }
            }
        }

        public async void start_container (Container container) throws ApiClientError {
            try {
                var resp = yield this.http_client.r_post (@"/containers/$(container.id)/start");

                if (resp.code == 304) {
                    return;
                }
                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }
            } catch (HttpClientError error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async void stop_container (Container container) throws ApiClientError {
            try {
                var resp = yield this.http_client.r_post (@"/containers/$(container.id)/stop");

                if (resp.code == 304) {
                    return;
                }
                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }
            } catch (HttpClientError error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async void pause_container (Container container) throws ApiClientError {
            try {
                var resp = yield this.http_client.r_post (@"/containers/$(container.id)/pause");

                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }
            } catch (HttpClientError error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async void restart_container (Container container) throws ApiClientError {
            try {
                var resp = yield this.http_client.r_post (@"/containers/$(container.id)/restart");

                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }
            } catch (HttpClientError error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async void unpause_container (Container container) throws ApiClientError {
            try {
                var resp = yield this.http_client.r_post (@"/containers/$(container.id)/unpause");

                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }
            } catch (HttpClientError error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async void remove_container (Container container) throws ApiClientError {
            try {
                var resp = yield this.http_client.r_delete (@"/containers/$(container.id)");

                if (resp.code == 400) {
                    throw new ApiClientError.ERROR ("Bad parameter");
                }
                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 409) {
                    throw new ApiClientError.ERROR ("Conflict");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }
            } catch (HttpClientError error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async ContainerInspectInfo inspect_container (Container container) throws ApiClientError {
            try {
                var container_info = ContainerInspectInfo ();
                var resp = yield this.http_client.r_get (@"/containers/$(container.id)/json");

                //
                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }

                //
                var root_node = parse_json (resp);
                var root_object = root_node.get_object ();
                assert_nonnull (root_object);

                //
                container_info.name = root_object.get_string_member_with_default ("Name", _ ("Unknown"));

                //
                var state_object = root_object.get_object_member ("State");
                assert_nonnull (state_object);

                container_info.status = state_object.get_string_member_with_default ("Status", _ ("Unknown"));

                //
                var config_object = root_object.get_object_member ("Config");
                assert_nonnull (config_object);

                container_info.image = config_object.get_string_member_with_default ("Image", _ ("Unknown"));

                //
                var env_array = config_object.get_array_member ("Env");

                if (env_array != null && env_array.get_length () > 0) {
                    container_info.envs = new string[0];

                    foreach (var env_node in env_array.get_elements ()) {
                        container_info.envs += env_node.get_string () ?? _ ("Unknown");
                    }
                }

                //
                var host_config_object = get_object_member_or_null (root_object, "HostConfig");

                if (host_config_object != null) {
                    var binds_array = host_config_object.get_array_member ("Binds");

                    if (binds_array != null && binds_array.get_length () > 0) {
                        container_info.binds = new string[0];

                        foreach (var bind_node in binds_array.get_elements ()) {
                            container_info.binds += bind_node.get_string () ?? _ ("Unknown");
                        }
                    }
                }

                // actual bindings of a running container, otherwise the configured ones
                var network_settings_object = get_object_member_or_null (root_object, "NetworkSettings");

                if (network_settings_object != null) {
                    container_info.ports = format_ports (get_object_member_or_null (network_settings_object, "Ports"));
                }

                if (container_info.ports == null && host_config_object != null) {
                    container_info.ports = format_ports (get_object_member_or_null (host_config_object, "PortBindings"));
                }

                return container_info;
            } catch (HttpClientError error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async DockerVersionInfo version () throws ApiClientError {
            try {
                var version = Docker.DockerVersionInfo ();
                var resp = yield this.http_client.r_get ("/version");

                //
                var root_node = parse_json (resp);
                var root_object = root_node.get_object ();
                assert_nonnull (root_object);

                version.version = root_object.get_string_member_with_default ("Version", "-");
                version.api_version = root_object.get_string_member_with_default ("ApiVersion", "-");

                return version;
            } catch (HttpClientError error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async void ping () throws ApiClientError {
            try {
                yield this.http_client.r_get ("/_ping");
            } catch (HttpClientError error) {
                if (error is HttpClientError.ERROR_NO_ENTRY) {
                    throw new ApiClientError.ERROR_NO_ENTRY (error.message);
                } else {
                    throw new ApiClientError.ERROR (error.message);
                }
            }
        }
    }
}
