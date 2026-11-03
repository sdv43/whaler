from whaler_ui import display_name, wait_for


def test_logs_are_streamed(containers, launch):
    name = containers.logger("logger")
    app = launch()
    app.open_card(name)

    first = app.wait_log(lambda lines: lines, "the first log lines")
    # new lines keep coming while the screen is open
    app.wait_log(lambda lines: len(lines) >= len(first) + 3, "new log lines")

    app_lines = app.log_lines()
    docker_lines = containers.logs(name)
    assert app_lines == docker_lines[:len(app_lines)]


def test_logs_continue_after_restart_without_duplicates(containers, launch):
    name = containers.logger("logger")
    app = launch()
    app.open_card(name)
    app.wait_log(lambda lines: len(lines) >= 2, "log lines before the restart")

    app.screen_menu("Restart")

    # every start of the logger prints lines with a new run id
    first_run = app.log_lines()[0].split()[1]
    lines = app.wait_log(
        lambda lines: sum(1 for line in lines if line.split()[1] != first_run) >= 2,
        "log lines after the restart",
    )

    assert len(lines) == len(set(lines)), "the log has duplicated lines"
    assert set(lines) <= set(containers.logs(name))


def test_tty_container_logs(containers, launch):
    name = containers.logger("tty", tty=True)
    app = launch()
    app.open_card(name)

    lines = app.wait_log(lambda lines: len(lines) >= 2, "log lines")

    # TTY output is not multiplexed: no stream headers or carriage returns in the text
    for line in lines:
        assert line.startswith("run "), f"unexpected log line {line!r}"
        assert line.isprintable(), f"unexpected characters in {line!r}"


def test_stop_and_start_on_container_screen(containers, launch):
    name = containers.logger("logger")
    app = launch()
    app.open_card(name)
    app.wait_log(lambda lines: lines, "log lines")

    app.screen_button("Stop").click()
    wait_for(lambda: containers.state(name) == "exited", "the container to stop")
    app.screen_button("Start")
    stopped_lines = app.log_lines()

    app.screen_button("Start").click()
    wait_for(lambda: containers.state(name) == "running", "the container to start")
    app.screen_button("Stop")
    # the log is kept and continues with the new run
    app.wait_log(lambda lines: len(lines) > len(stopped_lines) and lines[:len(stopped_lines)] == stopped_lines,
                 "log lines of the new run")

    app.back()
    app.wait_card_status(name, "Running")


def test_compose_project_screen(containers, launch):
    project = containers.compose("stack", """
        api:
          image: alpine:3
          command: sh -c 'while true; do echo api tick; sleep 1; done'
          init: true
        worker:
          image: alpine:3
          command: sh -c 'while true; do echo worker tick; sleep 1; done'
          init: true
    """)
    app = launch()
    app.open_card(project)

    # services are listed in the order of the Docker API
    side_bar = app.side_bar()
    assert side_bar[:2] == [display_name(project), "Services"]
    assert sorted(side_bar[2:]) == ["Api", "Worker"]

    # the project shows the logs of all services, prefixed with the service name
    app.wait_log(lambda lines: any(l.startswith("Api: ") for l in lines) and any(l.startswith("Worker: ") for l in lines),
                 "logs of both services")

    app.select_side_bar_item("worker")
    app.wait_log(lambda lines: lines and all(line == "worker tick" for line in lines), "logs of the worker service")

    app.screen_button("Stop").click()
    wait_for(lambda: containers.project_states(project)["worker"] == "exited", "the worker to stop")
    assert containers.project_states(project)["api"] == "running"
