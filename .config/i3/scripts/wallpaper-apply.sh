#!/usr/bin/env bash
# wallpaper-apply.sh — rebuild nitrogen's per-screen background config from the
# CURRENT monitor layout, then apply it.
#
# `xrandr --listmonitors` prints the Xinerama head order that nitrogen --restore
# assigns its [xin_N] entries to, so we regenerate bg-saved.cfg on the fly:
# for each listed monitor (index N, connector C) write
#     [xin_N] file = <wallpaper for C>
# from wallpapers.conf, then `nitrogen --restore`.
#
# Env overrides (mostly for testing):
#   XDG_CONFIG_HOME   where to find nitrogen/ (default: ~/.config)
#   DRY_RUN=1         print generated config instead of applying
#   WALLPAPER_MODE    nitrogen draw mode written to cfg (default 5)
#   WALLPAPER_BGCOLOR background color written to cfg (default #000000)

nitrogen_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nitrogen"
mapping="$nitrogen_dir/wallpapers.conf"
saved_cfg="$nitrogen_dir/bg-saved.cfg"
mode="${WALLPAPER_MODE:-5}"
bgcolor="${WALLPAPER_BGCOLOR:-#000000}"

if [[ ! -f "$mapping" ]]; then
    echo "wallpaper-apply: no mapping at $mapping; skipping" >&2
    exit 0
fi

# Load connector -> wallpaper mapping (KEY=value, '#' comments).
declare -A wall
while IFS='=' read -r key val; do
    key=${key//[[:space:]]/}
    [[ -z $key || $key == \#* ]] && continue
    wall[$key]=$val
done < "$mapping"

# Build the config from the current monitor list (skip the "Monitors: N" header).
tmp="$(mktemp)"
added=0
while read -r line; do
    [[ $line =~ ^[[:space:]]*([0-9]+): ]] || continue
    idx=${BASH_REMATCH[1]}
    conn=${line##* }                 # connector name is the last field
    if [[ -z ${wall[$conn]:-} ]]; then
        echo "wallpaper-apply: no wallpaper mapped for $conn (index $idx); skipping" >&2
        continue
    fi
    printf '[xin_%s]\nfile=%s\nmode=%s\nbgcolor=%s\n\n' "$idx" "${wall[$conn]}" "$mode" "$bgcolor" >> "$tmp"
    added=$((added + 1))
done < <(xrandr --listmonitors 2>/dev/null)

if [[ $added -eq 0 ]]; then
    echo "wallpaper-apply: no monitors parsed; leaving config untouched" >&2
    rm -f "$tmp"
    exit 1
fi

if [[ -n ${DRY_RUN:-} ]]; then
    cat "$tmp"
    rm -f "$tmp"
    exit 0
fi

mv -f "$tmp" "$saved_cfg"

if command -v nitrogen >/dev/null 2>&1; then
    # Run in the FOREGROUND and log everything. The old backgrounded run raced
    # the parent shell exiting at login (silent failure -> black walls( and was hit
    # twice by the stale early `nitrogen --restore &` in i3 config.
    wall_log="${WALLPAPER_LOG:-/tmp/wallpaper-apply.log}"
    if ! nitrogen --restore >> "$wall_log" 2>&1; then
        echo "wallpaper-apply: nitrogen --restore failed; see $wall_log" >&2
    fi
else
    echo "wallpaper-apply: nitrogen not found; config written but not applied" >&2
fi
