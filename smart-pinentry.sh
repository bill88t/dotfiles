#!/bin/bash

FORCE_FILE="/tmp/force_pinentry.$UID.curses"

if [[ -f "$FORCE_FILE" || -z "$DISPLAY" || ! -x /usr/bin/pinentry-qt ]]; then
    exec /usr/bin/pinentry-curses "$@"
else
    exec /usr/bin/pinentry-qt "$@"
fi
