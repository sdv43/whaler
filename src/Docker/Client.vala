using Utils.DataEntities;

errordomain Docker.ClientError {
    ERROR,
    ERROR_JSON,
}

class Docker.Client {

    public static async string[] command_run (string[] argv) throws ClientError {
        try {
            var command = new Command (argv);

            yield command.run ();

            if (command.status != 0) {
                throw new ClientError.ERROR (string.joinv ("\n", command.stderr_lines));
            }

            return command.stdout_lines;
        } catch (CommandError error) {
            throw new ClientError.ERROR (error.message);
        }
    }

    private static Json.Node parse_json (string data) throws ClientError {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (data);

            var node = parser.get_root ();

            if (node == null) {
                throw new ClientError.ERROR_JSON ("Cannot parse json from: %s", data);
            }

            return node;
        } catch (Error error) {
            throw new ClientError.ERROR_JSON (error.message);
        }
    }

    public static async Container[] container_ls_all () throws ClientError {
        //  throw new ClientError.ERROR_JSON ("test error");

        //  var c0 = new Container ();
        //  c0.container_id = "id-1";
        //  c0.container_name = "blog_database";
        //  c0.container_image = "mysql:8";
        //  c0.name = "Mysql-sandbox";
        //  c0.type = ContainerType.CONTAINER;
        //  c0.state = ContainerState.STOPPED;

        //  var c1 = new Container ();
        //  c1.container_id = "id-2";
        //  c1.container_name = "nginx_demo";
        //  c1.container_image = "nginx:stable";
        //  c1.name = "Nginx-demo";
        //  c1.type = ContainerType.CONTAINER;
        //  c1.state = ContainerState.STOPPED;

        //  var c2 = new Container ();
        //  c2.container_id = "id-3";
        //  c2.container_name = "wordpress_demo";
        //  c2.container_image = "wordpress, db";
        //  c2.name = "App-demo-wordpress";
        //  c2.type = ContainerType.APP;
        //  c2.state = ContainerState.RUNNING;

        //  var c3 = new Container ();
        //  c3.container_id = "id-4";
        //  c3.container_name = "id-4";
        //  c3.container_image = "php";
        //  c3.name = "Php-sandbox";
        //  c3.type = ContainerType.APP;
        //  c3.state = ContainerState.STOPPED;

        //  var c4 = new Container ();
        //  c4.container_id = "id-5";
        //  c4.container_name = "id-5";
        //  c4.container_image = "nuxt";
        //  c4.name = "Nuxt-project";
        //  c4.type = ContainerType.CONTAINER;
        //  c4.state = ContainerState.RUNNING;

        //  return {c0, c1, c2, c3, c4};

        // get all container names
        var output = yield command_run ({"docker", "container", "ls", "-a", "--format={{json .Names}}"});
        string[] cmd_inspect = {"docker", "container", "inspect"};

        foreach (var line in output) {
            var root = parse_json (line);
            var name = root.get_string ();

            if (name == null || name.length == 0) {
                warning ("Cannot get name from: %s", line);
                continue;
            }

            cmd_inspect += name;
        }

        // get detailed information on each container
        var containers = new Container[0];

        cmd_inspect += "--format={{json .}}";
        output = yield command_run (cmd_inspect);

        foreach (var line in output) {
            var root = parse_json (line);
            var item = new Container ();

            if (root.get_node_type () != Json.NodeType.OBJECT) {
                warning ("Root node is not an object, json: %s", line);
                continue;
            }

            var root_obj = root.get_object ();
            assert_nonnull (root_obj);

            item.container_id = root_obj.get_string_member ("Id");
            item.container_name = root_obj.get_string_member ("Name");
            item.type = ContainerType.CONTAINER;
            item.name = Utils.format_container_name (item.container_name);

            // State
            item.state = ContainerState.STOPPED;

            var state = root_obj.get_member ("State");

            if (state != null && state.get_node_type () == Json.NodeType.OBJECT) {
                var state_obj = root_obj.get_object_member ("State");
                assert_nonnull (state_obj);

                var status = state_obj.get_string_member ("Status");

                switch (status) {
                    case "running":
                        item.state = ContainerState.RUNNING;
                        break;

                    case "paused":
                        item.state = ContainerState.PAUSED;
                        break;

                    case "exited":
                        item.state = ContainerState.STOPPED;
                        break;

                    default:
                        item.state = ContainerState.UNKNOWN;
                        warning ("Unknown docker container status: %s, container: %s", status, item.container_name);
                        break;
                }
            } else {
                warning ("Cannot get status for container: %s", item.container_name);
                continue;
            }

            // Config
            var config = root_obj.get_member ("Config");

            if (config != null && config.get_node_type () == Json.NodeType.OBJECT) {
                var config_obj = root_obj.get_object_member ("Config");
                assert_nonnull (config_obj);

                item.container_image = config_obj.get_string_member ("Image");

                // Labels
                var label = config_obj.get_member ("Labels");

                if (label != null && label.get_node_type () == Json.NodeType.OBJECT) {
                    var labels_obj = config_obj.get_object_member ("Labels");
                    assert_nonnull (labels_obj);

                    if (labels_obj.has_member ("com.docker.compose.project")) {
                        item.app_name = labels_obj.get_string_member ("com.docker.compose.project");
                    }
                    if (labels_obj.has_member ("com.docker.compose.service")) {
                        item.app_service = labels_obj.get_string_member ("com.docker.compose.service");
                    }
                    if (labels_obj.has_member ("com.docker.compose.project.config_files")) {
                        item.app_config = labels_obj.get_string_member ("com.docker.compose.project.config_files");
                    }
                    if (labels_obj.has_member ("com.docker.compose.project.working_dir")) {
                        item.app_workdir = labels_obj.get_string_member ("com.docker.compose.project.working_dir");
                    }
                }
            } else {
                warning ("Cannot get config for container: %s", item.container_name);
                continue;
            }

            containers += item;
        }

        // grouping containers into applications
        Container[] result = {};
        string[] apps = {};

        for (var i = 0; i < containers.length; i++) {
            var container = containers[i];

            if (container.app_name == null) {
                // single container
                result += container;
            } else {
                // if the container has already been processed
                if (container.app_name in apps) {
                    continue;
                }

                // create docker compose application
                var app = new Container ();

                app.type = ContainerType.APP;
                app.container_id = container.app_name;
                app.name = Utils.format_container_name (container.app_name);
                app.state = ContainerState.STOPPED;
                app.app_name = container.app_name;
                app.app_config = Path.build_filename (
                    container.app_workdir,
                    Path.get_basename (container.app_config)
                );
                app.app_workdir = container.app_workdir;
                app.containers = {};

                debug ("dcps: %s, %s", app.name, app.app_config);

                // search for containers with the same project
                for (var j = i; j < containers.length; j++) {
                    var service = containers[j];

                    if (service.app_name != null && service.app_name == app.app_name) {
                        service.name = Utils.ucfirst (service.app_service);
                        app.containers += service;
                    }
                }

                //
                string?[] services = {};

                foreach (var service in app.containers) {
                    services += service.app_service;
                }

                app.container_image = string.joinv (", ", services);

                // mark that the application has already been processed
                apps += app.app_name;

                // saving the container to the resulting array
                result += app;
            }
        }

        // determine the status of applications
        for (var i = 0; i < result.length; i++) {
            if (result[i].type != ContainerType.APP) {
                continue;
            }

            var is_all_running = true;
            var is_all_paused = true;

            foreach (var service in result[i].containers) {
                is_all_running = is_all_running && service.state == ContainerState.RUNNING;
                is_all_paused = is_all_paused && service.state == ContainerState.PAUSED;
            }

            if (is_all_running) {
                result[i].state = ContainerState.RUNNING;
            }

            if (is_all_paused) {
                result[i].state = ContainerState.PAUSED;
            }
        }

        return result;
    }

    public static async void container_start (Container container) throws ClientError {
        //  throw new ClientError.ERROR ("some error");

        if (container.type == ContainerType.APP) {
            yield command_run ({
                "docker-compose",
                "-f", container.app_config,
                "start"
            });
        } else {
            yield command_run ({"docker", "container", "start", container.container_name});
        }
    }

    public static async void container_stop (Container container) throws ClientError {
        if (container.type == ContainerType.APP) {
            yield command_run ({
                "docker-compose",
                "-f", container.app_config,
                "stop"
            });
        } else {
            yield command_run ({"docker", "container", "stop", container.container_name});
        }
    }

    public static async void container_unpause (Container container) throws ClientError {
        if (container.type == ContainerType.APP) {
            yield command_run ({
                "docker-compose",
                "-f", container.app_config,
                "unpause"
            });
        } else {
            yield command_run ({"docker", "container", "unpause", container.container_name});
        }
    }

    public static async void container_pause (Container container) throws ClientError {
        if (container.type == ContainerType.APP) {
            yield command_run ({
                "docker-compose",
                "-f", container.app_config,
                "pause"
            });
        } else {
            yield command_run ({"docker", "container", "pause", container.container_name});
        }
    }

    public static async void container_remove (Container container) throws ClientError {
        if (container.type == ContainerType.APP) {
            yield command_run ({
                "docker-compose",
                "-f", container.app_config,
                "rm", "--force", "--stop"
            });
        } else {
            yield command_run ({"docker", "container", "rm", "--force", container.container_name});
        }
    }
}
