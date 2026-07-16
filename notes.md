# Notes

Running list of ideas and things to revisit later, not a spec.

## Future Walker Menu Ideas

Small `bin/cachy-*` scripts that wrap some system capability and surface it as a themed, searchable Walker dmenu - same pattern as `cachy-menu` and `cachy-keybinds`.

Already discussed:
- Wi-Fi picker (wraps `nmcli`, replaces the `nm-connection-editor` GUI for quick connects)
- Bluetooth picker (wraps `bluetoothctl`, same idea)
- systemd user-service control menu (list services → restart/status/logs)
- `pass`-style password menu (classic "passmenu" pattern, only relevant if a password-store CLI is in use)
- SSH host launcher (parses `~/.ssh/config` `Host` entries, opens a floating terminal already connected)
- Emoji/glyph picker (types the selection via `wtype`)
- Project jumper (lists dirs under a projects folder, opens a terminal or editor there)
- Recent-files jump (track last N files opened via `launch-editor`, surface in a menu)
- Cheatsheet/notes search (fuzzy-search a personal markdown cheatsheet, show matched section)

More:
- Man-page fuzzy search (search local man pages by name/description, open the match in a floating terminal)
- systemd journal/log viewer (pick a service, tail/search its recent journal entries in a floating terminal)
- Display/monitor profile switcher (surface DMS's own `displayProfiles`/`niriOutputSettings` as a quick-switch menu, relevant once multi-monitor is in play)
- "Which package owns this file" lookup (wraps `pacman -Qo`)
- GitHub PR/issue quick-glance (wraps `gh pr list`/`gh issue list`)

Pick one and I'll build it the same way as `cachy-keybinds` (small parsing/wrapper script + a `binds.kdl` entry).
