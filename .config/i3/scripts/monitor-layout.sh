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

# An output is active (has a mode + position) when its line carries geometry.
# Note an active output may read "connected primary 3440x1440+0+960", hence the loose match.
output_active() {
    xrandr --query | grep -qE "^$1 connected .*[0-9]+x[0-9]+\+[0-9]+\+[0-9]+"
}

externals_active() {
    xrandr --query | grep -cE '^(HDMI-1-0|DP-1-0) connected .*[0-9]+x[0-9]+\+[0-9]+\+[0-9]+'
}

# Docked layout (laptop off, both externals on)
is_multi_active() {
    local n
    n=$(externals_active)
    [[ $n -ge 2 ]] && ! output_active eDP-1
}

# All-screens layout (laptop + both externals on)
is_all_active() {
    local n
    n=$(externals_active)
    [[ $n -ge 2 ]] && output_active eDP-1
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

apply_all() {
    if ! both_externals_present; then
        notify "All-screens mode requires both external monitors to be detected!"
        exit 1
    fi

    xrandr --output eDP-1 --mode 1920x1080 --pos 0x1320 --rate 144.00 --scale 1.00 \
           --output HDMI-1-0 --primary --mode 3440x1440 --pos 1920x960 --scale 1.00 \
           --output DP-1-0 --mode 2560x1440 --pos 5360x0 --scale 1.00 --rotate right
    notify "All monitors (laptop + HDMI ultrawide + DP portrait)"
}

restart_xborders() {
    "$HOME/.config/xborder/launch.sh"
}

restart_polybar() {
    "$HOME/.config/polybar/launch.sh"
}

rerun_keys_remaps() {
    "$HOME/.config/i3/keys-remap.sh"
}

case "${1:-auto}" in
    single)
        apply_single
        ;;
    multi)
        apply_multi
        ;;
    all)
        apply_all
        ;;
    auto)
        if both_externals_present; then
            apply_multi
        else
            apply_single
        fi
        ;;
    cycle)
        if is_all_active; then
            apply_single
        elif is_multi_active; then
            apply_all
        elif both_externals_present; then
            apply_multi
        else
            notify "Multi/All-screens modes require both external monitors to be detected!"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $(basename "$0") {auto|single|multi|all|cycle}"
        exit 2
        ;;
esac

# Which of the three layouts is active right now (used by the settle wait below)
expected_outputs() {
    if is_all_active; then
        echo 3
    elif is_multi_active;then
        echo 2
    else
        echo 1
    fi
}

# Replace the brittle fixed sleep with a real settle wait: poll until the active-output
# count matches the layout just applied, then restart polybar/xborders. Fail-open: if it
# never converges (timeout), proceed anyway so the UI still comes up.
wait_for_layout() {
    local expected want ticks=0 delay="${SETTLE_POLL:-0.3}" max="${SETTLE_TIMEOUT:-15}"
    expected=$(expected_outputs)
    sleep 1.5
    while ((ticks < max)); do
        want=$(xrandr --query 2>/dev/null | grep -cE '^[a-zA-Z0-9-]+ connected .*[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
        [[ $want =~ ^[0-9]+$ ]] && ((want == expected)) && return 0
        sleep "$delay"
        ((ticks++))
    done
    >&2 echo "layout: active-output count did not settle (want=$want expected=$expected); continuing"
}

wait_for_layout
restart_polybar
restart_xborders
rerun_keys_remaps

# Regenerate nitrogen per-screen wallpapers from the new layout
"$HOME/.config/i3/scripts/wallpaper-apply.sh"

