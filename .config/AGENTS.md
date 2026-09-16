# Linux Configuration Map — ~/.config

Keeps an agent grounded when modifying this user's dotfiles. Read me first.

Last verified: 2026-09-16

## Layout overview

| Path | Purpose |
|------|---------|
| `i3/config` | i3 wm config; keybindings, workspaces, autostart |
| `i3/keys-remap.sh` | key remapping (CapsLock→Super/Esc, Left Shift→Ctrl) |
| `i3/scripts/` | custom scripts — `monitor-layout.sh`, `startup.sh`, `wallpaper-apply.sh`, `spotify-notify.sh`, `media-popup.sh` |
| `i3/layouts/` | saved workspace layouts (1, 3, 5) |
| `i3/blocklets/` | menu scripts (e.g. `shutdown_menu`) |
| `polybar/` | bar: pill/original configs, `launch.sh`, and CPU/RAM/GPU scripts |
| `xborder/` | border daemon (upstream clone of deter0/xborder) |
| `picom/` | compositor config (`picom.conf`) |
| `alacritty/` | terminal config + themes |
| `rofi/` | launcher config + themes (`config-dmenu.rasi` used by `shutdown_menu`) |
| `deadd/` | notification daemon config (`deadd.yml`, `deadd.css`) + whatsapp parser |
| `nitrogen/` | wallpaper restore; `wallpapers.conf` per-monitor mapping |
| `nvim/` | neovim config |
| `Install.md` | first-install package list |
| `Keyboard.md` | key remaps + app shortcuts |
| `ISSUES.md` | persistent issue list for tracking current issues in dotfiles |
| `TODO.md` | task list for planned improvements to the dotfiles |

`discord/settings.json` and `easyeffects/output/` are tracked app settings.

## Key facts / gotchas

- **Mod key is Super (Mod4)**; `i3/keys-remap.sh` maps CapsLock→Super (tap→Escape via `xcape`) and **Left Shift→Left Control** (`xmodmap keycode 50`). See `Keyboard.md`.
- **Monitor names change with the dock** — verify with `xrandr --query` before hardcoding. Current: `eDP-1` (laptop, 1920x1080@144), `HDMI-1-0` (ultrawide 3440x1440, primary), `DP-1-0` (portrait 1440p, rotated right).
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
- **Startup race fix**: `i3/scripts/startup.sh` runs once at login through plain `exec`. It waits for the display layout, appends workspace layouts 1/3/5, then launches Spotify, four Alacritty instances, Brave, Notion, and Discord. It is not re-run on i3 reload. Logs go to `~/.config/log/i3-startup.log`; overrides are `STARTUP_TIMEOUT`, `STARTUP_POLL`, `STARTUP_NO_APPS=1`, and `STARTUP_LOG`.
- **Per-screen wallpapers**: `i3/scripts/wallpaper-apply.sh` rebuilds `nitrogen/bg-saved.cfg` from the live `xrandr --listmonitors` order and maps connectors through `nitrogen/wallpapers.conf`. It applies each mapped wallpaper explicitly with Nitrogen's per-head mode, retrying up to 5 times with a 1-second delay for slow external monitors. Diagnostic messages go to `STARTUP_LOG` (default `~/.config/log/i3-startup.log`), while Nitrogen output goes to `/tmp/wallpaper-apply.log` or the `WALLPAPER_LOG` override.
- **Workspace and application assignments**:
  - Workspaces 1-2 -> eDP-1
  - Workspaces 3-4 -> primary
  - Workspaces 5-6 -> DP-1-0
  - Notion -> workspace 1
  - Discord -> workspace 5
