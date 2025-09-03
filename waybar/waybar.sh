#!/bin/sh
set -eu

LOCKFILE="/tmp/waybar.$UID.lock"
exec 9>"$LOCKFILE"

if ! flock -n 9; then
    echo "Waybar watchdog already running."
    exit 1
fi

child_pid=

cleanup() {
    [ -n "${child_pid:-}" ] && kill "$child_pid" 2>/dev/null || true
    rm -f "$LOCKFILE"
}
trap 'cleanup; exit 0' INT TERM EXIT

while :; do
    waybar -c ~/git/dotfiles/waybar/config.jsonc -s ~/git/dotfiles/waybar/style.css >/dev/null 2>&1 &
    child_pid=$!
    wait "$child_pid" || true
    child_pid=
done
