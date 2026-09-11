#!/usr/bin/env bash
# startup.sh — sequential i3 startup.
#
# Replaces the parallel `exec` race: instead of i3 firing the display layout,
# workspace-layout appends, and app launches all at once (unpredictable order),
# this script:
#   1. waits for the display layout (applied by `monitor-layout.sh auto`, which
#      runs separately via `exec_always`) to actually settle,
#   2. appends the saved workspace layouts (1, 3, 5),
#   3. launches the apps.
#
# Login only (plain `exec` in i3 config) — reloads (`i3-msg reload`) re-run
# exec_always, not exec, so this never re-appends layouts or re-launches apps.

LOG="${STARTUP_LOG:-/tmp/i3-startup.log}"
TIMEOUT="${STARTUP_TIMEOUT:-30}"          # seconds, then fail-open
POLL_INTERVAL="${STARTUP_POLL:-0.5}"      # settle check cadence
NO_APPS="${STARTUP_NO_APPS:-0}"

log() { echo "$(date '+%F %T') startup: $*" >> "$LOG"; }

wait_for_layout() {
    local expected active ticks=0
    # Expected # of active outputs for whatever `auto` will apply:
    # both externals docked -> multi (HDMI + DP, eDP off) = 2 outputs,
    # otherwise -> single (eDP only) = 1 output.
    if xrandr --query 2>/dev/null | grep -q "^HDMI-1-0 connected" &&
       xrandr --query 2>/dev/null | grep -q "^DP-1-0 connected"; then
        expected=2
    else
        expected=1
    fi
    log "waiting for layout to settle (expect $expected active output(s))"
    while ((ticks < TIMEOUT)); do
        active=$(xrandr --query 2>/dev/null | grep -cE '^[a-zA-Z0-9-]+ connected .*[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
        if ((active == expected)); then
            log "layout settled (active=$active)"
            return 0
        fi
        sleep "$POLL_INTERVAL"
        ((ticks++))
    done
    log "WARN layout did not settle (expected=$expected got=$active); continuing"
    return 1
}

log_display_diagnostics() {
    local active monitors plymouth_state plymouth_result
    active=$(xrandr --query 2>/dev/null | grep -cE '^[a-zA-Z0-9-]+ connected .*[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
    monitors=$(xrandr --listmonitors 2>/dev/null | tr '\n' ' ')
    plymouth_state=$(systemctl show plymouth-quit.service -p ActiveState --value 2>/dev/null || true)
    plymouth_result=$(systemctl show plymouth-quit.service -p Result --value 2>/dev/null || true)
    log "boot diagnostics: active_outputs=$active; monitors=${monitors:-unavailable}; plymouth_quit=${plymouth_state:-unknown}/${plymouth_result:-unknown}"
}

append_layouts() {
    local base="$HOME/.config/i3/layouts"
    log "appending workspace layouts"
    i3-msg "workspace 1; append_layout $base/workspace-1.json" >/dev/null
    i3-msg "workspace 3; append_layout $base/workspace-3.json" >/dev/null
    i3-msg "workspace 5; append_layout $base/workspace-5.json" >/dev/null
}

launch_apps() {
    ((NO_APPS)) && { log "app launch skipped (STARTUP_NO_APPS=1)"; return; }
    log "launching apps"
    # Subsell: spawn every app detached, then exit immediately.
    (
        spotify &
        env WINIT_X11_SCALE_FACTOR=1 alacritty &
        env WINIT_X11_SCALE_FACTOR=1 alacritty &
        env WINIT_X11_SCALE_FACTOR=1 alacritty &
        env WINIT_X11_SCALE_FACTOR=1 alacritty &
        brave &
        notion-app --ignore-gpu-blocklist --disable-features=UseOzonePlatform \
            --enable-features=VaapiVideoDecoder --use-gl=desktop \
            --enable-gpu-rasterization --enable-zero-copy &
        discord --ignore-gpu-blocklist --disable-features=UseOzonePlatform \
            --enable-features=VaapiVideoDecoder --use-gl=desktop \
            --enable-gpu-rasterization --enable-zero-copy &
    ) 2>/dev/null || true
}

wait_for_layout
log_display_diagnostics
append_layouts
launch_apps
log "done"
