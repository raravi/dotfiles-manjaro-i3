# TODO

Task list for planned improvements to the dotfiles.

For tracking current issues (with diagnosis/rollback), see `ISSUES.md`.

## Structure

Use one checkbox per task, grouped by area. Add a short note after the
task if there is extra context (e.g. a decision or a dependency).

- [ ] Area/Component: Task description

## Tasks

- [x] UI: Unified palette — resolved per-component instead: rofi border/selected ring matched to xborder purple (#6b406e99, two-frame window), deadd critical cards redesigned; polybar/i3 kept original (lavender/pink and full Rosé Pine attempts reverted)
- [ ] UI: Polybar — pill modules, Unicode block meters (CPU/RAM/GPU), FA7 icon consistency, colors
- [x] UI: i3 — borders, gaps, focus/urgent colors — kept as-is (palette attempts reverted; current look with xborder + gaps approved)
- [x] UI: Rofi — search icon switched to Hack Nerd Font U+F002 (FA7 WOFF2 unusable by pango), icon padding, xborder-matched border (#6b406e99), two-frame window design
- [x] UI: deadd — critical cards (raspberry glass w/ amber corner, lavender border, light text), 14px radius, center clock accent, muted timestamps, 19px titles; buttons + regular-card gradient kept original
- [ ] UI: xborder — animated focused-window border (gradient/glow/pulse)
- [ ] UI: picom — inactive-dim on unfocused windows
