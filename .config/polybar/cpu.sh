#!/usr/bin/env bash

read_cpu() {
    awk '/^cpu / { print $2 + $3 + $4 + $5 + $6 + $7 + $8, $5 + $6 }' /proc/stat
}

read total_before idle_before < <(read_cpu)
sleep 0.1
read total_after idle_after < <(read_cpu)

total_delta=$((total_after - total_before))
idle_delta=$((idle_after - idle_before))
if [ "$total_delta" -gt 0 ]; then
    cpu=$((100 * (total_delta - idle_delta) / total_delta))
else
    cpu=0
fi

temp_path=
for zone in /sys/class/thermal/thermal_zone*/; do
    if [ -r "${zone}type" ] && [ "$(<"${zone}type")" = "x86_pkg_temp" ]; then
        temp_path="${zone}temp"
        break
    fi
done

meter=$(awk -v value="$cpu" 'BEGIN { count = int(value / 20 + 0.5); if (count < 1) count = 1; if (count > 5) count = 5; for (i = 1; i <= 5; i++) printf "%s", i <= count ? "█" : "░" }')

if [ -r "$temp_path" ]; then
    temp=$(awk '{ printf "%.0f", $1 / 1000 }' "$temp_path")
    printf '%s %s°C\n' "$meter" "$temp"
else
    printf '%s\n' "$meter"
fi
