#!/usr/bin/env bash
set -euo pipefail

SRC="$HOME/.local/share/waydroid/data/media/0"
DST="$HOME/Waydroid"

if [[ ! -d "$HOME/.local/share/waydroid/data/media" ]]; then
    echo "Error: Source directory not found: $SRC" >&2
    exit 1
fi

if [[ ! -d "$DST" ]]; then
    mkdir -p "$DST"
fi

if mountpoint -q "$DST"; then
    echo "Already mounted: $DST"
    exit 0
fi

sudo bindfs -u $UID -g $UID "$SRC" "$DST"

echo "Mounted $SRC → $DST with host UID $UID mapped"
