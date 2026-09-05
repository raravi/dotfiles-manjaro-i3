# Linux Configuration Map — ~/.config

Keeps an agent grounded when modifying this user's dotfiles. Read me first.

## Layout overview

| Path | Purpose |
|------|---------|
| `i3/config` | i3 wm config; keybindings, workspaces, autostart |
| `i3/scripts/` | custom scripts — `monitor-layout.sh`, `keys-remap.sh` |
| `i3/layouts/` | saved workspace layouts (1, 3, 5) |
| `i3/blocklets/` | menu scripts (e.g. `shutdown_menu`) |
| `polybar/` | bar: `launch.sh` + `config.ini` |
| `xborder/` | border daemon: `launch.sh` + `config.json` |
| `picom/` | compositor config (`picom.conf`) |

## Key facts / gotchas

- **Mod key is Super (Mod4)**; `keys-remap.sh` remaps CapsLock to Super (tap → Escape) and juggles Ctrl/Shift.
- **Monitor names change with the dock** — verify with `xrandr --query` before hardcoding. Current:
  `eDP-1` (laptop, 1920x1080@144), `HDMI-1-0` (ultrawide 3440x1440, primary), `DP-1-0` (portrait 1440p, rotated right).
- **Single/multi layout** is managed by `i3/scripts/monitor-layout.sh` (`auto|single|multi|toggle`):
  `auto` at boot/reload (`exec_always`), `Mod+Shift+m` toggles. It restarts **polybar + xborders** after every change —
  do not remove that, or bars/borders die on toggle (real past bug).
- Toggle needs ~0.5s settle after `xrandr` before relaunching polybar, or you get "Monitor not found".
- Notifications: `notify-send` works as a fallback for `deadd-notification-center`.

## Verification

```bash
i3 -C -c ~/.config/i3/config    # validate i3 config
i3-msg reload                   # live-reload i3
bash -n ~/.config/i3/scripts/monitor-layout.sh
polybar --list-monitors
xrandr --query                  # current display layout
pgrep -a polybar; pgrep -a xborders
```

## Repo state

- Dotfiles are versioned with a **bare-repo setup** (`~/.myconfig`), per the Atlassian method documented in `~/README.md`.
- Use the `config` alias (`/usr/bin/git --git-dir=$HOME/.myconfig --work-tree=$HOME`), **not** plain `git`.
  e.g. `config status`, `config diff -- ~/.config/i3/config`, `config add ... && config commit`.