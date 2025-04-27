# List of things to do on First Install

## Packages to Install
### General

These are useful on first login
```bash
pamac install alacritty neovim xclip
```
Note: nvim needs a clipboard tool to copy contents (using CTRL+SHIFT+C / CTRL+SHIFT+V commands) from a buffer to another.

These are for long-term use. If a second Windows Manager is going to be installed, then\
these can be installed in it.
```bash
pamac install spotify discord teams-for-linux
```

### i3 Tiling Windows Manager

These are i3 and related packages
```bash
pamac install i3-wm i3status xss-lock betterlockscreen deadd-notification-center blueman network-manager-applet perl-anyevent-i3
```
Note: In order to save i3 workspaces, `perl-anyevent-i3` is needed.

In order to manage Wallpapers upon login
```bash
pamac install nitrogen
```

For transparency
```bash
pamac install picom
```

For better status bar
```bash
pamac install ttf-font-awesome ttc-monocraft polybar
```

For better sound
```bash
pamac install easyeffects lsp-plugins-lv2 calf
```

Browsers
```bash
pamac install brave-browser
pamac build zen-browser-avx2-bin
```
Note: Zen Browser has a special package for newer CPUs, including my Razer Blade one.

For rounded borders on i3 & Picom
1. Git clone [xborder](https://github.com/deter0/xborder) & follow Usage section on the README. 
2. Install `libwnck3`, as its a dependency.
3. `xborders` will run without issues now.

For installing python dependencies through `pip` on Arch Linux, use the following commands:
```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```
Note: See [this Stack Overflow thread](https://stackoverflow.com/questions/75602063/pip-install-r-requirements-txt-is-failing-this-environment-is-externally-mana) for more context.

## Set Multi Monitor layout

In order to set up 2 monitors, use the below query to get the current setup
```bash
xrandr --query
```

From the above query, extract the information about monitors and use it to update\
the below command and run it to setup the required monitor setup.
```bash
xrandr --output eDP-1 --mode 1920x1080 --pos 0x480 --rate 144.00 --scale 1.00 --output DP-1-0.2 --primary --mode 2560x1440 --pos 1920x120 --rate 59.95 --scale 1.00 --output DP-1-0.3 --mode 1920x1080 --pos 4480x0 --scale 1.00 --rotate right
```
Note: The actual names of Monitors will change (for e.g., DP-1-0.2 may become DP-4)
