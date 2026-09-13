#!/usr/bin/env bash

mark=media_popup
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/spotify-art"
accent='\e[38;2;240;198;116m'
green='\e[38;2;166;227;161m'
dim='\e[2m'
bold='\e[1m'
rst='\e[0m'
eol=$'\e[K'
bar_w=26
max_col=44
dim_cols=44
dim_lines=28

get_pos() {
    local p i
    for i in 1 2 3; do
        p=$(playerctl -p spotify position 2>/dev/null) && [ -n "$p" ] && { printf '%s' "$p"; return; }
        sleep 0.1
    done
}

fmt_time() {
    local s=${1%.*}
    s=${s:-0}
    [ "$s" -lt 0 ] && s=0
    printf '%d:%02d' $((s / 60)) $((s % 60))
}

trunc() {
    local s=$1
    [ "${#s}" -gt "$max_col" ] && s="${s:0:$((max_col - 1))}…"
    printf '%s' "$s"
}

last_art_url=""
art_cache=""

art_frame() {
    local art_url file
    art_url=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null)
    if [ -n "$art_url" ] && [ "$art_url" = "$last_art_url" ]; then
        printf '%s' "$art_cache"
        return
    fi
    last_art_url=$art_url
    file=""
    if [ -n "$art_url" ]; then
        file="$cache_dir/$(basename "${art_url%%\?*}")"
        [ -f "$file" ] || curl -fsSL --max-time 10 -o "$file" "$art_url" 2>/dev/null
    fi
    if command -v chafa >/dev/null 2>&1 && [ -f "$file" ]; then
        art_cache=$(chafa --size 42x21 "$file" 2>/dev/null)
    else
        art_cache=$(printf '%b' "${dim}( install chafa for cover art )${rst}")
    fi
    printf '%s' "$art_cache"
}

render() {
    local status artist title album length_us pos dur pos_s dur_s pct vol loop shuf
    status=$(playerctl -p spotify status 2>/dev/null)
    if [ -z "$status" ]; then
        printf '%b\n' "${dim}Spotify not running${rst}${eol}"
        return
    fi
    IFS=$'\t' read -r artist title album length_us <<<"$(playerctl -p spotify metadata -f $'{{artist}}\t{{title}}\t{{album}}\t{{mpris:length}}' 2>/dev/null)"
    pos=$(get_pos)
    vol=$(awk -v v="$(playerctl -p spotify volume 2>/dev/null)" 'BEGIN { printf "%d", v * 100 + 0.5 }')
    loop=$(playerctl -p spotify loop 2>/dev/null)
    shuf=$(playerctl -p spotify shuffle 2>/dev/null)

    art_frame

    printf '%b\n' "$eol"
    printf '%b\n' "${bold}${accent}$(trunc "${title:-Unknown title}")${rst}${eol}"
    printf '%b\n' "${dim}$(trunc "${artist:-Unknown artist} — ${album:-Unknown album}")${rst}${eol}"
    printf '%b\n' "$eol"

    pos_s=${pos%.*}
    dur_s=$(( ${length_us:-0} / 1000000 ))
    pos_s=${pos_s:-0}
    if [ "$dur_s" -gt 0 ]; then
        pct=$(( pos_s * 100 / dur_s ))
    else
        pct=0
    fi
    if [ "$status" = "Playing" ]; then
        printf '%b\n' "${green}playing${rst}${dim} · ${rst}$(fmt_time "$pos")${dim} / ${rst}$(fmt_time "${dur_s}")${eol}"
    else
        printf '%b\n' "${dim}paused · $(fmt_time "$pos") / $(fmt_time "${dur_s}")${eol}"
    fi

    local filled i bar=""
    filled=$(( pct * bar_w / 100 ))
    [ "$filled" -gt "$bar_w" ] && filled=$bar_w
    for ((i = 0; i < filled; i++)); do bar+='█'; done
    for ((i = filled; i < bar_w; i++)); do bar+='░'; done
    printf '%b %3d%%%b\n' "${accent}${bar}${rst}" "$pct" "$eol"

    loop=${loop,,}
    shuf=${shuf,,}
    printf '%b\n' "${dim}vol ${vol:-0}% · repeat ${loop:-?} · shuffle ${shuf:-?}${rst}${eol}"
}

loop() {
    local esc=$'\e' key frame last=""
    printf '\e[?25l'
    trap 'printf "\e[?25h"' EXIT
    while true; do
        frame=$(render)
        if [ "$frame" != "$last" ]; then
            printf '\e[H%s\e[J' "$frame"
            last=$frame
        fi
        key=""
        read -rsn1 -t 1 key || continue
        case "$key" in
            q | "$esc") i3-msg "[con_mark=$mark] move scratchpad" >/dev/null 2>&1 ;;
            " ") playerctl -p spotify play-pause >/dev/null 2>&1 ;;
            n) playerctl -p spotify next >/dev/null 2>&1 ;;
            p) playerctl -p spotify previous >/dev/null 2>&1 ;;
        esac
    done
}

position_popup() {
    local out rect ox oy gw gh
    read -r gw gh <<<"$(i3-msg -t get_tree 2>/dev/null | jq -r '[.. | objects | select((.marks? // []) | index("media_popup"))][0].geometry | "\(.width // 0) \(.height // 0)"' 2>/dev/null)"
    if [[ "$gw" =~ ^[1-9][0-9]*$ ]] && [[ "$gh" =~ ^[1-9][0-9]*$ ]]; then
        i3-msg "[con_mark=$mark] resize set $gw px $gh px" >/dev/null 2>&1
    fi
    out=$(i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused).output')
    rect=$(i3-msg -t get_tree 2>/dev/null | jq -r --arg o "$out" '.. | objects | select(.type? == "output" and .name? == $o) | "\(.rect.x) \(.rect.y)"')
    read -r ox oy <<<"$rect"
    [ -n "$ox" ] && i3-msg "[con_mark=$mark] move position $((ox + 60)) px $((oy + 46)) px" >/dev/null 2>&1
}

toggle() {
    local script node
    script=$(readlink -f "${BASH_SOURCE[0]}")
    node=$(i3-msg -t get_tree 2>/dev/null | jq -r '.. | objects | select((.marks? // []) | index("media_popup")) | .output' 2>/dev/null | head -1)
    if [ -z "$node" ]; then
        setsid -f alacritty --class media-popup -o window.dimensions.columns=$dim_cols -o window.dimensions.lines=$dim_lines -e "$script" >/dev/null 2>&1
        local i n
        for i in $(seq 1 20); do
            sleep 0.1
            i3-msg '[class="^media-popup$"] floating enable, sticky enable, border none, mark media_popup' >/dev/null 2>&1
            n=$(i3-msg -t get_tree 2>/dev/null | jq -r '[.. | objects | select((.marks? // []) | index("media_popup"))] | length' 2>/dev/null)
            [ "${n:-0}" -ge 1 ] && { position_popup; return; }
        done
    elif [[ "$node" == __i3* ]]; then
        i3-msg "[con_mark=$mark] scratchpad show" >/dev/null 2>&1
        position_popup
    else
        i3-msg "[con_mark=$mark] move scratchpad" >/dev/null 2>&1
    fi
}

case "${1:-loop}" in
    toggle) toggle ;;
    once) render ;;
    *) loop ;;
esac
