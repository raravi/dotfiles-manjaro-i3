#!/usr/bin/env bash

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low "Screen Mode" "$1"
    fi
}

hdmi_connected() {
    xrandr --query | grep -q "^HDMI-1-0 connected"
}

dp_connected() {
    xrandr --query | grep -q "^DP-1-0 connected"
}

# Multi layout is only valid when both external displays are docked
both_externals_present() {
    hdmi_connected && dp_connected
}

# Multi layout is currently applied when both external outputs carry a mode + position
# (note: an active output may say "connected primary 3440x1440+0+960", hence the loose match)
is_multi_active() {
    local active
    active=$(xrandr --query | grep -cE '^(HDMI-1-0|DP-1-0) connected .*[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
    ((active >= 2))
}

apply_single() {
    # Only touch outputs that exist, or xrandr fails on the missing one
    local -a cmd=(xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rate 144 --scale 1.00)
    hdmi_connected && cmd+=(--output HDMI-1-0 --off)
    dp_connected && cmd+=(--output DP-1-0 --off)
    "${cmd[@]}"
    notify "Single monitor (laptop)"
}

apply_multi() {
    if ! both_externals_present; then
        notify "Multi-monitor requires both external monitors to be detected!"
        exit 1
    fi

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

case "${1:-auto}" in
    single)
        apply_single
        ;;
    multi)
        apply_multi
        ;;
    auto)
        if both_externals_present; then
            apply_multi
        else
            apply_single
        fi
        ;;
    toggle)
        if is_multi_active; then
            apply_single
        else
            if both_externals_present; then
                apply_multi
            else
                notify "Multi-monitor requires both external monitors to be detected!"
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

