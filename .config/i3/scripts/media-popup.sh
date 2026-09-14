#!/usr/bin/env bash
#
# Media flyout popup (scratchpad Alacritty): control view for the Playing
# player, or a player picker (most-recently-paused first) when nothing is
# Playing. Tab opens the picker from the control view; polybar clicks go
# through the `action` subcommand. Player state (MRU order + per-player
# meta) is shared with polybar/media.sh in ~/.cache/media-players/.

mark=media_popup
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/spotify-art"
state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/media-players"
order_file="$state_dir/order"
meta_dir="$state_dir/meta"
blacklist=" plasma-browser-integration "
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
popup_x_off=128
popup_bottom=64

pinned=""
entries=()
sel=0

get_pos() {
    local p i
    for i in 1 2 3; do
        p=$(playerctl -p "$1" position 2>/dev/null) && [ -n "$p" ] && { printf '%s' "$p"; return; }
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
    local s=$2
    [ "${#s}" -gt "$1" ] && s="${s:0:$(( $1 - 1 ))}…"
    printf '%s' "$s"
}

clean_title() {  # $1=player $2=title; strips browser page-title cruft, browser players only
    case $1 in
        brave* | chromium* | google-chrome* | microsoft-edge* | firefox* | librewolf* | vivaldi* | opera* | epiphany* | qutebrowser*)
            printf '%s' "${2#Watch }" ;;
        *) printf '%s' "$2" ;;
    esac
}

list_players() {
    local p
    playerctl -l 2>/dev/null | while IFS= read -r p; do
        [ -n "$p" ] || continue
        [[ "$blacklist" == *" $p "* ]] && continue
        printf '%s\n' "$p"
    done
}

