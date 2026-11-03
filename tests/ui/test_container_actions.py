from whaler_ui import wait_for


def test_stop_and_start(containers, launch):
    name = containers.sleeper("box")
    app = launch()

    app.card(name).main_button.click()
    wait_for(lambda: containers.state(name) == "exited", "the container to stop")
    assert app.wait_card_status(name, None).main_button.name == "Start"

    app.card(name).main_button.click()
    wait_for(lambda: containers.state(name) == "running", "the container to start")
    assert app.wait_card_status(name, "Running").main_button.name == "Stop"


def test_pause_and_unpause(containers, launch):
    name = containers.sleeper("box")
    app = launch()

    app.container_menu(name, "Pause")
    wait_for(lambda: containers.state(name) == "paused", "the container to pause")
    card = app.wait_card_status(name, "Paused")
    assert card.main_button.name == "Unpause"

    card.main_button.click()
    wait_for(lambda: containers.state(name) == "running", "the container to unpause")
    app.wait_card_status(name, "Running")


def test_restart(containers, launch):
    name = containers.sleeper("box")
    started_at = containers.started_at(name)
    app = launch()

    app.container_menu(name, "Restart")

    wait_for(lambda: containers.started_at(name) != started_at, "the container to restart")
    assert containers.state(name) == "running"
    app.wait_card_status(name, "Running")


def test_remove_asks_for_confirmation(containers, launch):
    name = containers.sleeper("box", start=False)
    app = launch()

    app.container_menu(name, "Remove")
    dialog = app.wait_dialog()
    assert "Do you really want to remove container?" in dialog.labels()
    dialog.wait("button", "Cancel").click()
    app.wait_no_dialog()
    assert containers.state(name) == "created"
    assert app.card(name).main_button.sensitive

    app.container_menu(name, "Remove")
    app.wait_dialog().wait("button", "Yes, remove").click()

    app.wait_card_gone(name)
    assert containers.state(name) is None


def test_remove_running_container_shows_error(containers, launch):
    name = containers.sleeper("box")
    app = launch()

    app.container_menu(name, "Remove")
    app.wait_dialog().wait("button", "Yes, remove").click()

    # Docker refuses to remove a running container without force
    error = wait_for(lambda: (d := app.wait_dialog()) and "Container remove error" in d.labels() and d,
                     "the error dialog")
    assert "Conflict" in error.labels()
    error.wait("button", "Close").click()
    app.wait_no_dialog()

    assert containers.state(name) == "running"
    app.wait_card_status(name, "Running")


def test_stop_and_start_compose_project(containers, launch):
    project = containers.compose("stack", """
        web:
          image: nginx:alpine
        worker:
          image: alpine:3
          command: sleep 3600
          init: true
    """)
    app = launch()

    app.card(project).main_button.click()
    wait_for(lambda: set(containers.project_states(project).values()) == {"exited"}, "the project to stop")
    # a stopped project lists its services
    assert "Web, Worker" in app.wait_card_status(project, None).labels()

    app.card(project).main_button.click()
    wait_for(lambda: set(containers.project_states(project).values()) == {"running"}, "the project to start")
    app.wait_card_status(project, "Running")
