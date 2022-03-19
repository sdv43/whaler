namespace Utils.DataEntities {
    class Container {
        public string name;
        public ContainerType type;
        public ContainerState state;
        public string container_id;
        public string container_name;
        public string? container_image;
        public string? app_name;
        public string? app_service;
        public string? app_config;
        public string? app_workdir;
        public Container[]? containers;
    }

    enum ContainerType {
        APP,
        CONTAINER
    }

    enum ContainerState {
        UNKNOWN,
        PAUSED,
        RUNNING,
        STOPPED,
    }
}
