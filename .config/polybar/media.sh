#!/usr/bin/env bash

color_reset='%{F-}'
color_primary='%{F#F0C674}'

ic_play=$'\uf04b'
ic_pause=$'\uf04c'

render() {
    IFS='|' read -r status artist title <<<"$1"
    case $status in
        Playing) icon=$ic_pause ;;
        *) icon=$ic_play ;;
    esac
    track=$artist
    [ -n "$artist" ] && [ -n "$title" ] && track="$artist - $title"
    [ "${#track}" -gt 30 ] && track="${track:0:29}..."
    body="$color_primary$icon$color_reset"
    [ -n "$track" ] && body="$body $track"
    printf '%s\n' "$body"
}

while true; do
    playerctl -F -p spotify metadata -f '{{status}}|{{artist}}|{{title}}' 2>/dev/null | while read -r line; do
        render "$line"
    done
    echo
    sleep 2
done