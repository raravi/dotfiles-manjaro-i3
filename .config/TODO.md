# TODO

## Issue entry structure

Use this structure for each issue.

Status values used here: `Not started`, `Fixed`, `Monitoring`, `Closed`.

Leave a field empty if it does not apply (e.g. `Action` for a fixed issue).

- [ ] ISSUE N: Title
  - **Status:** ...
  - **Action:** ...
  - **Original issue:** ...
  - **Likely diagnosis:** ...
  - **Changes done:** ...
  - **Verified:** ...
  - **Rollback:**
    - **Temporary fallback:** ...
    - **Permanent rollback:** ...

## Multi-monitor setup

- [x] ISSUE 1: Keep Alacritty font scale consistent across monitors.
  - **Status:** Fixed.
  - **Action:**
  - **Original issue:** Alacritty windows became larger when switching from single-monitor mode to multi-monitor mode.
  - **Likely diagnosis:** Alacritty/winit was applying different per-monitor DPI scale factors as windows moved between the laptop and external displays.
  - **Changes done:** Set `WINIT_X11_SCALE_FACTOR=1` in the i3 terminal binding and `startup.sh`.
  - **Verified:** New Alacritty windows retain a consistent font size across monitor modes after adjusting the configured font size.
  - **Rollback:**

- [ ] ISSUE 2: Improve runtime `DP-1-0` dock detection.
  - **Status:** Not started.
  - **Action:** Next time `DP-1-0` remains disconnected, capture diagnostics before reconnecting the dock:
    - `xrandr --query`
    - `xrandr --listproviders`
    - `journalctl -b -k --no-pager | grep -iE 'drm|nvidia|displayport|hotplug'`
  - **Original issue:** After a cold boot, `DP-1-0` can sometimes remain disconnected even though the dock is connected. Reconnecting may fix the normal runtime case, but does not fix the boot-framebuffer case described in Issue 3.
  - **Likely diagnosis:** This is likely a dock/NVIDIA DisplayPort link-training or hotplug event problem, not merely a delayed `xrandr` query. If `DP-1-0` is absent entirely, `monitor-layout.sh` cannot enable it; polling or `xrandr --output DP-1-0 --auto` will not help until the connector is registered.
  - **Changes done:**
  - **Verified:**
  - **Rollback:**

- [ ] ISSUE 3: Verify permanent NVIDIA DRM KMS stability across multiple boots.
  - **Status:** Monitoring.
  - **Action:** Continue testing cold boots and reboots with the dock connected; report any failure. If it recurs, test the Plymouth-disabled boot (see Proposed fix below) before trying any other mitigation. Mark `[x]` only after several boots pass without the boot-screen issue recurring.
  - **Original issue:** After some logins, the external monitors remained on the Manjaro boot/loading screen while only `eDP-1` was available to Xorg/i3.
  - **Likely diagnosis:** NVIDIA DRM KMS was not initialized early or consistently enough for SDDM/Xorg to claim the dock-connected outputs. In the failed boot, Xorg reported `Failed to acquire modesetting permission`, exposed only the Intel provider, and left the external displays on the boot framebuffer.
  - **Changes done:**
    - Backed up `/etc/default/grub` with `sudo cp /etc/default/grub /etc/default/grub.before-nvidia-kms`.
    - Added `nvidia_drm.modeset=1` to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`.
    - Regenerated GRUB with `sudo grub-mkconfig -o /boot/grub/grub.cfg`.
    - No initramfs rebuild was needed because this only changed the kernel command line and the temporary boot already loaded the module successfully.
    - Enabled NVIDIA DRM KMS early enough for SDDM/Xorg to claim the dock-connected outputs.
    - Proposed fix (de-prioritized, NOT yet applied): add `nvidia_drm.fbdev=0` to `GRUB_CMDLINE_LINUX_DEFAULT`. The NVIDIA GPU drives no console here (i915 owns fb0 and the VT), so its `nvidia-drmdrmfb` fb1 console could contend for DRM master at X startup. Evidence review (2026-09-11) showed `fbcon` stayed deferred and bound to i915 `fb0`, so this hypothesis is unproven; only revisit it if Plymouth is ruled out.
    - 2026-09-11 diagnosis (Plymouth): `plymouth-quit.service` (`/usr/bin/plymouth quit`) started at 15:39:01 and timed out after 20s (15:39:21); its `ExecStart` was killed by `TERM` and the service failed. `plymouth-quit-wait.service` remained stuck in `activating`. `sddm.service` declares `After=plymouth-quit.service`, but systemd `After=` does not require the unit to succeed, so SDDM started anyway the instant the timeout expired — while Plymouth still held the console/DRM master on the NVIDIA GPU. Xorg (NVIDIA(G0)) then failed with `Failed to acquire modesetting permission`. This matches the left-behind boot/loading screen on the externals.
    - Proposed fix (primary, NOT yet applied): test one boot with Plymouth disabled — remove `splash` (and optionally add `plymouth.enable=0`) from `GRUB_CMDLINE_LINUX_DEFAULT`, or `sudo systemctl mask plymouth-quit.service plymouth-quit-wait.service`. If the externals come up, keep Plymouth disabled or fix its shutdown so `plymouth quit` completes (and releases DRM) before SDDM starts. The dock and direct-HDMI findings rule out dock state as the cause: both `card1-DP-1` and `card1-HDMI-A-1` are NVIDIA outputs, and HDMI is connected directly to the laptop (not via the dock).
  - **Verified:** `NVIDIA-G0`, `HDMI-1-0`, and `DP-1-0` appeared correctly after the initial reboot, with no Xorg modesetting failure.
    - Regression on 2026-09-11 15:39: Xorg log shows `NVIDIA(GPU-0): Failed to acquire modesetting permission` / `NVIDIA(G0): Failing initialization of X screen`. The kernel had `card1-DP-1` and `card1-HDMI-A-1` connected, but X lost all NVIDIA outputs for the session, leaving the externals on the boot screen.
    - Logging out and back in did not restore the external outputs, confirming that SDDM kept the failed Xorg server alive; a full Xorg restart is required to retest initialization.
  - **Rollback:**
    - **Temporary fallback:** Remove `nvidia_drm.modeset=1` from the GRUB entry by pressing `e`, then boot with `Ctrl+X` or `F10`.
    - **Permanent rollback:** Restore `/etc/default/grub.before-nvidia-kms` if available, run `sudo grub-mkconfig -o /boot/grub/grub.cfg`, and reboot.

