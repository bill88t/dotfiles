#!/usr/bin/env bash
set -euo pipefail

SRC="$HOME/.local/share/waydroid/data/media/0"
DST="$HOME/Waydroid"

if [[ ! -d "$HOME/.local/share/waydroid/data/media" ]]; then
    echo "Error: Source directory not found: $SRC" >&2
    exit 1
fi

if mountpoint -q "$DST" >/dev/null 2>&1; then
    echo "Already mounted: $DST"
    exit 0
else
    # Could be not mounted OR mountpoint choked on a dead mount
    if findmnt -rn "$DST" >/dev/null 2>&1; then
        echo "Mount is invalid, remounting.."
        sudo umount "$DST" 2>/dev/null || umount -l "$DST"
    fi
fi


if [[ ! -d "$DST" ]]; then
    mkdir -p "$DST"
fi

sudo bindfs -u $UID -g $UID "$SRC" "$DST"

echo "Mounted $SRC → $DST with host UID $UID mapped"
