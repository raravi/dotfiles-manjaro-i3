# Linux Configuration Knowledge Base — ~/.config

Deep-dive investigation write-ups, one entry per investigation. Kept out of
AGENTS.md to keep the map lean — read the relevant entry before touching the
affected files. AGENTS.md carries one-line pointers to each entry.

Every entry follows the same template; include a section only when it has content:

```markdown
## <Topic> (<date>)

**Area**: files/systems affected
**Status**: resolved | workaround in place | open

### Symptom
### Investigation
### Root cause
### Resolution / workarounds
### Dead ends
### Proposed improvements
```

---

## Electron GPU & picom (2026-09-16)

**Area**: `i3/scripts/startup.sh`, `picom/picom.conf`, Chromium/Electron apps (Notion, Discord, Brave)
**Status**: resolved — VAAPI flags pinned, `picom.conf` tuned, gotchas documented

### Symptom

- Uncertainty whether the removed Electron GPU flags still mattered (app launch time / video).
- Chromium apps feel sluggish after compositor restarts; GPU processes behave erratically.
- Discord hovers/scrolls spike `intel_gpu_top` Render/3D (~80%) — suspicion it was picom's fault.

### Investigation

- `strings` on the app binaries + an electron41 `app.getGPUFeatureStatus()` probe (bare: `video_decode` already default-on, `video_encode` off; with the flags: both on).
- Differential test for engine-load questions: `pkill picom`, re-test, restart picom — a spike persisting without picom is app-side. Per-process view in `sudo intel_gpu_top` names the exact consumer under each engine. Compare the suspect app's renderer cmdline against Brave's (reference Chromium on this box).

### Root cause

- `--disable-features=UseOzonePlatform` and `--use-gl=desktop` are dead (feature removed in Chromium M111; GL goes through ANGLE). `VaapiVideoDecoder` is vestigial — the real Linux VAAPI gates are `AcceleratedVideoDecodeLinuxGL`, `AcceleratedVideoDecodeLinuxZeroCopyGL`, `AcceleratedVideoEncoder`.
- `pkill picom` while Discord/Notion/Brave are running can crash the app's GPU process; Chromium then silently downgrades that session to software compositing and never self-recovers.
- Discord's hover/scroll spikes are its own damage pattern — the UI repaints large regions per pointer move (Brave shows the same effect at ~20–40%); Xorg's pixmap-upload path is the irreducible cost.

### Resolution / workarounds

- All three Linux VAAPI gates pinned in startup.sh, Brave-style; do not re-add the removed flags.
- After every picom restart, expect the software-compositing downgrade; restart the app, not the compositor. Check: `tr '\0' '\n' </proc/<renderer-pid>/cmdline | grep disable-gpu-compositing`.
- Keep `picom.conf` as-is unless picom internals change.

### Dead ends

- Tested and reverted as measured no-ops: `vsync`, blur-strength 4→2, EGL backend; `glx-no-rebind-pixmap` (deprecated no-op in picom v13).
- Blur-exclude + 100% opacity for discord/notion tried and reverted at user request — no measurable gain (both windows are fully opaque anyway).

---

## USB-C hub / DP alt-mode failure (2026-09-16)

**Area**: USB-C hub (keyboard/mouse/webcam + portrait monitor `DP-1-0`), boot-time monitor detection
**Status**: workaround in place — physical replug preferred by user; boot-notify unimplemented

### Symptom

- On some boots the portrait monitor (`DP-1-0`, hanging off the USB-C hub) is missing while the hub's USB peripherals (keyboard/mouse/webcam) still work — the hub came up **USB2-only** and the DP alt-mode was never established. In this failure mode `HDMI-1-0` (directly wired to the laptop, not via the hub) stays connected.
- Not to be confused with the separate **boot-framebuffer** failure (externals stuck on the Manjaro boot screen; NVIDIA DRM KMS/SDDM init — tracked in ISSUES.md): a hub replug does not apply there.
- Quick detection: `lsusb -d 2109:0103` (billboard present) + bus 2 empty + `xrandr` shows `DP-1-0 disconnected`.

### Investigation

- Topology via sysfs/lsusb: the hub = USB2 tree `1-11` on the chipset xHCI (`0000:00:14.0`) — `1-11.2` Terminus sub-hub holds the 2.4G keyboard (`1-11.2.2`) and C920 webcam (`1-11.2.3`), `1-11.4` RTS5411 sub-hub holds the mouse (`1-11.4.1`) and EPOMAKER (`1-11.4.2`); its USB3 half would appear on bus 2.
- The dock (ASIX ethernet + NS1081 reader) is a separate USB3-only tree `6-1`/`6-1.4` on the Titan Ridge xHCI (`0000:3d:00.0`, buses 5/6); `boltctl` is empty (dock runs USB3 fallback, no TB authorization). `HDMI-1-0`/`DP-1-0` sit on the NVIDIA provider; `1-14` is internal Bluetooth, not a dock device.
- The VIA **billboard** device `1-11.2.4` (`2109:0103`) is enumerated during bad boots — per USB-IF spec billboards only appear when alt-mode negotiation failed, and they vanish on healthy boots.
- `/sys/class/typec/` is empty, no `intel_pmc_mux`; i2c bus 6 is just the PCH SMBus (SPD/`jc42`/dummy clients, no PD chip); the `ALASKA TbtTypeC` SSDT is consumed by BIOS SMM.

### Root cause

- DP alt-mode/PD is negotiated at the USB-C connector, *below* the USB tree, and on this laptop it is firmware-only. This CML-era design predates the kernel typec-class, so there is no software reset for the connector state machine — only SMM-triggered events (physical attach/detach, S3 resume) re-run PD/alt-mode.
- On bad boots the alt-mode entry is lost in the race between PD negotiation, SMM mux programming, and the late-loading NVIDIA driver — and nothing retries it, because as far as PD is concerned the link is up.

### Resolution / workarounds

- Physical hub replug — user's preferred fix (fastest, always works).
- **Suspend/resume** also re-runs the firmware mux/PD init. Hands-free variant: arm `echo "+30" | sudo tee /sys/class/rtc/rtc0/wakealarm`, then `systemctl suspend` (allowed without password for an active session; only the betterlockscreen session lock returns, and only eDP-1 is guaranteed after wake).
- Software replug of the USB subtree only (peripherals, **not** the monitor): `echo 0 | sudo tee /sys/bus/usb/devices/1-11/authorized`, `sleep 1`, `echo 1 | sudo tee /sys/bus/usb/devices/1-11/authorized`. The `1-11` path is port-based, so it survives resets and is safe to script; peripherals drop ~1–2 s, X re-grabs them.

### Dead ends

- `uhubctl` port power — not installed; xHCI root ports can't cut Type-C VBUS anyway.
- PCI remove/rescan of the xHCI — doesn't redo PD; on `00:14.0` it also kills internal camera/BT.
- `boltctl` deauthorize/authorize — no TB device to deauthorize (dock runs USB3 fallback).
- Binding a PD-controller driver — no PD controller is visible to the kernel on this board.

### Proposed improvements

- Boot-time check in `monitor-layout.sh` or `startup.sh`: billboard present + `DP-1-0` disconnected → `notify-send` "dock alt-mode failed, replug needed".
