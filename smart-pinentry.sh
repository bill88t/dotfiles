#!/bin/bash

FORCE_FILE="/tmp/force_pinentry.$UID.curses"

if [[ -f "$FORCE_FILE" ]]; then
    exec /usr/bin/pinentry-curses "$@"
elif [[ -n "$DISPLAY" ]]; then
    exec /usr/bin/pinentry-qt "$@"
else
    exec /usr/bin/pinentry-curses "$@"
fi
