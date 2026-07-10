# cachy-omarchy-dots

Dotfiles for CachyOS + Niri + DMS, built to look like Omarchy without the
Hyprland-specific tooling and opinionated bloat. Ported from an Omarchy
install (Hyprland/waybar) - see the full design plan for rationale and
what's intentionally left out.

## Prerequisites (do these yourself first)

- CachyOS installed, Niri installed, DMS installed.
- When installing DMS, **decline its bundled greeter** - this repo installs
  its own minimal SDDM theme.

## Install

```sh
./install.sh
```

Idempotent - installs remaining packages (Walker, mako, swayosd, fonts,
icons, cursor), symlinks `config/*` into `~/.config`, sets file-type
associations, installs systemd user units, installs the SDDM + Plymouth
themes, and applies the tokyo-night color theme.

## Structure

- `config/` - per-app configs, symlinked into `~/.config` by `install.sh`.
- `themes/` - curated color palettes (`colors.toml` per theme).
- `theme-engine/` - templates + `theme-set.sh`, which stamps a theme's colors
  into small per-app fragments (mirrors Omarchy's theming mechanism).
- `sddm/`, `plymouth/` - login screen and boot splash themes (branding
  replaced with a "PAMAC" placeholder - swap for something real whenever).
- `bin/` - small scripts (editor launch, window focus-or-launch, OCR capture,
  battery-only suspend) that replace Hyprland-specific Omarchy tooling.

## Known gaps

- `config/dms/` is a placeholder - DMS's actual config schema needs to be
  filled in once DMS is installed (see `config/dms/README.md`).
- Niri keybinds are intentionally left at stock defaults - configure them
  through DMS's own settings panel.
