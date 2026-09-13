#!/usr/bin/env bash
#
# Bluetooth flyout popup (media-popup style): floating scratchpad Alacritty.
#
# Lists paired devices with connected/battery state. j/k or arrows select,
# Space toggles connect/disconnect, r unpairs, Esc hides.
# Renders live at 1 Hz. Window size adapts to the device count at spawn.

mark=bluetooth_popup
accent=$'\e[38;2;240;198;116m'
green=$'\e[38;2;166;227;161m'
red=$'\e[38;2;243;139;168m'
dim=$'\e[2m'
bold=$'\e[1m'
rst=$'\e[0m'
eol=$'\e[K'
dim_cols=36
# Right-edge alignment: popup right edge sits popup_right_off px from the
# monitor's right edge; bottom edge popup_bottom px above it (bar ≈ 48px tall)
popup_right_off=450
popup_bottom=64

# Title banner (half-block glyphs, embedded; %s-printed so backslashes are literal)
BANNER=(
'█▀▀▄ ▐ ▐ ▌ ▄▀▀ ▄▐ ▄▀▄ ▄▀▄ ▄▐ █▄▄'
'█▄▄█ ▐ ▄▄▄ ▀▄▄  ▐ ▀▄▀ ▀▄▀  ▐ █ █'
)

feedback=""

# devices_tabsep: "connected<US>battery<US>mac<US>name" per line
# US (\x1f) delimiter: tabs/spaces would collapse empty battery fields in read
SEP=$'\x1f'
devices_tabsep=()
sel=0

