#!/bin/bash
log=$(journalctl -n 1 -u govctl --no-pager 2>/dev/null)

if [[ $log =~ Applied\ governor\ \"([^\"]+)\" ]]; then
    gov="${BASH_REMATCH[1]}"
    echo "${gov^}"
else
    echo "Unknown"
fi
