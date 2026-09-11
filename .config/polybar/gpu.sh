#!/usr/bin/env bash

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | awk -F', ' '{ value = $1; count = int(value / 20 + 0.5); if (count < 1) count = 1; if (count > 5) count = 5; for (i = 1; i <= 5; i++) printf "%s", i <= count ? "█" : "░"; printf " %s°C\n", $2 }'
else
    printf '░░░░░ N/A\n'
fi
