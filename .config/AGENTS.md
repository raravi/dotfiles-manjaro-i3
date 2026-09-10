# Linux Configuration Map — ~/.config

Keeps an agent grounded when modifying this user's dotfiles. Read me first.

Last verified: 2026-09-09

## Layout overview

| Path | Purpose |
|------|---------|
| `i3/config` | i3 wm config; keybindings, workspaces, autostart |
| `i3/keys-remap.sh` | key remapping (CapsLock→Super/Esc, Left Shift→Ctrl) |
| `i3/scripts/` | custom scripts — `monitor-layout.sh`, `startup.sh`, `wallpaper-apply.sh` |
| `i3/layouts/` | saved workspace layouts (1, 3, 5) |
| `i3/blocklets/` | menu scripts (e.g. `shutdown_menu`) |
| `polybar/` | bar: `launch.sh` + `config.ini` |
| `xborder/` | border daemon (upstream clone of deter0/xborder) |
| `picom/` | compositor config (`picom.conf`) |
| `alacritty/` | terminal config + themes |
| `rofi/` | launcher config + themes (`config-dmenu.rasi` used by `shutdown_menu`) |
| `deadd/` | notification daemon config (`deadd.yml`, `deadd.css`) + whatsapp parser |
| `nitrogen/` | wallpaper restore; `wallpapers.conf` per-monitor mapping |
| `nvim/` | neovim config |
| `Install.md` | first-install package list |
| `Keyboard.md` | key remaps + app shortcuts |
| `TODO.md` | persistent task list for tracking current issues in dotfiles |

`discord/settings.json` and `easyeffects/output/` are tracked app settings.

## Key facts / gotchas

- **Mod key is Super (Mod4)**; `i3/keys-remap.sh` maps CapsLock→Super (tap→Escape via `xcape`) and **Left Shift→Left Control** (`xmodmap keycode 50`). See `Keyboard.md`.
- **Monitor names change with the dock** — verify with `xrandr --query` before hardcoding. Current:
  `eDP-1` (laptop, 1920x1080@144), `HDMI-1-0` (ultrawide 3440x1440, primary), `DP-1-0` (portrait 1440p, rotated right).
- **Screen layout** is managed by `i3/scripts/monitor-layout.sh` (`auto|single|multi|all|cycle`):
  - `auto` runs at boot and reload through `exec_always`.
  - `Mod+Shift+m` runs `cycle`: single -> multi -> all -> single.
  - `single` = laptop eDP-1 only.
  - `multi` = HDMI ultrawide primary + DP portrait, with eDP-1 off.
  - `all` = eDP-1 left of HDMI-1-0, with DP-1-0 on the right:
    - eDP-1: 1920x1080@144 at 0x1320
    - HDMI-1-0: 3440x1440 primary at 1920x960
    - DP-1-0: 2560x1440 rotated right at 5360x0
  - `multi` and `all` require both external monitors.
  - The script restarts polybar, xborders, key remapping, and wallpapers after layout changes.
  - Layout settling uses a 1.5s initial delay plus polling for up to 4.5s, then fails open.
- **Startup race fix**: `i3/scripts/startup.sh` runs once at login through plain `exec`.
  It waits for the display layout, appends workspace layouts 1/3/5, then launches Spotify,
  four Alacritty instances, Brave, Notion, and Discord. It is not re-run on i3 reload.
  Logs go to `/tmp/i3-startup.log`; overrides are `STARTUP_TIMEOUT`, `STARTUP_POLL`,
  `STARTUP_NO_APPS=1`, and `STARTUP_LOG`.
- **Per-screen wallpapers**: `i3/scripts/wallpaper-apply.sh` rebuilds `nitrogen/bg-saved.cfg`
  from the live `xrandr --listmonitors` order and maps connectors through
  `nitrogen/wallpapers.conf`, then runs `nitrogen --restore` in the foreground.
  Logs go to `/tmp/wallpaper-apply.log`. The nitrogen restore command in `i3/config`
  is intentionally commented out because layout setup performs the restore afterward.
- **Workspace and application assignments**:
  - Workspaces 1-2 -> eDP-1
  - Workspaces 3-4 -> primary
  - Workspaces 5-6 -> DP-1-0
  - Notion -> workspace 1
  - Discord -> workspace 5
- `i3-msg reload` re-runs every `exec_always`, including `monitor-layout.sh auto`, which can override a manual `single` layout when both externals are docked.
- **Notifications**: `deadd-notification-center` is the daemon; `notify-send` is the client used by `monitor-layout.sh` (guarded with `command -v`). Toggle the center with `Mod+n`.
- Lock screen: `xss-lock` → `betterlockscreen -l blur` (blur + dim). Lock wallpaper cache
  lives under `~/.cache/betterlockscreen/` — re-run `betterlockscreen -u <wallpaper>` to refresh it
  (currently `~/Pictures/Walls/apex_octane.jpg`). Used by suspend and the shutdown menu's Lock action.
- Live anomaly (2026-09-05): two `deadd-notification-center` instances run (one from i3 `exec_always`, one D-Bus-activated by systemd --user). Don't assume which is "the" daemon.

## xborder gotcha

`xborder/` is a full upstream git clone (`deter0/xborder` v3.4) with its own `.git` and `.venv`.
Only `launch.sh` + `config.json` are user files (tracked in the dotfiles repo, untracked in the clone).
Never `config add .config/xborder/` wholesale — the nested `.git` gets added as a gitlink. Add files individually.
`launch.sh` runs the system `/bin/python3`, not the clone's `.venv`.

## Verification

```bash
i3 -C -c ~/.config/i3/config    # validate i3 config
i3-msg reload                   # live-reload i3 (re-runs exec_always!)
bash -n ~/.config/i3/scripts/monitor-layout.sh
bash -n ~/.config/i3/scripts/startup.sh
bash -n ~/.config/i3/scripts/wallpaper-apply.sh
polybar --list-monitors
xrandr --query                  # current display layout
pgrep -a polybar; pgrep -a xborders
```

Polybar logs to `/tmp/polybar.log`.

## Repo state

- Dotfiles are versioned with a **bare-repo setup** (`~/.myconfig`), per the Atlassian method documented in `~/README.md`.
- The `config` alias is defined **only in `~/.zshrc`**; in bash/non-interactive shells use the full form:
  `git --git-dir=$HOME/.myconfig --work-tree=$HOME <cmd>`
- **New files are added manually, one at a time** (`config add <path>`); never `config add -A` or whole directories.
  Untracked files are intentionally hidden from `config status` (`status.showUntrackedFiles=no`).
- e.g. `config status`, `config diff -- ~/.config/i3/config`, `config add ~/.config/i3/config && config commit`.
