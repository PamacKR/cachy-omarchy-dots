#!/usr/bin/env bash
# Bring a fresh CachyOS + Niri + DMS box to the "Omarchy look".
#
# Assumes you've already installed Niri and DMS yourself (declining DMS's own
# bundled greeter - we install our own SDDM theme below). This script installs
# everything else: Walker, mako, swayosd, fonts/icons/cursor, theming engine,
# file associations, systemd units, and the SDDM/Plymouth themes.
#
# Idempotent: safe to re-run.
set -euo pipefail

CACHY_DOTS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHY_DOTS_INSTALLED="$HOME/.local/share/cachy-dots"

log() { echo -e "\n==> $*"; }

# --- Sanity checks ----------------------------------------------------------

log "Checking for Niri and DMS..."
command -v niri >/dev/null 2>&1 || {
  echo "error: niri not found. Install Niri yourself first, then re-run." >&2
  exit 1
}
if ! command -v dms >/dev/null 2>&1 && [[ ! -x /usr/bin/dms ]]; then
  echo "warning: could not find a 'dms' binary. If DMS is installed under a" >&2
  echo "different command name, that's fine - just make sure config/systemd/user/dms.service" >&2
  echo "and config/niri/config.kdl point at the right binary before relying on it." >&2
fi

# --- Packages ----------------------------------------------------------------

log "Installing packages via pacman..."
sudo pacman -S --needed --noconfirm \
  walker elephant mako alacritty imv evince mpv swayosd tesseract tesseract-data-eng \
  ttf-jetbrains-mono-nerd papirus-icon-theme breeze polkit-gnome swaybg swayidle grim slurp wl-clipboard jq

# yay/AUR helper fallback for anything not in the official repos on your setup:
if command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm walker-bin elephant-bin 2>/dev/null || true
fi

# --- Symlink dotfiles --------------------------------------------------------

log "Linking cachy-omarchy-dots into ~/.local/share/cachy-dots..."
mkdir -p "$(dirname "$CACHY_DOTS_INSTALLED")"
rm -f "$CACHY_DOTS_INSTALLED"
ln -s "$CACHY_DOTS_PATH" "$CACHY_DOTS_INSTALLED"

log "Symlinking config/* into ~/.config/*..."
mkdir -p "$HOME/.config"
for entry in "$CACHY_DOTS_PATH"/config/*; do
  name="$(basename "$entry")"
  target="$HOME/.config/$name"
  if [[ "$name" == "systemd" ]]; then
    mkdir -p "$HOME/.config/systemd/user"
    for unit in "$entry"/user/*.service; do
      ln -sf "$unit" "$HOME/.config/systemd/user/$(basename "$unit")"
    done
    continue
  fi
  rm -rf "$target"
  ln -s "$entry" "$target"
done

ln -sf "$CACHY_DOTS_PATH/config/mimeapps.list" "$HOME/.config/mimeapps.list"

# --- File associations -------------------------------------------------------

log "Setting default apps via xdg-mime..."
xdg-mime default org.gnome.Nautilus.desktop inode/directory
xdg-mime default imv.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff
xdg-mime default org.gnome.Evince.desktop application/pdf
xdg-mime default mpv.desktop video/mp4 video/x-msvideo video/x-matroska video/x-flv video/x-ms-wmv \
  video/mpeg video/ogg video/webm video/quicktime video/3gpp video/3gpp2 video/x-ms-asf \
  video/x-ogm+ogg video/x-theora+ogg application/ogg
xdg-mime default nvim.desktop text/plain text/english text/x-makefile text/x-c++hdr text/x-c++src \
  text/x-chdr text/x-csrc text/x-java text/x-moc text/x-pascal text/x-tcl text/x-tex \
  application/x-shellscript text/x-c text/x-c++ application/xml text/xml
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# --- Systemd user units -------------------------------------------------------

log "Enabling systemd user services..."
systemctl --user daemon-reload
for unit in walker mako swayosd polkit-agent battery-suspend-watch dms; do
  systemctl --user enable "$unit.service" 2>/dev/null || true
done

# --- SDDM login theme ---------------------------------------------------------

log "Installing SDDM theme (requires sudo)..."
sudo rm -rf /usr/share/sddm/themes/omarchy-look
sudo cp -r "$CACHY_DOTS_PATH/sddm/omarchy-look" /usr/share/sddm/themes/omarchy-look
sudo mkdir -p /etc/sddm.conf.d
sudo cp "$CACHY_DOTS_PATH/sddm/10-theme.conf" /etc/sddm.conf.d/10-theme.conf
sudo cp "$CACHY_DOTS_PATH/sddm/10-wayland.conf" /etc/sddm.conf.d/10-wayland.conf
sudo systemctl enable sddm.service

# --- Plymouth boot splash ------------------------------------------------------

log "Installing Plymouth theme (requires sudo)..."
sudo rm -rf /usr/share/plymouth/themes/omarchy-look
sudo cp -r "$CACHY_DOTS_PATH/plymouth/omarchy-look" /usr/share/plymouth/themes/omarchy-look
sudo plymouth-set-default-theme omarchy-look
sudo mkinitcpio -P 2>/dev/null || echo "note: re-run 'sudo mkinitcpio -P' manually if this distro uses mkinitcpio."

# --- Theme -----------------------------------------------------------------

log "Applying tokyo-night theme..."
chmod +x "$CACHY_DOTS_PATH/theme-engine/theme-set.sh" "$CACHY_DOTS_PATH"/bin/*
"$CACHY_DOTS_PATH/theme-engine/theme-set.sh" tokyo-night

log "Done. Log out and back in (or reboot) to pick up the new SDDM/Plymouth themes."
