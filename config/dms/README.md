# DMS settings

`settings.json` and `themes/` are a snapshot of DMS's own settings
(`~/.config/DankMaterialShell/settings.json` and its `themes/` folder) - copied
here so a fresh install reproduces the current theme/font/cursor/border-radius
choices instead of needing to re-click through DMS's Settings UI every time.

install.sh symlinks these specifically into `~/.config/DankMaterialShell/`
(not the generic `config/<name>` -> `~/.config/<name>` loop, since DMS's real
config dir isn't named `dms`).

To refresh this snapshot after changing something in DMS's Settings UI:

```sh
cp ~/.config/DankMaterialShell/settings.json config/dms/settings.json
cp -r ~/.config/DankMaterialShell/themes/* config/dms/themes/   # if you added/edited a theme
git add config/dms && git commit -m "Update DMS settings snapshot" && git push
```

Deliberately not tracked (DMS regenerates these itself, and/or they're
runtime state, not settings): `~/.local/state/DankMaterialShell/*` (session
state, notepad scratch content, app-usage stats), `.firstlaunch` and
`.changelog-*` marker files, and the per-app "matugen" theme integration
files DMS writes into other apps' config dirs (`dank-theme.toml`,
`dank-colors.css`, etc - see `.gitignore`).