devices() {
    local out line
    devices_tabsep=()
    out=$(bluetoothctl devices Paired 2>/dev/null) || out=""
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        line=${line#\#Device }
        line=${line#Device }
        local mac=${line%% *} name=${line#* }
        if [ "${#name}" -gt 20 ]; then
            name="${name:0:19}…"
        fi
        local conn
        if bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes'; then
            conn=yes
        else
            conn=no
        fi
        local bat
        bat=$(bluetoothctl info "$mac" 2>/dev/null | awk -F'[()]' '/Battery Percentage/ {print $2; exit}')
        devices_tabsep+=("${conn}${SEP}${bat}${SEP}${mac}${SEP}${name}")
    done <<<"$out"
    return 0
}

clamp_sel() {
    local count=${#devices_tabsep[@]}
    [ "$sel" -ge "$count" ] && sel=$(( count > 0 ? count - 1 : 0 ))
    [ "$sel" -lt 0 ] && sel=0
    return 0
}

render() {
    local powered i row conn bat mac name arrow bline
    printf '%b\n' "$eol"
    if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
        powered=on
    else
        powered=off
    fi
    for bline in "${BANNER[@]}"; do
        printf '%s\n' "${bold}${accent}${bline}${rst}${eol}"
    done
    printf '%b\n' "${dim}· adapter ${powered}${rst}${eol}"
    printf '%b\n' "$eol"

    local count=${#devices_tabsep[@]}
    if [ "$powered" = "off" ]; then
        printf '%b\n' "${dim}( adapter off )${rst}${eol}"
    elif [ "$count" -eq 0 ]; then
        printf '%b\n' "${dim}( no paired devices )${rst}${eol}"
    else
        for i in "${!devices_tabsep[@]}"; do
            IFS="$SEP" read -r conn bat mac name <<<"${devices_tabsep[$i]}"
            if [ "$i" -eq "$sel" ]; then
                arrow="${accent}›${rst} "
            else
                arrow="  "
            fi
            if [ "$conn" = "yes" ]; then
                row="${arrow}${green}\uf00c${rst} ${name}"
            else
                row="${arrow}${dim}· ${name}${rst}"
            fi
            [ -n "$bat" ] && row+=" ${dim}${bat}%${rst}"
            printf '%b\n' "${row}${eol}"
        done
    fi
    printf '%b\n' "$eol"

    printf '%b\n' "${feedback}${eol}"
    printf '%b\n' "${dim}j/k select · space toggle${rst}${eol}"
    printf '%b\n' "${dim}r remove · esc hide${rst}${eol}"
}

toggle_device() {
    local conn bat mac name
    [ "${#devices_tabsep[@]}" -eq 0 ] && return
    IFS="$SEP" read -r conn bat mac name <<<"${devices_tabsep[$sel]}"
    if [ "$conn" = "yes" ]; then
        feedback="${dim}disconnecting ${name}…${rst}"
        printf '\e[H%s\e[J' "$(render)"
        if bluetoothctl disconnect "$mac" >/dev/null 2>&1; then
            feedback="${green}✔${rst} ${name} disconnected"
        else
            feedback="${red}✘${rst} disconnect failed"
        fi
    else
        feedback="${dim}connecting ${name}…${rst}"
        printf '\e[H%s\e[J' "$(render)"
        if bluetoothctl connect "$mac" >/dev/null 2>&1; then
            feedback="${green}✔${rst} ${name} connected"
        else
            feedback="${red}✘${rst} connect failed (reachable?)"
        fi
    fi
}

remove_device() {
    local conn bat mac name
    [ "${#devices_tabsep[@]}" -eq 0 ] && return
    IFS="$SEP" read -r conn bat mac name <<<"${devices_tabsep[$sel]}"
    feedback="${dim}removing ${name}…${rst}"
    printf '\e[H%s\e[J' "$(render)"
    if bluetoothctl remove "$mac" >/dev/null 2>&1; then
        feedback="${green}✔${rst} ${name} removed"
    else
        feedback="${red}✘${rst} remove failed"
    fi
}

loop() {
    local esc=$'\e' key key2 key3 frame last=""
    printf '\e[?25l'
    trap 'printf "\e[?25h"' EXIT
    while true; do
        devices
        clamp_sel
        frame=$(render)
        if [ "$frame" != "$last" ]; then
            printf '\e[H%s\e[J' "$frame"
            last=$frame
        fi
        IFS= read -rsn1 -t 1 key || continue
        if [ "$key" = "$esc" ]; then
            if IFS= read -rsn1 -t 0.05 key2 && [ "$key2" = "[" ]; then
                IFS= read -rsn1 -t 0.05 key3 || continue
                case "$key3" in
                    A) [ "${#devices_tabsep[@]}" -gt 0 ] && [ "$sel" -gt 0 ] && sel=$((sel - 1)) ;;
                    B) [ "$sel" -lt $(( ${#devices_tabsep[@]} - 1 )) ] && sel=$((sel + 1)) ;;
                esac
            else
                i3-msg "[con_mark=$mark] move scratchpad" >/dev/null 2>&1
            fi
            continue
        fi
        case "$key" in
            j) [ "$sel" -lt $(( ${#devices_tabsep[@]} - 1 )) ] && sel=$((sel + 1)) ;;
            k) [ "$sel" -gt 0 ] && sel=$((sel - 1)) ;;
            " ") toggle_device ;;
            r) remove_device ;;
        esac
    done
}

position_popup() {
    local out rect gw gh ox oy ow oh
    read -r gw gh <<<"$(i3-msg -t get_tree 2>/dev/null | jq -r '[.. | objects | select((.marks? // []) | index("bluetooth_popup"))][0].geometry | "\(.width // 0) \(.height // 0)"' 2>/dev/null)"
    if [[ "$gw" =~ ^[1-9][0-9]*$ ]] && [[ "$gh" =~ ^[1-9][0-9]*$ ]]; then
        i3-msg "[con_mark=$mark] resize set $gw px $gh px" >/dev/null 2>&1
    fi
    out=$(i3-msg -t get_outputs 2>/dev/null | jq -r '[.[] | select(.primary and .active)][0].name // empty')
    [ -z "$out" ] && out=$(i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused).output')
    rect=$(i3-msg -t get_tree 2>/dev/null | jq -r --arg o "$out" '.. | objects | select(.type? == "output" and .name? == $o) | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"')
    read -r ox oy ow oh <<<"$rect"
    [ -n "$ox" ] && i3-msg "[con_mark=$mark] move position $(( ox + ow - gw - popup_right_off )) px $(( oy + oh - popup_bottom - gh )) px" >/dev/null 2>&1
}

toggle() {
    local script node ndev lines
    script=$(readlink -f "${BASH_SOURCE[0]}")
    ndev=$(bluetoothctl devices Paired 2>/dev/null | grep -c .)
    [ "${ndev:-0}" -ge 1 ] || ndev=1
    lines=$(( 9 + ndev ))
    node=$(i3-msg -t get_tree 2>/dev/null | jq -r '.. | objects | select((.marks? // []) | index("bluetooth_popup")) | .output' 2>/dev/null | head -1)
    if [ -z "$node" ]; then
        setsid -f alacritty --class bluetooth-popup -o window.dimensions.columns=$dim_cols -o window.dimensions.lines=$lines -e "$script" >/dev/null 2>&1
        local i n
        for i in $(seq 1 20); do
            sleep 0.1
            i3-msg '[class="^bluetooth-popup$"] floating enable, sticky enable, border none, mark bluetooth_popup' >/dev/null 2>&1
            n=$(i3-msg -t get_tree 2>/dev/null | jq -r '[.. | objects | select((.marks? // []) | index("bluetooth_popup"))] | length' 2>/dev/null)
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
    once) devices && clamp_sel && render ;;
    *) loop ;;
esac
