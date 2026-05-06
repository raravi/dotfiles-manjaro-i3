#!/bin/bash

# Assign the Caps Lock key to Super key (which is my i3 Mod key)...
# But when it is pressed only once, treat it as escape.
setxkbmap -option caps:super
killall xcape ; xcape -e "Super_L=Escape"

# Assign Left Control to Left Shift key
xmodmap -e "keycode 50 = Shift_L"
xmodmap -e "remove shift = Shift_L"
xmodmap -e "keycode 50 = Control_L"
xmodmap -e "add control = Control_L"

