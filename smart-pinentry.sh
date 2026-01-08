#!/bin/bash

if [[ -n "$DISPLAY" ]]; then
    exec /usr/bin/pinentry-qt "$@"
    # exec /usr/bin/pinentry-curses "$@"
else
    exec /usr/bin/pinentry-curses "$@"
fi
