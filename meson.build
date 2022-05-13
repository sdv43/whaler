project(
    'com.github.sdv43.whaler', 'vala', 'c',
    meson_version : '>= 0.49',
    version: '1.1.0'
)

#
i18n = import('i18n')
vapi_dir = meson.current_source_dir() / 'vapi'

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

#
subdir('po')
subdir('data')
subdir('src')

#
executable(
    meson.project_name(),
    gresource,
    constants,
    sources,
    dependencies: [
        dependency('gio-2.0'),
        dependency('gtk+-3.0'),
        dependency('gee-0.8'),        
        dependency('gdk-pixbuf-2.0'),
        dependency('json-glib-1.0'),
        dependency('granite'),
        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('vala').find_library('libcurl', dirs: vapi_dir),
        meson.get_compiler('c').find_library('libcurl', dirs: vapi_dir),
    ],
    install: true
)

meson.add_install_script('meson/post_install.py')
