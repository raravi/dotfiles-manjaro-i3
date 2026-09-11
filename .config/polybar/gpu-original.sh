#!/usr/bin/env bash

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | awk -F', ' '{ printf "%s%% (%s°C)\n", $1, $2 }'
else
    printf 'N/A\n'
fi
