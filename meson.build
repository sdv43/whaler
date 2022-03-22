project(
    'com.github.sdv43.whaler', 'vala', 'c',
    meson_version : '>= 0.49',
    version: '1.0.0'
)

# 
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

#
subdir('po')
subdir('data')
subdir('src')

#
executable(
    meson.project_name(),
    gresource,
    sources,
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
