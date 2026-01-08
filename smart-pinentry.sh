#!/bin/bash

if [[ -n "$DISPLAY" ]]; then
    exec /usr/bin/pinentry-qt "$@"
else
    exec /usr/bin/pinentry-curses "$@"
fi
