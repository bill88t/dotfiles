#!/bin/bash

log=$(journalctl -n 1 -u govctl --no-pager 2>/dev/null)

if [[ $log =~ Applied\ governor\ \"([^\"]+)\" ]]; then
    gov="${BASH_REMATCH[1]}"

    case "$gov" in
        performance)
            echo "P"
            ;;
        conservative)
            echo "C"
            ;;
        powersave)
            echo "B"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
else
    echo "U"
fi
