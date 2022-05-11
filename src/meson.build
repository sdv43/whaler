configuration = configuration_data()

configuration.set_quoted('APP_ID', meson.project_name())
configuration.set_quoted('APP_VERSION', meson.project_version())
configuration.set_quoted('LOCALE_DIR', join_paths (get_option('prefix'), get_option('localedir')))

constants = configure_file(
    input : 'Utils/Constants.vala.in',
    output : 'Constants.vala',
    configuration : configuration
)

#
sources = files(    
    'Application.vala',

    'Utils/DockerContainer.vala',
    'Utils/HttpClient.vala',
    'Utils/Helpers.vala',
    'Utils/Theme.vala',
    'Utils/Sorting/SortingInterface.vala',
    'Utils/Sorting/SortingName.vala',
    'Utils/Sorting/SortingType.vala',

    'State/Root.vala',
    'State/ScreenMain.vala',
    'State/ScreenDockerContainer.vala',
    
    'Widgets/HeaderBar.vala',
    'Widgets/ScreenManager.vala',
    'Widgets/ScreenError.vala',
    'Widgets/ScreenMain.vala',
    'Widgets/ScreenDockerContainer.vala',

    'Widgets/Screens/Main/ContainersGrid.vala',
    'Widgets/Screens/Main/ContainersGridFilter.vala',
    'Widgets/Screens/Main/ContainerCard.vala',
    'Widgets/Screens/Main/ContainerCardActions.vala',

    'Widgets/Screens/DockerContainer/TopBar.vala',
    'Widgets/Screens/DockerContainer/TopBarActions.vala',
    'Widgets/Screens/DockerContainer/SideBar.vala',
    'Widgets/Screens/DockerContainer/SideBarItem.vala',
    'Widgets/Screens/DockerContainer/SideBarSeparator.vala',
    'Widgets/Screens/DockerContainer/Log.vala',
    'Widgets/Screens/DockerContainer/LogOutput.vala',

    'Widgets/Utils/ConfirmationDialog.vala',
    'Widgets/Utils/ContainerInfoDialog.vala',
    'Widgets/Utils/DockerContainerStatusLabel.vala',

    'Docker/ApiClient.vala',
    'Docker/ContainerLogWatcher.vala',
)