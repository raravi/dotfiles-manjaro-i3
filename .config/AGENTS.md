# Linux Configuration Map — ~/.config

Keeps an agent grounded when modifying this user's dotfiles. Read me first.

Last verified: 2026-09-07

## Layout overview

| Path | Purpose |
|------|---------|
| `i3/config` | i3 wm config; keybindings, workspaces, autostart |
| `i3/keys-remap.sh` | key remapping (CapsLock→Super/Esc, Left Shift→Ctrl) |
| `i3/scripts/` | custom scripts — `monitor-layout.sh`, `wallpaper-apply.sh` |
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

`discord/settings.json` and `easyeffects/output/` are tracked app settings.

## Key facts / gotchas

- **Mod key is Super (Mod4)**; `i3/keys-remap.sh` maps CapsLock→Super (tap→Escape via `xcape`) and **Left Shift→Left Control** (`xmodmap keycode 50`). See `Keyboard.md`.
- **Monitor names change with the dock** — verify with `xrandr --query` before hardcoding. Current:
  `eDP-1` (laptop, 1920x1080@144), `HDMI-1-0` (ultrawide 3440x1440, primary), `DP-1-0` (portrait 1440p, rotated right).
- **Screen layout** is managed by `i3/scripts/monitor-layout.sh` (`auto|single|multi|all|cycle`):
  - Modes
    - `auto` at boot/reload (`exec_always`); `Mod+Shift+m` runs `cycle` (single → multi → all → single).
    - `single` = laptop eDP-1 only. `multi` = docked (HDMI ultrawide primary + DP portrait on the right), eDP off.
    - `all` = laptop left of ultrawide, geometry:
      - `eDP-1 1920x1080@144 at 0x1320`, `HDMI-1-0 primary 3440x1440 at 1920x960`, `DP-1-0 2560x1440 (rotate right) at 5360x0`.
    - `multi`/`all` require **both** HDMI-1-0 and DP-1-0 connected (`both_externals_present`); the script only passes
    - `--output` flags for outputs that exist.
  - It restarts **polybar + xborders** after every change — do not remove that, or bars/borders die on switch (real past bug).
  - Cycle needs ~1.5s to settle after `xrandr` before relaunching polybar, or you get "Monitor not found".
- **Per-screen wallpapers**: `i3/scripts/wallpaper-apply.sh` (called at the end of every `monitor-layout.sh`
  run) rebuilds `nitrogen/bg-saved.cfg` from the *live* `xrandr --listmonitors` order and
  maps each head's connector to a wallpaper via `nitrogen/wallpapers.conf` (`eDP-1=` / `HDMI-1-0=` / `DP-1-0=`
  lines), then runs `nitrogen --restore`. Nitrogen keys `[xin_N]` by Xinerama head order, so the config must be
  regenerated per layout (order differs between single/multi/all). The `nitrogen --restore &` runs once on i3 boot;
  then the multi monitor check `exec_always monitor-layout.sh auto` calls `nitrogen --restore &` rewrites it a moment later.
- **Workspace→output mapping** (`i3/config`): 1–2→`eDP-1`, 3–4→`primary`, 5–6→`DP-1-0`. In multi mode `eDP-1` is **off**, so workspaces 1/2 fall back onto `HDMI-1-0` — not a bug.
- **Startup** (login only, plain `exec`): appends layouts 1/3/5 and opens spotify, 4× alacritty, brave, notion, discord.
- `i3-msg reload` re-runs **every** `exec_always` — including `monitor-layout.sh auto`, which overrides a manual `single` toggle whenever both externals are docked.
- **Notifications**: `deadd-notification-center` is the daemon; `notify-send` is the client used by `monitor-layout.sh` (guarded with `command -v`). Toggle the center with `Mod+n`.
- **Known stale lines in `i3/config`** (do not "fix"): the `dex` autostart (dex not installed, autostart dir empty) and `$refresh_i3status` (i3status not running; polybar is used).
- Live anomaly (2026-09-05): two `deadd-notification-center` instances run (one from i3 `exec_always`, one D-Bus-activated by systemd --user). Don't assume which is "the" daemon.
- Clutter (untracked, safe to delete): `i3/layouts/*.old`, `i3/layouts/workspace-3.json.test.new`, empty `xborder1/`.

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
