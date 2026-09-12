#!/usr/bin/env bash

color_reset='%{F-}'
color_primary='%{F#F0C674}'
color_disabled='%{F#707880}'

ic_headphones=$'\uf025'
ic_bluetooth_headphones=$'\U000F0970'
ic_speakers=$'\uf028'
ic_bluetooth=$'\uf294'
#ic_echo=$'\U000F071F'
ic_echo=$'\U000F09A2'
ic_monitor=$'\uf26c'
ic_eq=$'\uf1de'
ic_mute=$'\uf026'

render() {
    sink=$1
    if [ -z "$sink" ]; then
        sink=$(pactl get-default-sink 2>/dev/null) || return
    fi

    read -r port form desc <<<"$(pactl list sinks 2>/dev/null | awk -v s="$sink" '
        /^[[:space:]]+Name: / { in_block = ($2 == s) }
        in_block && /Active Port: / { port = $3 }
        in_block && /device.form_factor = / { form = $3; gsub(/"/, "", form) }
        in_block && /device.description = / { match($0, /"[^"]*"/); desc = substr($0, RSTART + 1, RLENGTH - 2) }
        END { print port, form, desc }
    ')"

    icon=$ic_speakers
    case $sink in
        easyeffects_sink) icon=$ic_eq ;;
        bluez_*)
            case $form in
                *head*|*hands*) icon=$ic_bluetooth_headphones ;;
                *)
                    case $desc in
                        *Echo*) icon=$ic_bluetooth ;;
                        *) icon=$ic_bluetooth ;;
                    esac
                    ;;
            esac
            ;;
        *)
            case $port in
                *headphones*|*headset*) icon=$ic_headphones ;;
                *hdmi*|*displayport*) icon=$ic_monitor ;;
            esac
            ;;
    esac

    volume=$(pactl get-sink-volume "$sink" 2>/dev/null | grep -oE '[0-9]+ ?%' | head -1 | tr -d ' %') || return
    [ -n "$volume" ] || return

    if pactl get-sink-mute "$sink" 2>/dev/null | grep -q yes; then
        printf '%s%s muted%s\n' "$color_disabled" "$ic_mute" "$color_reset"
    else
        printf '%s%s%s %s%%\n' "$color_primary" "$icon" "$color_reset" "$volume"
    fi
}

render "$1"
[ -n "$1" ] && exit 0
pactl subscribe 2>/dev/null | while read -r event; do
    case $event in
        *" on sink "*|*" on server "*|*" on card "*) render "$1" ;;
    esac
done
