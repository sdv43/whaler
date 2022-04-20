using Utils;
using Utils.Constants;

namespace Docker {
    errordomain ApiClientError {
        ERROR,
        ERROR_JSON,
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

    class ApiClient : Object {
        public HttpClient http_client;
        public string version;

        public ApiClient () {
            this.version = "1.41";

            this.http_client = new HttpClient ();
            this.http_client.verbose = false;
            this.http_client.base_url = @"http://localhost/v$(DOCKER_ENIGINE_API_VERSION)";
            this.http_client.unix_socket_path = DOCKER_ENGINE_SOCKET_PATH;
        }

        private static Json.Node parse_json (string data) throws ApiClientError {
            try {
                var parser = new Json.Parser ();
                parser.load_from_data (data);

                var node = parser.get_root ();

                if (node == null) {
                    throw new ApiClientError.ERROR_JSON ("Cannot parse json from: %s", data);
                }

                return node;
            } catch (Error error) {
                throw new ApiClientError.ERROR_JSON (error.message);
            }
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
                var json = "";
                string? line = null;

                while ((line = resp.body_data_stream.read_line_utf8 (null, null)) != null) {
                    json += line;
                }

                //
                var root_node = parse_json (json);
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
            } catch (Error error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async void start_container (Container container) throws ApiClientError {
            try {
                var resp = yield this.http_client.r_post (@"/containers/$(container.id)/start");

                if (resp.code == 304) {
                    throw new ApiClientError.ERROR ("Container already started");
                }
                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }
            } catch (Error error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }

        public async void stop_container (Container container) throws ApiClientError {
            try {
                var resp = yield this.http_client.r_post (@"/containers/$(container.id)/stop");

                if (resp.code == 304) {
                    throw new ApiClientError.ERROR ("Container already stopped");
                }
                if (resp.code == 404) {
                    throw new ApiClientError.ERROR ("No such container");
                }
                if (resp.code == 500) {
                    throw new ApiClientError.ERROR ("Server error");
                }
            } catch (Error error) {
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
            } catch (Error error) {
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
            } catch (Error error) {
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
            } catch (Error error) {
                throw new ApiClientError.ERROR (error.message);
            }
        }
    }
}
