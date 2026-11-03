from whaler_ui import display_name, wait_for


def test_window_state_is_saved_and_restored(containers, launch, settings):
    first = containers.sleeper("first")
    second = containers.sleeper("second")

    app = launch(window_size=(900, 640), window_position=(30, 20))
    assert app.search_entry.text == containers.prefix
    assert app.sorting() == "Status"

    app.search(second)
    app.wait_card_gone(first)
    app.sort_by("Name")
    app.close()
    wait_for(lambda: app.process.poll() is not None, "Whaler to exit")

    saved = settings.read()
    assert saved["main-screen-search-term"] == second
    assert saved["main-screen-sorting"] == 1
    assert saved["window-size"] == (900, 640)
    assert saved["window-position"] == (30, 20)

    app = launch()
    assert app.search_entry.text == second
    assert app.sorting() == "Name"
    assert app.card_names() == [display_name(second)]
