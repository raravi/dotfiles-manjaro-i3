#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use 
# polybar-msg cmd quit
# Otherwise you can use the nuclear option:
killall -q polybar

# Launch bar
# echo "---" | tee -a /tmp/polybar.log
# polybar bar 2>&1 | tee -a /tmp/polybar.log & disown
# polybar bar2 2>&1 | tee -a /tmp/polybar2.log & disown

# for monitor in $(xrandr --query | grep " connected" | cut -d" " -f1); do
for monitor in $(polybar --list-monitors | cut -d":" -f1); do
    echo "Starting bar on monitor '$monitor'" | tee -a /tmp/polybar.log
    MONITOR="$monitor" polybar bar 2>&1 | tee -a /tmp/polybar.log & disown
done

echo "Bars launched..."
