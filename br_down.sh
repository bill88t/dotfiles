#!/bin/bash

current=$(brightnessctl g)
max=$(brightnessctl m)

# Calculate percentage (using integer math)
percent=$(( current * 100 / max ))

if [ "$percent" -gt 5 ]; then
    brightnessctl s 5%-
elif [[ "$percent" -le 5 && "$current" -gt 1 ]]; then
    brightnessctl s 1
elif [ "$current" -eq 1 ]; then
    brightnessctl s 0
fi
