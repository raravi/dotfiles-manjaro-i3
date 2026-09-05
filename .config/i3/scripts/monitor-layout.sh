#!/usr/bin/env bash

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low "monitor-layout" "$1"
    fi
}

apply_single() {
    xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rate 144 --scale 1.00 \
           --output HDMI-1-0 --off \
           --output DP-1-0 --off
    notify "Single monitor (laptop screen)"
}

apply_multi() {
    xrandr --output eDP-1 --off \
           --output HDMI-1-0 --primary --mode 3440x1440 --pos 0x960 --scale 1.00 \
           --output DP-1-0 --mode 2560x1440 --pos 3440x0 --scale 1.00 --rotate right
    notify "Multi-monitor (HDMI ultrawide + DP portrait)"
}

restart_xborders() {
    "$HOME/.config/xborder/launch.sh"
}

restart_polybar() {
    "$HOME/.config/polybar/launch.sh"
}

# HDMI is active when its line carries a current mode + position (e.g. "3440x1440+0+960");
# when off it only shows bare "connected".
is_multi_active() {
    xrandr --query | grep "^HDMI-1-0 connected" | grep -qE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+'
}

is_hdmi_present() {
    xrandr --query | grep -q "^HDMI-1-0 connected"
}

case "${1:-auto}" in
    single)
        apply_single
        ;;
    multi)
        apply_multi
        ;;
    auto)
        if is_hdmi_present; then
            apply_multi
        else
            apply_single
        fi
        ;;
    toggle)
        if is_multi_active; then
            apply_single
        else
            if is_hdmi_present; then
                apply_multi
            else
                notify "No external display detected"
                exit 1
            fi
        fi
        ;;
    *)
        echo "Usage: $(basename "$0") {auto|single|multi|toggle}"
        exit 2
        ;;
esac

sleep 0.5
restart_polybar
restart_xborders