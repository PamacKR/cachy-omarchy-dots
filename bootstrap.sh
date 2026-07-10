#!/usr/bin/env bash
# Take a bare CachyOS box all the way to "run install.sh works" - use this
# instead of install.sh if you haven't installed yay/Niri/DMS yet.
#
# Does: base-devel + git -> build yay from the AUR -> install Niri -> run
# DMS's own installer (interactive - you make your own choices there) ->
# hand off to install.sh for everything else.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo -e "\n==> $*"; }

# Prime sudo once and keep it alive for the whole script (build + DMS's own
# installer can take a while, and a stale sudo timestamp partway through
# looks like the script has hung).
source "$SCRIPT_DIR/bin/cachy-sudo-keepalive"

log "Installing base-devel + git (needed to build yay from the AUR)..."
sudo pacman -S --needed --noconfirm base-devel git

if command -v yay >/dev/null 2>&1; then
  log "yay already installed, skipping."
else
  log "Building and installing yay from the AUR..."
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
fi

log "Installing Niri..."
sudo pacman -S --needed --noconfirm niri

log "Running DMS's installer (interactive - make your own choices here)..."
curl -fsSL https://install.danklinux.com | sh

log "DMS installer finished. Continuing with the rest of the setup..."
exec "$SCRIPT_DIR/install.sh"
