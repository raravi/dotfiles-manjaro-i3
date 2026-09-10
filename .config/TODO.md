# TODO

## Multi-monitor setup

- [x] ISSUE 1: Keep Alacritty font scale consistent across monitors.
  - Set `WINIT_X11_SCALE_FACTOR=1` in the i3 terminal binding and `startup.sh`.
  - Continue monitoring after fresh logins.

- [ ] ISSUE 2: Improve runtime `DP-1-0` dock detection.
  - Address cases where the dock is connected but `DP-1-0` remains disconnected, and reconnecting the dock fixes it.
  - Design a bounded retry or hotplug recovery path after the provider initialization issue is understood.
  - Avoid changing the layout script until the output is visible to X11.
  - Likely diagnosis: this is likely a dock/NVIDIA DisplayPort link-training or hotplug event problem, not merely a delayed xrandr query. If DP-1-0 is absent entirely, monitor-layout.sh cannot enable it; polling or xrandr --output DP-1-0 --auto won’t help until the connector is registered. Next time it fails, capture before reconnecting the dock:
    - xrandr --query
    - xrandr --listproviders
    - journalctl -b -k --no-pager | grep -iE 'drm|nvidia|displayport|hotplug'

- [ ] ISSUE 3: Investigate boot-time NVIDIA/Xorg provider initialization.
  - Capture failed-boot Xorg, SDDM, kernel, provider, and `nvidia_drm` modesetting diagnostics.
  - Determine why Xorg exposes only `eDP-1` while the dock outputs retain the boot framebuffer.
  - Likely diagnosis: This is the same underlying GPU/dock issue, but earlier in boot:
    - The external screens are still showing the boot framebuffer/splash, not an active i3/X11 desktop.
    - Xorg/SDDM starts using the Intel modesetting device, so only eDP-1 is exposed to i3.
    - The NVIDIA provider fails during Xorg startup. The Xorg log contains: "NVIDIA(GPU-0): Failed to acquire modesetting permission. NVIDIA(G0): Failing initialization of X screen"
    - At the same time, DRM reports the dock outputs as connected, but `xrandr --listproviders` exposes only the Intel provider.
    - Therefore `monitor-layout.sh` cannot fix this: the DP/HDMI outputs are not available in X11 yet. Reconnecting the dock triggers a new hotplug/provider initialization, which is why they then appear.
    - The likely fix area is NVIDIA DRM modesetting/early initialization with SDDM, especially ensuring `nvidia_drm` modesetting is enabled before Xorg starts. We should investigate that separately rather than modify the i3 layout script.

