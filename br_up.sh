#!/bin/bash

current=$(brightnessctl g)

if [ "$current" -eq 0 ]; then
    brightnessctl s 1
elif [ "$current" -eq 1 ]; then
    brightnessctl s 5%
else
    brightnessctl s 5%+
fi