- **Polybar modes:** `~/.config/polybar/launch.sh pills` runs the current pill layout; `original` runs the full bar layout; `toggle` switches between them using `~/.cache/polybar-mode`. Pills are the default. `Mod+Shift+p` toggles modes. The primary bar has the tray outside the right pill; secondary bars show only battery and the audio module on the right.
  - **Pill mode - styling:** pill backgrounds use opaque Rosepine theme base `#26233a`; CPU, RAM, and GPU use five-block meters. RAM shows only its meter; CPU and GPU show meter plus temperature.
  - **Audio module:** `[module/audio]` (custom/script, `tail = true`) runs `polybar/audio.sh`. Event-driven via `pactl subscribe` (sink/server/card events; no polling). With icons for different sources/sinks. Glyphs come from Hack Nerd Font; `config-original.ini` loads Hack NF as font-2 for this. One-shot render for testing: `audio.sh <sink-name>` prints once and exits.
  - **Media module:** `[module/media]` (custom/script, `tail = true`) runs `polybar/media.sh` as its own pill beside `workspaces`. Tracks ALL MPRIS players: polls at 1 Hz and renders the Playing player (play/pause action icon U+F04B/U+F04C + `artist - title`, 30-char truncation, title-only when artist is empty — browser titles have no artist, and their `Watch ` page-title prefix is stripped at capture for browser players only (`brave*`/`chromium*`/`firefox*`/… — protects non-browser "Watch …" titles), which also cleans the meta files). Polling, not `playerctl -F`: `-a -F` only follows the most-recently-updated player, so per-player events can't all be captured; polling also handles players appearing/vanishing. When nothing is Playing it dims (`%{F#707880}`) the most-recently-paused player's track. Blacklists `plasma-browser-integration` (a duplicate proxy of the same browser media as the real `brave.instance*` player). Owns the shared state dir `~/.cache/media-players/`: `order` (player names, most-recently-active first — drives picker order and the last-paused click target) and `meta/<player>` (`artist|title` lines for the picker). Clicks route through `media-popup.sh action play-pause|next|previous` (Playing → last-paused → spotify; play-pause also pauses any other Playing player, matching the popup's single-media Space). Needs `playerctl`.
- **Media popup:** `i3/scripts/media-popup.sh` — any-MPRIS flyout (chafa cover art + title/artist-album/progress bar/volume/loop/shuffle + source label), `Mod+m` → `toggle` subcommand. Two modes inferred per 1 Hz tick: control view of the explicitly picked player if any (a picker selection outranks the currently Playing player until the popup is hidden), else control view of the Playing player, and when nothing is Playing a picker listing players MRU-first (from `~/.cache/media-players/order`) with dim last-track info — `j/k`/arrows select, Enter/Space opens the control view of that player (Space there resumes, pausing any other Playing player first — single media at a time), `Tab` toggles picker from the control view, `q`/Esc hides. Floating sticky borderless Alacritty (class `media-popup`), parked in the scratchpad when hidden, FIXED 44×28 window for both modes (picker renders at the top of the window; per-mode live resizing was tried and deliberately dropped). The picked-player state (`pinned`) resets whenever the popup is hidden (inline on Esc/q, plus a per-tick visibility check that also covers `toggle` hides), so reopening always starts fresh: picker when nothing is Playing, control view of the Playing player otherwise. Missing `artUrl` (browsers) renders a dim `( no cover art )` placeholder instead of the chafa hint, and the browser `Watch ` page-title prefix is stripped from titles in both media scripts (browser players only). Styled by both the `for_window` rule in i3 config and the script's spawn branch (keep the two property lists in sync). Positioned per toggle relative to the primary output's rect (+128 from left, 64px above bottom) because i3 `move position` is absolute. `action` subcommand serves the polybar media-pill clicks. Shares the `~/.cache/spotify-art/` cache with `spotify-notify.sh` (which stays Spotify-only). Needs `playerctl`, `chafa`, `jq`. Toggle triggers: keybind only — do NOT use polybar `click-double-left`: polybar fires single-click actions on the first press of a double-click, so both would fire (play/pause + toggle). Metadata parsing in both media scripts uses `\x1f` delimiters, never `|` or tabs — browser titles contain `|` and IFS whitespace collapses empty fields in `read`.
- **Bluetooth popup:** `i3/scripts/bt-popup.sh` — same flyout pattern as media-popup (`Mod+b` → `toggle`; class `bluetooth-popup`, mark `bluetooth_popup`, `for_window` rule + spawn branch in sync). Lists paired devices via `bluetoothctl` (needs `bluez-utils`): green check = connected, dim = disconnected, battery % when the device exposes it. `j/k` or arrows select, Space toggles connect/disconnect (synchronous, blocks a few seconds while connecting), `r` removes (unpairs) the selected device with no confirmation, `Esc` hides. Renders live at 1 Hz. Device data is parsed with a `\x1f` delimiter — tab/whitespace delimiters collapse empty battery fields in `read`.
- `i3-msg reload` re-runs every `exec_always`, including `monitor-layout.sh auto`, which can override a manual `single` layout when both externals are docked.
- **Notifications**: `deadd-notification-center` is the daemon; `notify-send` is the client used by `monitor-layout.sh` (guarded with `command -v`). Toggle the center with `Mod+n`.
- **Spotify cover notifications**: `i3/scripts/spotify-notify.sh` (plain `exec` in i3 config, no dupes on reload) fires a cover-art notification on track change; only while Playing, deduped by `artist - title`. Art cached in `~/.cache/spotify-art/` keyed by Spotify image ID.
- Lock screen: `xss-lock` → `betterlockscreen -l blur` (blur + dim). Lock wallpaper cache lives under `~/.cache/betterlockscreen/` — re-run `betterlockscreen -u <wallpaper>` to refresh it (currently `~/Pictures/Walls/apex_octane.jpg`). Used by suspend and the shutdown menu's Lock action.
- **Icon fonts in rofi (pango)**: pango cannot rasterize the FA7 WOFF2 files (`/usr/share/fonts/WOFF2/fa-*.woff2`, package `woff2-font-awesome`) — FA codepoints render as pango "hexboxes" even though fontconfig lists them (`fc-list ':charset=f002'` includes FA7). Polybar is unaffected: it loads the font file directly via freetype. For rofi icon glyphs use **Hack Nerd Font** (TTF, ships the FA codepoints, e.g. U+F002 = search): set `font: "Hack Nerd Font 20"` and put the raw U+F002 character in the `str` (rofi does not support `\uXXXX` escapes in theme strings).
- Live anomaly (2026-09-05): two `deadd-notification-center` instances run (one from i3 `exec_always`, one D-Bus-activated by systemd --user). Don't assume which is "the" daemon.
- **deadd quirk**: image hints are only treated as files with a `file://` prefix — bare paths parse as icon names and land in the `.icon` widget, which `deadd.css` hides (`opacity: 0`).

## xborder gotcha

- `xborder/` is a full upstream git clone (`deter0/xborder` v3.4) with its own `.git` and `.venv`. 
  - Only `launch.sh` + `config.json` are user files (tracked in the dotfiles repo, untracked in the clone).
  - Never `config add .config/xborder/` wholesale — the nested `.git` gets added as a gitlink. Add files individually.
  - `launch.sh` runs the system `/bin/python3`, not the clone's `.venv`.

## Electron GPU & picom gotcha (2026-09-16 investigation)

- **startup.sh Electron flags** (`notion-app`, `discord`): `--disable-features=UseOzonePlatform` and `--use-gl=desktop` are dead (feature removed in Chromium M111; GL goes through ANGLE) — don't re-add. `VaapiVideoDecoder` is vestigial too; the real Linux VAAPI gates are `AcceleratedVideoDecodeLinuxGL`, `AcceleratedVideoDecodeLinuxZeroCopyGL`, `AcceleratedVideoEncoder` — all three now pinned in startup.sh, Brave-style. Verified empirically: `strings` on the app binaries + an electron41 `app.getGPUFeatureStatus()` probe (bare: video_decode already default-on, video_encode off; with the flags: both on).
- **Compositor restarts can poison Chromium GPU processes**: `pkill picom` while Discord/Notion/Brave are running can crash the app's GPU process; Chromium then silently downgrades that session to software compositing (`--disable-gpu-compositing` appears in the renderer's cmdline) and never self-recovers — a full app restart is required. Check with `tr '\0' '\n' </proc/<renderer-pid>/cmdline | grep disable-gpu-compositing`. Expect this after every picom restart; if an app feels sluggish afterwards, restart the app, not the compositor.
- **Discord hover/scroll spikes** in `intel_gpu_top` Render/3D (Xorg + picom, ~80%) are Discord's own damage pattern (its UI repaints large regions per pointer move; Brave shows the same effect at ~20-40%). Tested and reverted as measured no-ops: `vsync`, blur-strength 4→2, EGL backend; `glx-no-rebind-pixmap` is a deprecated no-op in picom v13. Blur-exclude + 100% opacity for discord/notion were also tried and reverted at user request — no measurable gain (both windows are fully opaque anyway; Xorg's pixmap-upload path is the irreducible cost). Keep `picom.conf` as-is unless picom internals change.
- Diagnosis recipe for engine-load questions: (1) differential test — `pkill picom`, re-test, restart picom; spike persisting without picom = app-side. (2) per-process view in `sudo intel_gpu_top` names the exact consumer under each engine. (3) compare the suspect app's renderer cmdline against Brave's (reference Chromium on this box).

