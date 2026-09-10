# TODO

## Issue entry structure

Use this structure for each issue:

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

- [ ] ISSUE 1: Keep Alacritty font scale consistent across monitors.
  - **Status:** Fix applied; stability under monitoring.
  - **Action:** Continue monitoring new Alacritty windows after fresh logins and monitor-mode switches. Mark `[x]` only after monitoring confirms no regression.
  - **Original issue:** Alacritty windows became larger when switching from single-monitor mode to multi-monitor mode.
  - **Likely diagnosis:** Alacritty/winit was applying different per-monitor DPI scale factors as windows moved between the laptop and external displays.
  - **Changes done:** Set `WINIT_X11_SCALE_FACTOR=1` in the i3 terminal binding and `startup.sh`.
  - **Verified:** New Alacritty windows retain a consistent font size across monitor modes after adjusting the configured font size.
  - **Rollback:**

- [ ] ISSUE 2: Improve runtime `DP-1-0` dock detection.
  - **Status:** Not yet fixed; investigate after confirming Issue 3 remains stable. Keep this open until runtime dock reconnection and DP detection are reliable.
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
  - **Status:** Fix applied; stability under monitoring.
  - **Action:** Continue testing cold boots and reboots with the dock connected; report any failure. Mark `[x]` only after several boots pass without the boot-screen issue recurring.
  - **Original issue:** After some logins, the external monitors remained on the Manjaro boot/loading screen while only `eDP-1` was available to Xorg/i3.
  - **Likely diagnosis:** NVIDIA DRM KMS was not initialized early or consistently enough for SDDM/Xorg to claim the dock-connected outputs. In the failed boot, Xorg reported `Failed to acquire modesetting permission`, exposed only the Intel provider, and left the external displays on the boot framebuffer.
  - **Changes done:**
    - Backed up `/etc/default/grub` with `sudo cp /etc/default/grub /etc/default/grub.before-nvidia-kms`.
    - Added `nvidia_drm.modeset=1` to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`.
    - Regenerated GRUB with `sudo grub-mkconfig -o /boot/grub/grub.cfg`.
    - No initramfs rebuild was needed because this only changed the kernel command line and the temporary boot already loaded the module successfully.
    - Enabled NVIDIA DRM KMS early enough for SDDM/Xorg to claim the dock-connected outputs.
  - **Verified:** `NVIDIA-G0`, `HDMI-1-0`, and `DP-1-0` appear correctly after reboot, with no Xorg modesetting failure.
  - **Rollback:**
    - **Temporary fallback:** Remove `nvidia_drm.modeset=1` from the GRUB entry by pressing `e`, then boot with `Ctrl+X` or `F10`.
    - **Permanent rollback:** Restore `/etc/default/grub.before-nvidia-kms` if available, run `sudo grub-mkconfig -o /boot/grub/grub.cfg`, and reboot.

