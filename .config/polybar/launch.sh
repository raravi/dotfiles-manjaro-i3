#!/usr/bin/env bash

mode=${1:-pills}
case "$mode" in
    pills) config="$HOME/.config/polybar/config.ini" ;;
    original) config="$HOME/.config/polybar/config-original.ini" ;;
    *) printf 'Usage: %s [pills|original]\n' "$0" >&2; exit 2 ;;
esac

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use 
# polybar-msg cmd quit
# Otherwise you can use the nuclear option:
killall -q polybar

# Launch bar
# echo "---" | tee -a /tmp/polybar.log
# polybar bar 2>&1 | tee -a /tmp/polybar.log & disown
# polybar bar2 2>&1 | tee -a /tmp/polybar2.log & disown

# The bar with the system tray (`bar`) runs on the primary monitor;
# tray-less `bar-secondary` runs on the others (only one bar can own the tray).
monitors=$(polybar --list-monitors)

primary=$(echo "$monitors" | grep -oE '^[^:]+: .*\(primary\)' | cut -d: -f1)
[ -z "$primary" ] && primary=$(echo "$monitors" | cut -d: -f1 | head -1)

for monitor in $(echo "$monitors" | cut -d: -f1); do
    if [ "$monitor" = "$primary" ]; then
        bar=bar
    else
        bar=bar-secondary
    fi
    echo "Starting $bar on monitor '$monitor'" | tee -a /tmp/polybar.log
    MONITOR="$monitor" polybar --config="$config" "$bar" 2>&1 | tee -a /tmp/polybar.log & disown
done

echo "Bars launched..."