## USB-C hub / DP alt-mode failure (2026-09-16 investigation)

- **Symptom**: on some boots the portrait monitor (`DP-1-0`, hanging off the USB-C hub) is missing, while the hub's USB peripherals (keyboard/mouse/webcam) still work — the hub came up **USB2-only** and the DP alt-mode was never established. A physical hub replug fixes it; user prefers replug over software workarounds.
- **Topology** (verified via sysfs/lsusb): the hub = USB2 tree `1-11` on the chipset xHCI (`0000:00:14.0`) — `1-11.2` Terminus sub-hub holds the 2.4G keyboard (`1-11.2.2`) and C920 webcam (`1-11.2.3`), `1-11.4` RTS5411 sub-hub holds the mouse (`1-11.4.1`) and EPOMAKER (`1-11.4.2`); its USB3 half would appear on bus 2. The dock (ASIX ethernet + NS1081 reader) is a separate USB3-only tree `6-1`/`6-1.4` on the Titan Ridge xHCI (`0000:3d:00.0`, buses 5/6); `boltctl` is empty (dock runs USB3 fallback, no TB authorization). `HDMI-1-0`/`DP-1-0` sit on the NVIDIA provider; `1-14` is internal Bluetooth, not a dock device.
- **Bad-boot signature**: the VIA **billboard** device `1-11.2.4` (`2109:0103`) is enumerated — per USB-IF spec billboards only appear when alt-mode negotiation failed, and they vanish on healthy boots. Check: `lsusb -d 2109:0103` + bus 2 empty + `xrandr` shows `DP-1-0 disconnected`.
- **Root cause**: DP alt-mode/PD is negotiated at the USB-C connector, *below* the USB tree, and on this laptop it is firmware-only — `/sys/class/typec/` is empty, no `intel_pmc_mux`, bus 6 is just the PCH SMBus (SPD/`jc42`/dummy clients, no PD chip), and the `ALASKA TbtTypeC` SSDT is consumed by BIOS SMM. This CML-era design predates the kernel typec-class, so **there is no software reset for the connector state machine** — only SMM-triggered events (physical attach/detach, S3 resume) re-run PD/alt-mode.
- **What works**:
  - Software replug of the USB subtree only (peripherals, **not** the monitor): `echo 0 | sudo tee /sys/bus/usb/devices/1-11/authorized`, `sleep 1`, `echo 1 | sudo tee /sys/bus/usb/devices/1-11/authorized`. The `1-11` path is port-based, so it survives resets and is safe to script; peripherals drop ~1–2 s, X re-grabs them.
  - Monitor recovery: physical replug, or **suspend/resume** (S3 resume re-runs the firmware mux/PD init). Hands-free variant: arm `echo "+30" | sudo tee /sys/class/rtc/rtc0/wakealarm`, then `systemctl suspend` (allowed without password for an active session; only the betterlockscreen session lock returns — and only eDP-1 is guaranteed after wake).
  - Dead ends, don't retry: `uhubctl` port power (not installed; xHCI root ports can't cut Type-C VBUS), PCI remove/rescan of the xHCI (doesn't redo PD; on `00:14.0` it also kills internal camera/BT), `boltctl` (no TB device to deauthorize).
- **Proposed, not implemented**: boot-time check in `monitor-layout.sh` or `startup.sh` — billboard present + `DP-1-0` disconnected → `notify-send` "dock alt-mode failed, replug needed".

## Verification

```bash
i3 -C -c ~/.config/i3/config    # validate i3 config
i3-msg reload                   # live-reload i3 (re-runs exec_always!)
bash -n ~/.config/i3/scripts/monitor-layout.sh
bash -n ~/.config/i3/scripts/startup.sh
bash -n ~/.config/i3/scripts/wallpaper-apply.sh
bash -n ~/.config/i3/scripts/spotify-notify.sh
bash -n ~/.config/i3/scripts/media-popup.sh
bash -n ~/.config/i3/scripts/bt-popup.sh
bash -n ~/.config/polybar/*.sh
polybar --config ~/.config/polybar/config.ini bar
polybar --config ~/.config/polybar/config-original.ini bar
polybar --list-monitors
xrandr --query                  # current display layout
pgrep -a polybar; pgrep -a xborders
```

Polybar logs to `/tmp/polybar.log`.

## Repo state

- Dotfiles are versioned with a **bare-repo setup** (`~/.myconfig`), per the Atlassian method documented in `~/README.md`.
- The `config` alias is defined **only in `~/.zshrc`**; in bash/non-interactive shells use the full form:
  `git --git-dir=$HOME/.myconfig --work-tree=$HOME <cmd>`
- **New files are added manually, one at a time** (`config add <path>`); never `config add -A` or whole directories. Untracked files are intentionally hidden from `config status` (`status.showUntrackedFiles=no`).
- e.g. `config status`, `config diff -- ~/.config/i3/config`, `config add ~/.config/i3/config && config commit`.
