# Whaler 

![List of Docker containers](data/images/screenshots/screenshot-1.png?raw=true)

## Description

Whaler provides basic functionality for managing Docker containers. The app can start and stop both standalone containers and docker-compose applications. Also, it supports container logs viewing.

The solution is perfect for those who are looking for a simple tool to perform some basic actions. For the app to run correctly, make sure that Docker and docker-compose are installed on your system.
 

## Building and Installation

You'll need the following dependencies:
* libglib2.0-dev
* gtk
* libgee-0.8-dev
* libgdk-pixbuf-2.0-dev
* libjson-glib-dev
* libgranite-dev
* meson
* valac

### Building

```
meson build --prefix=/usr
cd build
ninja
```

### Installation

```
sudo ninja install
com.github.sdv43.whaler
```