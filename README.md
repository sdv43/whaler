# Whaler 

<div align="center">
 <img src="data/images/logo/64.png" alt="Whaler"/>
</div>

![List of Docker containers](data/images/screenshots/screenshot-1.png?raw=true)

## Description

Whaler provides basic functionality for managing Docker containers. The app can start and stop both standalone containers and docker-compose applications. Also, it supports container logs viewing.

The solution is perfect for those who are looking for a simple tool to perform some basic actions. For the app to run correctly, make sure that Docker is installed on your system.

## Installation

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.sdv43.whaler)

<a href="https://flathub.org/apps/details/com.github.sdv43.whaler" target="_blank"><img src="https://flathub.org/assets/badges/flathub-badge-i-en.svg" width="160px" alt="Get it from Flathub!"></a>

## Usage with Podman

1. Open Whaler
2. An error-screen should appear
3. Click on the "Open Settings" button
4. Replace the `API socket path` with something like `/run/user/1000/podman/podman.sock`

## Building

You'll need the following dependencies:
* gio-2.0
* gtk+-3.0
* gee-0.8
* gdk-pixbuf-2.0
* json-glib-1.0
* libcurl
* granite
* posix
* meson
* valac

### Meson

In project root:
```
meson build --prefix=/usr
cd build
ninja

sudo ninja install
com.github.sdv43.whaler
```

### Flatpak

In project root:
```
flatpak-builder --force-clean --install --user build com.github.sdv43.whaler.yml
flatpak run com.github.sdv43.whaler
```

## UI tests

The UI tests in `tests/ui` start the app on a virtual display and drive it through the accessibility
tree (AT-SPI), like a user: they start, stop and remove containers and check the results in Docker.
The tests create their own containers (named `wuit-*`) and remove them afterwards, and don't change
your Whaler settings.

You'll need Docker with the compose plugin and:
* xvfb
* dbus
* at-spi2-core
* gir1.2-atspi-2.0
* python3-gi
* python3-pytest
* imagemagick (optional, for screenshots of failed tests)

In project root, after building with Meson into `build`:
```
tests/ui/run.sh
```

Extra arguments are passed to pytest, e.g. `tests/ui/run.sh -k logs -x`. Screenshots and logs of
failed tests are saved to `tests/ui/artifacts`.
