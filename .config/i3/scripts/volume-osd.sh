#!/usr/bin/env bash
#
# volume-osd.sh — XOB overlay volume bar for the default sink (exec_always).
#
# Pipes pactl subscribe events (any volume/mute change from keys, apps or
# popups) into xob: prints "N" on change, "N!" when muted (xob's alternate
# color), and flashes once on default-sink switches (dock audio appearing).
# Silent at startup — only changes flash the bar.
#
# xob positions against the combined screen surface while the primary moves
# between single/multi/all layouts, so bar geometry is generated per spawn
# into a config file; monitor-layout.sh restarts us on layout changes.
#
# One instance: pidfile + setsid process group (reload replaces the whole
# watcher|pactl|xob tree). One-shot state for testing: volume-osd.sh state
#
# stdout is the value stream into xob; diagnostics go to STARTUP_LOG.

LOG="${STARTUP_LOG:-$HOME/.config/log/i3-startup.log}"
log() {
    printf '%s volume-osd: %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}
mkdir -p "$(dirname "$LOG")"

# value|sink on stdout ("42!", "42|alsa_output..."); fails when pactl is down
state() {
    local sink vol
    sink=$(pactl get-default-sink 2>/dev/null) || return 1
    [ -n "$sink" ] || return 1
    vol=$(pactl get-sink-volume "$sink" 2>/dev/null | grep -oE '[0-9]+ ?%' | head -1 | tr -d ' %')
    [ -n "$vol" ] || return 1
    if pactl get-sink-mute "$sink" 2>/dev/null | grep -q yes; then
        printf '%s!|%s\n' "$vol" "$sink"
    else
        printf '%s|%s\n' "$vol" "$sink"
    fi
}

if [ "${1:-}" = state ]; then
    s=$(state) || exit 1
    printf '%s\n' "${s%%|*}"
    exit 0
fi

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pidfile="$runtime_dir/volume-osd.pid"

if [ -z "${VOLUME_OSD_LEADER:-}" ]; then
    # First pass: reap the previous instance's whole process group (watcher,
    # pactl subscribe and xob), then re-exec as session leader so that $$ is
    # our killable process-group id.
    if [ -r "$pidfile" ]; then
        read -r oldpid < "$pidfile"
        if [ -n "$oldpid" ]; then
            kill -- -"$oldpid" 2>/dev/null || kill "$oldpid" 2>/dev/null
        fi
    fi
    VOLUME_OSD_LEADER=1 exec setsid "$0" "$@"
fi
printf '%s\n' "$$" > "$pidfile"

# Bar geometry — absolute pixels (verified: xob's relative=0 offsets anchor the
# box's left/top edge). 64px bottom gap matches popup_bottom (polybar ~48px).
bar_len=320
bar_thick=16
bar_gap=64

read -r pw ph px py <<<"$(xrandr --query 2>/dev/null | awk '/ connected primary / {
    if (match($0, /([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+)/, m))
        print m[1], m[2], m[3], m[4]
}')"
if [ -z "${pw:-}" ]; then
    log "no primary monitor parsed; falling back to 1920x1080+0+0"
    pw=1920 ph=1080 px=0 py=0
fi

bar_x=$((px + pw / 2 - bar_len / 2))
bar_y=$((py + ph - bar_gap - bar_thick))

cfg="$runtime_dir/xob-volume.cfg"
cat > "$cfg" <<EOF
volume = {
    x = {relative = 0; offset = $bar_x;};
    y = {relative = 0; offset = $bar_y;};
    length = {relative = 0; offset = $bar_len;};
    thickness = $bar_thick;
    outline = 0;
    border = 0;
    padding = 0;
    orientation = "horizontal";
    overflow = "proportional";
    color = {
        normal = {
            fg = "#F0C674";
            bg = "#26233aE6";
            border = "#26233aE6";
        };
        alt = {
            fg = "#707880";
            bg = "#26233aE6";
            border = "#26233aE6";
        };
        overflow = {
            fg = "#A54242";
            bg = "#26233aE6";
            border = "#26233aE6";
        };
        altoverflow = {
            fg = "#A54242";
            bg = "#26233aE6";
            border = "#26233aE6";
        };
    };
};
EOF

log "spawned: bar ${bar_len}x${bar_thick} at ${bar_x},${bar_y} (primary ${pw}x${ph}+${px}+${py})"

# Seed the change detector so startup stays silent; the sink name is part of
# the key so a default-sink switch flashes the new sink's level once.
last_state=$(state 2>/dev/null) || last_state=""

pactl subscribe 2>/dev/null | while read -r event; do
    case $event in
        *" on sink "*|*" on server "*|*" on card "*)
            cur=$(state) || continue
            [ "$cur" = "$last_state" ] && continue
            last_state=$cur
            printf '%s\n' "${cur%%|*}"
            ;;
    esac
done | xob -c "$cfg" -s volume -t 1500
