#!/bin/bash

niri msg keyboard-layouts |
awk '
/^\s*\*/ {
    if ($0 ~ /English/) print "EN"
    else if ($0 ~ /Greek/) print "GR"
}
'
