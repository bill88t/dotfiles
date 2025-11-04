#!/bin/bash

echo "Launching shitass app.."
MATLAB_PATH="/home/bill88t/Matlab/R2024b/bin"

cd "$MATLAB_PATH"
./matlab -webui -nosoftwareopengl "$@"

echo "MATLAB exited. Cleaning up lingering MathWorks processes..."
pkill -if "mathworks" 2>/dev/null
