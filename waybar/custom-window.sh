#!/bin/bash

# Query focused window info from niri
output=$(/usr/bin/niri msg focused-window 2>/dev/null)

# Extract Title and App ID
title=$(echo "$output" | grep 'Title:' | sed -E 's/.*"([^"]+)".*/\1/')
appid=$(echo "$output" | grep 'App ID:' | sed -E 's/.*"([^"]+)".*/\1/')

# If both exist, print "Title | App"
if [[ -n "$title" && -n "$appid" ]]; then
    echo "$title | $appid"
else
    echo "No window"
fi
