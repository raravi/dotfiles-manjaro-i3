# TODO

## Issue entry structure

Use this structure for each issue:

- [ ] ISSUE N: Title
  - **Status:** ...
  - **Action:** ...
  - **Original issue:** ...
  - **Changes done:** ...
  - **Verified:** ...
  - **Rollback:**
    - **Temporary fallback:** ...
    - **Permanent rollback:** ...

## Multi-monitor setup

- [x] ISSUE 1: Keep Alacritty font scale consistent across monitors.
  - Set `WINIT_X11_SCALE_FACTOR=1` in the i3 terminal binding and `startup.sh`.
  - Continue monitoring after fresh logins.

- [ ] ISSUE 2: Improve runtime `DP-1-0` dock detection.
  - Address cases where `DP-1-0` remains disconnected after the dock is connected; reconnecting may fix the normal runtime case, but does not fix the boot-framebuffer case described in Issue 3.
  - Design a bounded retry or hotplug recovery path after the provider initialization issue is understood.
  - Avoid changing the layout script until the output is visible to X11.
  - Likely diagnosis: this is likely a dock/NVIDIA DisplayPort link-training or hotplug event problem, not merely a delayed xrandr query. If DP-1-0 is absent entirely, monitor-layout.sh cannot enable it; polling or `xrandr --output DP-1-0 --auto` won’t help until the connector is registered. Next time it fails, capture before reconnecting the dock:
    - `xrandr --query`
    - `xrandr --listproviders`
    - `journalctl -b -k --no-pager | grep -iE 'drm|nvidia|displayport|hotplug'`

- [ ] ISSUE 3: Verify permanent NVIDIA DRM KMS stability across multiple boots.
  - **Status:** Fix works on one boot, but stability is not yet confirmed. Keep this open until several cold boots and reboots pass without the external monitors getting stuck on the boot screen.
  - **Action:** Continue testing cold boots and reboots with the dock connected. Report any failure; mark `[x]` only after stability is confirmed.
  - **Original issue:** After some logins, the external monitors remained on the Manjaro boot/loading screen while only `eDP-1` was available to Xorg/i3.
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

