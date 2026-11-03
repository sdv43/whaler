from whaler_ui import wait_for


def test_info_dialog_shows_ports(containers, launch):
    name = containers.run("web", image="nginx:alpine", ports=["127.0.0.1::80"])
    host_port = containers.host_port(name, "80/tcp")
    app = launch()

    app.container_menu(name, "Info")

    dialog = app.wait_dialog()
    labels = wait_for(lambda: (labels := dialog.labels()) and f"/{name}" in labels and labels, "container info")
    assert "nginx:alpine" in labels
    assert "running" in labels
    assert f"{host_port} -> 80/tcp" in labels

    dialog.wait("button", "Close").click()
    app.wait_no_dialog()


def test_settings_check_connection(containers, launch):
    containers.sleeper("box")
    app = launch()

    dialog = app.open_settings()
    entry = dialog.wait("text")
    check = dialog.wait("button", "Check connection")

    check.click()
    labels = wait_for(lambda: (labels := dialog.labels()) and "Success" in labels and labels, "a successful check")
    assert any(label.startswith("Docker v") for label in labels)

    entry.set_text("/run/whaler-ui-test-missing.sock")
    check.click()
    labels = wait_for(lambda: (labels := dialog.labels()) and "Error" in labels and labels, "a failed check")
    assert any("No such file or directory" in label for label in labels)

    dialog.wait("button", "Close").click()
    app.wait_no_dialog()
