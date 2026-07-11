# cachy-omarchy-dots

Dotfiles for CachyOS + Niri + DMS, built to look like Omarchy without the
Hyprland-specific tooling and opinionated bloat. Ported from an Omarchy
install (Hyprland/waybar) - see the full design plan for rationale and
what's intentionally left out.

## Prerequisites

- CachyOS installed.
- Niri and DMS - either installed yourself already (in which case skip to
  `./install.sh` below), or let `./bootstrap.sh` do it (see below).
- When installing DMS, **decline its bundled greeter** - this repo installs
  its own minimal SDDM theme.

## Install

**From a bare CachyOS box** (no yay/Niri/DMS yet):

```sh
./bootstrap.sh
```

Installs `base-devel`+`git`, builds `yay` from the AUR, then runs DMS's own
installer (`curl -fsSL https://install.danklinux.com | sh`, which installs
Niri itself) - this step is interactive, so make your own choices there -
and once that's done, hands off straight into `install.sh` for everything
else.

**If Niri and DMS are already installed:**

```sh
./install.sh
```

Idempotent - installs remaining packages (Walker, mako, swayosd, fonts,
icons, cursor), symlinks `config/*` into `~/.config`, symlinks `bin/*` onto
PATH, installs the web app installer, sets file-type associations, installs
systemd user units, installs the SDDM + Plymouth themes, and applies the
tokyo-night color theme.

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
