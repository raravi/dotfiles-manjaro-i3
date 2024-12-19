#!/usr/bin/env bash

# Terminate already running xborder instances
killall -q xborders

# Launch xborder
$HOME/.config/xborder/./xborders --config $HOME/.config/xborder/config.json

