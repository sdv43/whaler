from whaler_ui import display_name


def test_lists_containers_and_compose_projects(containers, launch):
    running = containers.sleeper("running")
    stopped = containers.sleeper("stopped", start=False)
    project = containers.compose("stack", """
        web:
          image: nginx:alpine
        worker:
          image: alpine:3
          command: sleep 3600
          init: true
    """)

    app = launch()

    assert app.card(running).status == "Running"
    assert app.card(project).status == "Running"

    # stopped containers show the image instead of the status
    stopped_card = app.card(stopped)
    assert stopped_card.status is None
    assert "alpine:3" in stopped_card.labels()

    assert sorted(app.card_names()) == sorted(display_name(name) for name in (running, stopped, project))

    assert app.card(running).main_button.name == "Stop"
    assert stopped_card.main_button.name == "Start"


def test_search_is_case_insensitive(containers, launch):
    web = containers.sleeper("web")
    db = containers.sleeper("db")
    app = launch()

    app.search(containers.prefix.upper())
    app.card(web)
    app.card(db)

    app.search(f"{containers.prefix}-WE")
    app.wait_card_gone(db)
    assert app.card_names() == [display_name(web)]


def test_sorting(containers, launch):
    a_stopped = containers.sleeper("a-stopped", start=False)
    b_running = containers.sleeper("b-running")
    project = containers.compose("c-stack", """
        app:
          image: alpine:3
          command: sleep 3600
          init: true
    """)
    app = launch()

    app.sort_by("Name")
    assert app.card_names() == [display_name(n) for n in (a_stopped, b_running, project)]

    # compose projects go first
    app.sort_by("Type")
    assert app.card_names() == [display_name(n) for n in (project, a_stopped, b_running)]

    # running containers go first
    app.sort_by("Status")
    names = app.card_names()
    assert names[-1] == display_name(a_stopped)
    assert set(names[:2]) == {display_name(b_running), display_name(project)}


def test_refresh_shows_new_containers(containers, launch):
    existing = containers.sleeper("existing")
    app = launch()
    app.card(existing)

    created = containers.sleeper("created")
    app.refresh()

    assert app.card(created).status == "Running"
