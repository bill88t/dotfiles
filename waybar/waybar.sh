#!/bin/sh
set -eu

LOCKFILE="/tmp/waybar.$UID.lock"
PIDFILE="/tmp/waybar.$UID.pid"

is_alive() {
    [ -n "$1" ] && kill -0 "$1" 2>/dev/null
}

if [ -f "$LOCKFILE" ]; then
    existing_pid=$(cat "$PIDFILE" 2>/dev/null || echo "")
    if is_alive "$existing_pid"; then
        exit 1
    else
        rm -f "$LOCKFILE" "$PIDFILE"
    fi
fi

exec 9>"$LOCKFILE"
if ! flock -n 9; then
    exit 1
fi

child_pid=
fail_times=()
start_time=$(date +%s)

cleanup() {
    [ -n "${child_pid:-}" ] && kill "$child_pid" 2>/dev/null || true
    rm -f "$LOCKFILE" "$PIDFILE"
}
trap 'cleanup; exit 0' INT TERM EXIT

HOSTNAME=$(hostname)
BASE_DIR=~/git/dotfiles/waybar

while :; do
    # --- dynamically pick config and style each restart ---
    CONFIG="$BASE_DIR/config.jsonc"
    STYLE="$BASE_DIR/style.css"

    [ -f "$BASE_DIR/config-${HOSTNAME}.jsonc" ] && CONFIG="$BASE_DIR/config-${HOSTNAME}.jsonc"
    [ -f "$BASE_DIR/style-${HOSTNAME}.css" ] && STYLE="$BASE_DIR/style-${HOSTNAME}.css"

    waybar -c "$CONFIG" -s "$STYLE" >/dev/null 2>&1 &
    child_pid=$!
    echo "$child_pid" > "$PIDFILE"

    wait "$child_pid" || true
    child_pid=

    now=$(date +%s)
    fail_times+=("$now")

    tmp=()
    for t in "${fail_times[@]}"; do
        [ $((now - t)) -le 4 ] && tmp+=("$t")
    done
    fail_times=("${tmp[@]}")

    if [ "${#fail_times[@]}" -ge 3 ] && [ $((now - start_time)) -gt 10 ]; then
        exit 1
    fi
done
