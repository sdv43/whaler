#!/bin/sh
# Runs the UI tests on a virtual X display inside a private D-Bus session,
# so they don't touch the desktop session. Extra arguments are passed to pytest.
#
#   tests/ui/run.sh
#   tests/ui/run.sh -k logs -x
#
# WHALER_BIN overrides the tested binary (default: build/com.github.sdv43.whaler).

set -eu

TESTS_DIR=$(cd "$(dirname "$0")" && pwd)
export WHALER_BIN="${WHALER_BIN:-$TESTS_DIR/../../build/com.github.sdv43.whaler}"

if [ ! -x "$WHALER_BIN" ]; then
    echo "Whaler binary not found at $WHALER_BIN, build it first: meson setup build && ninja -C build" >&2
    exit 1
fi

ARTIFACTS="$TESTS_DIR/artifacts"
rm -rf "$ARTIFACTS"
mkdir -p "$ARTIFACTS"

# Xvfb picks a free display number and writes it to the file
DISPLAY_FILE=$(mktemp)
Xvfb -displayfd 4 -screen 0 1280x800x24 -nolisten tcp 4>"$DISPLAY_FILE" 2>"$ARTIFACTS/xvfb.log" &
XVFB_PID=$!
trap 'kill $XVFB_PID 2>/dev/null; rm -f "$DISPLAY_FILE"' EXIT

for _ in $(seq 100); do
    [ -s "$DISPLAY_FILE" ] && break
    sleep 0.1
done
[ -s "$DISPLAY_FILE" ] || { echo "Xvfb did not start, see $ARTIFACTS/xvfb.log" >&2; exit 1; }
export DISPLAY=":$(cat "$DISPLAY_FILE")"

# DISPLAY is set before the D-Bus session starts, so the accessibility registry
# started inside the session can send synthesized clicks to the display.
# Output of the session's services goes to session.log, pytest keeps the terminal (fd 3 and 4).
status=0
dbus-run-session -- sh -c 'exec "$@" >&3 2>&4' sh "${PYTHON:-python3}" -m pytest "$TESTS_DIR" "$@" \
    3>&1 4>&2 >"$ARTIFACTS/session.log" 2>&1 || status=$?
exit $status
