#!/usr/bin/env bash

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/spotify-art"
mkdir -p "$cache_dir"

fmt=$'{{status}}\t{{mpris:artUrl}}\t{{title}}\t{{artist}}\t{{album}}'
last=""

while true; do
    playerctl -F -p spotify metadata -f "$fmt" 2>/dev/null |
    while IFS=$'\t' read -r status art_url title artist album; do
        [ "$status" = "Playing" ] || continue
        [ -n "$title" ] || continue
        key="$artist - $title"
        [ "$key" = "$last" ] && continue
        last="$key"

        icon=""
        if [ -n "$art_url" ]; then
            file="$cache_dir/$(basename "${art_url%%\?*}")"
            [ -f "$file" ] || curl -fsSL --max-time 10 -o "$file" "$art_url" 2>/dev/null
            [ -f "$file" ] && icon="$file"
        fi

        body=""
        [ -n "$artist" ] && body="$artist"
        [ -n "$artist" ] && [ -n "$album" ] && body="$artist — $album"
        [ -z "$body" ] && body="$album"

        if [ -n "$icon" ]; then
            notify-send -i "file://$icon" -a Spotify "$title" "$body"
        else
            notify-send -a Spotify "$title" "$body"
        fi
    done
    sleep 2
done
