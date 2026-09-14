#!/usr/bin/env bash
#
# Media pill: polls all MPRIS players at 1 Hz and renders the Playing one;
# when nothing is Playing, renders the most-recently-paused player dim.
# Maintains ~/.cache/media-players/ (MRU order + per-player meta) consumed
# by i3/scripts/media-popup.sh. Tab/whitespace-unsafe fields use \x1f.

color_reset='%{F-}'
color_primary='%{F#F0C674}'
color_disabled='%{F#707880}'

ic_play=$'\uf04b'
ic_pause=$'\uf04c'

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/media-players"
meta_dir="$state_dir/meta"
order_file="$state_dir/order"
blacklist=" plasma-browser-integration "
SEP=$'\x1f'

mkdir -p "$meta_dir"

declare -A p_status p_track
order=()
order_dirty=0
meta_dirty=0

is_blacklisted() {
    [[ "$blacklist" == *" $1 "* ]]
}

safe_name() {
    printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

clean_title() {
    printf '%s' "${1#Watch }"
}

mru_front() {
    local p=$1 i out=()
    for i in "${!order[@]}"; do
        [ "${order[$i]}" != "$p" ] && out+=("${order[$i]}")
    done
    order=("$p" "${out[@]}")
    order_dirty=1
}

prune_dead() {
    local p i keep=()
    for i in "${!order[@]}"; do
        p=${order[$i]}
        if grep -qxF "$p" <<<"$1"; then
            keep+=("$p")
        else
            unset "p_status[$p]" "p_track[$p]"
            rm -f "$meta_dir/$(safe_name "$p")"
            order_dirty=1
        fi
    done
    order=("${keep[@]}")
}

save_state() {
    local p fn
    if [ "$order_dirty" = 1 ]; then
        : >"$order_file.new" || return
        for p in "${order[@]}"; do
            printf '%s\n' "$p" >>"$order_file.new"
        done
        mv "$order_file.new" "$order_file"
        order_dirty=0
    fi
    if [ "$meta_dirty" = 1 ]; then
        for p in "${!p_track[@]}"; do
            fn="$meta_dir/$(safe_name "$p")"
            printf '%s\n' "${p_track[$p]}" >"$fn.new" && mv "$fn.new" "$fn"
        done
        meta_dirty=0
    fi
}

render_line() {
    local status=$1 artist=$2 title=$3 style=$4 icon track
    case $status in
        Playing) icon=$ic_pause ;;
        *) icon=$ic_play ;;
    esac
    if [ -n "$artist" ] && [ -n "$title" ]; then
        track="$artist - $title"
    else
        track="$title$artist"
    fi
    [ "${#track}" -gt 30 ] && track="${track:0:29}..."
    if [ "$style" = dim ]; then
        printf '%s%s%s %s%s%s' "$color_disabled" "$icon" "$color_reset" "$color_disabled" "$track" "$color_reset"
    else
        printf '%s%s%s %s' "$color_primary" "$icon" "$color_reset" "$track"
    fi
}

emit() {
    local p artist title
    for p in "${order[@]}"; do
        [ "${p_status[$p]}" = "Playing" ] || continue
        IFS='|' read -r artist title <<<"${p_track[$p]}"
        render_line Playing "$artist" "$title" normal
        return
    done
    for p in "${order[@]}"; do
        [ -n "${p_status[$p]}" ] || continue
        IFS='|' read -r artist title <<<"${p_track[$p]}"
        render_line "${p_status[$p]}" "$artist" "$title" dim
        return
    done
    printf ''
}

last_out="__unset__"

while true; do
    live=$(playerctl -l 2>/dev/null)
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        is_blacklisted "$p" && continue
        IFS="$SEP" read -r status artist title <<<"$(playerctl -p "$p" metadata -f "{{status}}${SEP}{{artist}}${SEP}{{title}}" 2>/dev/null)"
        if [ -z "$status" ]; then
            unset "p_status[$p]" "p_track[$p]"
            continue
        fi
        if [ -z "${p_status[$p]}" ]; then
            p_status[$p]=$status
            order+=("$p")
            order_dirty=1
        elif [ "${p_status[$p]}" != "$status" ]; then
            p_status[$p]=$status
            mru_front "$p"
        fi
        title=$(clean_title "$title")
        if [ "${p_track[$p]}" != "$artist|$title" ]; then
            p_track[$p]="$artist|$title"
            meta_dirty=1
        fi
    done <<<"$live"
    prune_dead "$live"
    save_state

    out=$(emit)
    if [ "$out" != "$last_out" ]; then
        printf '%s\n' "$out"
        last_out=$out
    fi
    sleep 1
done
