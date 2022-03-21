project('com.github.sdv43.whaler', 'vala', 'c', version: '1.0.0')

# Gnome resources
gnome = import('gnome')

gresource = gnome.compile_resources(
    'gresource',
    'data/gresource.xml',
    source_dir: 'data'
)

# Translations 
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

# Desktop file
i18n.merge_file(
    input: 'data/app.desktop',
    output: meson.project_name() + '.desktop',
    po_dir: meson.source_root() / 'po',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications'
)

# Metainfo file
i18n.merge_file(
    input: 'data/app.metainfo.xml',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.source_root() / 'po',
    install: true,
    install_dir: get_option('datadir') / 'metainfo'
)

# Icons
icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        'data/images/logo/' + i + '.svg',
        install_dir: get_option('datadir') + '/icons/hicolor/' + i + 'x' + i + '/apps',
        rename: meson.project_name() + '.svg'
    )
    
    install_data(
        'data/images/logo/' + i + '.svg',
        install_dir: get_option('datadir') + '/icons/hicolor/' + i + 'x' + i + '@2/apps',
        rename: meson.project_name() + '.svg'
    )
endforeach

# Settings
install_data (
    'data/gschema.xml',
    install_dir: get_option('datadir') + '/glib-2.0/schemas',
    rename: meson.project_name() + '.gschema.xml'
)

# 
executable(
    meson.project_name(),
    gresource,
    
    'src/Application.vala',

    'src/Utils/Constants.vala',
    'src/Utils/Helpers.vala',
    'src/Utils/Theme.vala',
    'src/Utils/DataEntities/Container.vala',
    'src/Utils/Sorting/SortingInterface.vala',
    'src/Utils/Sorting/SortingName.vala',
    'src/Utils/Sorting/SortingType.vala',

    'src/State/Root.vala',
    'src/State/ScreenMain.vala',
    'src/State/ScreenDockerContainer.vala',
    
    'src/Widgets/Utils/ConfirmationDialog.vala',

    'src/Widgets/HeaderBar.vala',
    'src/Widgets/ScreenManager.vala',
    'src/Widgets/ScreenError.vala',
    'src/Widgets/ScreenMain.vala',
    'src/Widgets/ScreenDockerContainer.vala',

    'src/Widgets/Screens/Main/FilterBar.vala',
    'src/Widgets/Screens/Main/ContainersGrid.vala',
    'src/Widgets/Screens/Main/ContainerCard.vala',

    'src/Widgets/Screens/DockerContainer/TopBar.vala',
    'src/Widgets/Screens/DockerContainer/SideBar.vala',
    'src/Widgets/Screens/DockerContainer/SideBarItem.vala',
    'src/Widgets/Screens/DockerContainer/SideBarSeparator.vala',
    'src/Widgets/Screens/DockerContainer/Log.vala',
    'src/Widgets/Screens/DockerContainer/LogOutput.vala',

    'src/Docker/Client.vala',
    'src/Docker/Command.vala',
    'src/Docker/ContainerLogWatcher.vala',
    
    dependencies: [
        dependency('gio-2.0'),
        dependency('gtk+-3.0'),
        dependency('gee-0.8'),        
        dependency('gdk-pixbuf-2.0'),
        dependency('json-glib-1.0'),
        dependency('granite'),
    ],
    
    install: true
)

meson.add_install_script('meson/post_install.py')
subdir('po')