first_playing() {
    local p q playing=()
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ] && playing+=("$p")
    done <<<"$1"
    ((${#playing[@]})) || return 0
    for q in "${playing[@]}"; do
        [[ "$q" == spotify* ]] && { printf '%s' "$q"; return; }
    done
    printf '%s' "${playing[0]}"
}

fallback_player() {
    local p
    if [ -f "$order_file" ]; then
        while IFS= read -r p; do
            [ -n "$p" ] || continue
            grep -qxF "$p" <<<"$1" && { printf '%s' "$p"; return; }
        done <"$order_file"
    fi
    grep '^spotify' <<<"$1" || head -n1 <<<"$1"
}

mode_target() {
    local pl
    pl=$(first_playing "$1") && [ -n "$pl" ] && { printf '%s' "$pl"; return; }
    [ -n "$pinned" ] && grep -qxF "$pinned" <<<"$1" && { printf '%s' "$pinned"; return; }
    return 0
}

safe_name() {
    printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

meta_track() {
    local f artist title
    f="$meta_dir/$(safe_name "$1")"
    [ -f "$f" ] || return 0
    IFS='|' read -r artist title <<<"$(head -n1 "$f")"
    if [ -n "$artist" ] && [ -n "$title" ]; then
        trunc 20 "$artist — $(clean_title "$1" "$title")"
    elif [ -n "$artist" ]; then
        trunc 20 "$artist"
    else
        trunc 20 "$(clean_title "$1" "$title")"
    fi
}

last_art_url=""
art_cache=""

art_frame() {
    local pl=$1 art_url file
    art_url=$(playerctl -p "$pl" metadata mpris:artUrl 2>/dev/null)
    if [ -n "$art_url" ] && [ "$art_url" = "$last_art_url" ]; then
        printf '%s' "$art_cache"
        return
    fi
    last_art_url=$art_url
    art_cache=""
    file=""
    if [ -n "$art_url" ]; then
        file="$cache_dir/$(basename "${art_url%%\?*}")"
        [ -f "$file" ] || curl -fsSL --max-time 10 -o "$file" "$art_url" 2>/dev/null
    fi
    if [ -f "$file" ]; then
        if command -v chafa >/dev/null 2>&1; then
            art_cache=$(chafa --font-ratio 1/2 --size 42x21 "$file" 2>/dev/null)
        else
            art_cache=$(printf '%b' "${dim}( install chafa for cover art )${rst}")
        fi
    fi
    [ -z "$art_cache" ] && art_cache=$(printf '%b' "${dim}( no cover art )${rst}")
    printf '%s' "$art_cache"
}

render() {
    local pl=$1 status artist title album length_us pos dur pos_s dur_s pct vol loop shuf src
    status=$(playerctl -p "$pl" status 2>/dev/null)
    if [ -z "$status" ]; then
        printf '%b\n' "${dim}player not responding${rst}${eol}"
        return
    fi
    IFS=$'\x1f' read -r artist title album length_us <<<"$(playerctl -p "$pl" metadata -f $'{{artist}}\x1f{{title}}\x1f{{album}}\x1f{{mpris:length}}' 2>/dev/null)"
    pos=$(get_pos "$pl")
    vol=$(awk -v v="$(playerctl -p "$pl" volume 2>/dev/null)" 'BEGIN { printf "%d", v * 100 + 0.5 }')
    loop=$(playerctl -p "$pl" loop 2>/dev/null)
    shuf=$(playerctl -p "$pl" shuffle 2>/dev/null)

    art_frame "$pl"

    printf '%b\n' "$eol"
    printf '%b\n' "${bold}${accent}$(trunc "$max_col" "$(clean_title "$pl" "${title:-Unknown title}")")${rst}${eol}"
    printf '%b\n' "${dim}$(trunc "$max_col" "${artist:-Unknown artist} — ${album:-Unknown album}")${rst}${eol}"
    printf '%b\n' "$eol"

    pos_s=${pos%.*}
    dur_s=$(( ${length_us:-0} / 1000000 ))
    pos_s=${pos_s:-0}
    if [ "$dur_s" -gt 0 ]; then
        pct=$(( pos_s * 100 / dur_s ))
    else
        pct=0
    fi
    src=${pl%%.*}
    if [ "$status" = "Playing" ]; then
        printf '%b\n' "${green}playing${rst}${dim} · ${rst}$(fmt_time "$pos")${dim} / ${rst}$(fmt_time "$dur_s")${dim} · ${src}${rst}${eol}"
    else
        printf '%b\n' "${dim}paused · $(fmt_time "$pos") / $(fmt_time "$dur_s") · ${src}${eol}"
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

picker_entries() {
    local p seen=" "
    entries=()
    if [ -f "$order_file" ]; then
        while IFS= read -r p; do
            [ -n "$p" ] || continue
            [[ "$seen" == *" $p "* ]] && continue
            grep -qxF "$p" <<<"$1" || continue
            entries+=("$p")
            seen+="$p "
        done <"$order_file"
    fi
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        [[ "$seen" == *" $p "* ]] && continue
        entries+=("$p")
        seen+="$p "
    done <<<"$1"
}

clamp_sel() {
    local count=${#entries[@]}
    [ "$sel" -ge "$count" ] && sel=$(( count > 0 ? count - 1 : 0 ))
    [ "$sel" -lt 0 ] && sel=0
    return 0
}

render_picker() {
    local i p arrow
    printf '%b\n' "$eol"
    printf '%b\n' "${bold}${accent}media${rst}${dim} · pick a player${rst}${eol}"
    printf '%b\n' "$eol"
    if [ "${#entries[@]}" -eq 0 ]; then
        printf '%b\n' "${dim}( no media players )${rst}${eol}"
    else
        for i in "${!entries[@]}"; do
            p=${entries[$i]}
            if [ "$i" -eq "$sel" ]; then
                arrow="${accent}›${rst} "
                printf '%b\n' "${arrow}${accent}$(trunc 20 "${p%%.*}")${rst} ${dim}$(meta_track "$p")${eol}"
            else
                arrow="  "
                printf '%b\n' "${arrow}$(trunc 20 "${p%%.*}") ${dim}$(meta_track "$p")${eol}"
            fi
        done
    fi
    printf '%b\n' "$eol"
    printf '%b\n' "${dim}j/k select · enter open · esc hide${rst}${eol}"
}

loop() {
    local esc=$'\e' key key2 key3 frame last="" live pl mode
    local force_picker=0 cr=$'\r' lf=$'\n'
    printf '\e[?25l'
    trap 'printf "\e[?25h"' EXIT
    while true; do
        live=$(list_players)
        pl=""
        [ "$force_picker" -eq 0 ] && pl=$(mode_target "$live")
        if [ -n "$pl" ]; then
            mode=control
        else
            mode=picker
            picker_entries "$live"
            clamp_sel
        fi
        if [ "$mode" = control ]; then
            frame=$(render "$pl")
        else
            frame=$(render_picker)
        fi
        if [ "$frame" != "$last" ]; then
            printf '\e[H%s\e[J' "$frame"
            last=$frame
        fi
        key=""
        key2=""
        key3=""
        IFS= read -rsn1 -t 1 key
        rc=$?
        [ "$rc" -eq 1 ] && break
        [ "$rc" -ne 0 ] && continue
        if [ "$key" = "$esc" ]; then
            if IFS= read -rsn1 -t 0.05 key2 && [ "$key2" = "[" ]; then
                IFS= read -rsn1 -t 0.05 key3 || continue
                case "$key3" in
                    A) [ "$sel" -gt 0 ] && sel=$((sel - 1)) ;;
                    B) [ "$sel" -lt $(( ${#entries[@]} - 1 )) ] && sel=$((sel + 1)) ;;
                esac
            else
                force_picker=0
                i3-msg "[con_mark=$mark] move scratchpad" >/dev/null 2>&1
            fi
            continue
        fi
        if [ "$mode" = picker ]; then
            case "$key" in
                j) [ "$sel" -lt $(( ${#entries[@]} - 1 )) ] && sel=$((sel + 1)) ;;
                k) [ "$sel" -gt 0 ] && sel=$((sel - 1)) ;;
                " " | "$cr" | "$lf")
                    if [ "${#entries[@]}" -gt 0 ]; then
                        pinned=${entries[$sel]}
                        force_picker=0
                    fi
                    ;;
                q)
                    force_picker=0
                    i3-msg "[con_mark=$mark] move scratchpad" >/dev/null 2>&1
                    ;;
            esac
        else
            case "$key" in
                " ") [ -n "$pl" ] && playerctl -p "$pl" play-pause >/dev/null 2>&1 ;;
                n) [ -n "$pl" ] && playerctl -p "$pl" next >/dev/null 2>&1 ;;
                p) [ -n "$pl" ] && playerctl -p "$pl" previous >/dev/null 2>&1 ;;
                $'\t') force_picker=1 ;;
                q)
                    force_picker=0
                    i3-msg "[con_mark=$mark] move scratchpad" >/dev/null 2>&1
                    ;;
            esac
        fi
    done
}

position_popup() {
    local out rect gw gh ox oy ow oh
    read -r gw gh <<<"$(i3-msg -t get_tree 2>/dev/null | jq -r '[.. | objects | select((.marks? // []) | index("media_popup"))][0].geometry | "\(.width // 0) \(.height // 0)"' 2>/dev/null)"
    if [[ "$gw" =~ ^[1-9][0-9]*$ ]] && [[ "$gh" =~ ^[1-9][0-9]*$ ]]; then
        i3-msg "[con_mark=$mark] resize set $gw px $gh px" >/dev/null 2>&1
    fi
    out=$(i3-msg -t get_outputs 2>/dev/null | jq -r '[.[] | select(.primary and .active)][0].name // empty')
    [ -z "$out" ] && out=$(i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused).output')
    rect=$(i3-msg -t get_tree 2>/dev/null | jq -r --arg o "$out" '.. | objects | select(.type? == "output" and .name? == $o) | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"')
    read -r ox oy ow oh <<<"$rect"
    [ -n "$ox" ] && i3-msg "[con_mark=$mark] move position $((ox + popup_x_off)) px $((oy + oh - popup_bottom - gh)) px" >/dev/null 2>&1
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

once() {
    local live pl
    live=$(list_players)
    pl=$(mode_target "$live")
    if [ -n "$pl" ]; then
        render "$pl"
    else
        picker_entries "$live"
        clamp_sel
        render_picker
    fi
}

action() {
    local live pl
    live=$(list_players)
    pl=$(first_playing "$live")
    [ -z "$pl" ] && pl=$(fallback_player "$live")
    [ -n "$pl" ] && playerctl -p "$pl" "${2:-play-pause}" >/dev/null 2>&1
}

case "${1:-loop}" in
    toggle) toggle ;;
    once) once ;;
    action) action "$2" ;;
    *) loop ;;
esac
