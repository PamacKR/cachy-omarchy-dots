#!/usr/bin/env bash
# Regenerate per-app color fragments from a theme's colors.toml and restart consumers.
# Mirrors Omarchy's omarchy-theme-set atomic-staging-dir approach, scoped to a smaller app set.
#
# Usage: theme-set.sh <theme-name>
set -euo pipefail

CACHY_DOTS_PATH="${CACHY_DOTS_PATH:-$HOME/.local/share/cachy-dots}"
STATE_DIR="$HOME/.config/cachy-dots/current"

theme_name="${1:?Usage: theme-set.sh <theme-name>}"
theme_src="$CACHY_DOTS_PATH/themes/$theme_name"
colors_toml="$theme_src/colors.toml"

if [[ ! -f "$colors_toml" ]]; then
  echo "error: no colors.toml found for theme '$theme_name' at $colors_toml" >&2
  exit 1
fi

staging="$STATE_DIR/next-theme"
rm -rf "$staging"
mkdir -p "$staging"

# Copy the theme's own static assets (backgrounds, any hand-authored overrides) first.
cp -r "$theme_src"/. "$staging"/

# Build a sed script from colors.toml: {{ key }}, {{ key_strip }} (no leading #), {{ key_rgb }} (r,g,b decimal).
sed_script="$(mktemp)"
trap 'rm -f "$sed_script"' EXIT

while IFS='=' read -r key value; do
  key="$(echo "$key" | xargs)"
  value="$(echo "$value" | xargs | tr -d '"')"
  [[ -z "$key" || "$key" == \#* ]] && continue

  hex="${value#\#}"
  r=$((16#${hex:0:2}))
  g=$((16#${hex:2:2}))
  b=$((16#${hex:4:2}))

  # 0.0-1.0 floats (3dp), for Plymouth's Window.SetBackgroundTopColor(r, g, b)
  # / Image.Text(..., r, g, b, ...) calls, which take floats, not 0-255 ints.
  r_float="$(awk "BEGIN{printf \"%.3f\", ${r}/255}")"
  g_float="$(awk "BEGIN{printf \"%.3f\", ${g}/255}")"
  b_float="$(awk "BEGIN{printf \"%.3f\", ${b}/255}")"

  {
    echo "s/{{ *${key} *}}/${value}/g"
    echo "s/{{ *${key}_strip *}}/${hex}/g"
    echo "s/{{ *${key}_rgb *}}/${r}, ${g}, ${b}/g"
    # Semicolon-joined, for raw ANSI escapes (ESC[38;2;r;g;bm) rather than
    # CSS-style rgba()/rgb() commas.
    echo "s/{{ *${key}_rgb_semi *}}/${r};${g};${b}/g"
    echo "s/{{ *${key}_rgb_float *}}/${r_float}, ${g_float}, ${b_float}/g"
  } >>"$sed_script"
done < <(grep -E '^[a-zA-Z0-9_]+\s*=' "$colors_toml")

# Stamp every template into the staging dir, dropping the .tpl suffix.
for tpl in "$CACHY_DOTS_PATH"/theme-engine/templates/*.tpl; do
  out_name="$(basename "$tpl" .tpl)"
  # A theme-provided static file (copied above) wins over the generated one.
  [[ -f "$staging/$out_name" ]] && continue
  sed -f "$sed_script" "$tpl" >"$staging/$out_name"
done

# Atomic swap.
mkdir -p "$STATE_DIR"
rm -rf "$STATE_DIR/theme.old"
[[ -d "$STATE_DIR/theme" ]] && mv "$STATE_DIR/theme" "$STATE_DIR/theme.old"
mv "$staging" "$STATE_DIR/theme"
rm -rf "$STATE_DIR/theme.old"
echo "$theme_name" >"$STATE_DIR/theme.name"

# Copy niri's border/focus-ring colors into its actual include path
# directly, rather than relying on DMS to regenerate this file itself -
# that didn't reliably happen when switching themes externally (see
# theme-engine/templates/niri-dms-colors.kdl.tpl for why).
niri_dms_colors="$HOME/.config/niri/dms/colors.kdl"
if [[ -f "$STATE_DIR/theme/niri-dms-colors.kdl" && -d "$(dirname "$niri_dms_colors")" ]]; then
  cat "$STATE_DIR/theme/niri-dms-colors.kdl" >"$niri_dms_colors"
fi

# SDDM/Plymouth live in root-owned system dirs (install.sh copies them
# there, they're not symlinked) - render the two templated files here and
# sudo-copy them over. theme-set.sh needs to be run from an actual
# terminal for this (see cachy-menu's show_style_theme_menu, which opens
# one) - a plain background/no-TTY invocation has nowhere for sudo to
# prompt. `sudo -v` once upfront means both copies below share one prompt
# instead of two. Note: this updates SDDM and Plymouth's shutdown/reboot
# screen immediately (both read straight from these files), but the
# early-boot splash is baked into the initramfs - it stays on the old
# colors until the next `sudo mkinitcpio -P` (e.g. next install.sh run,
# or reboot after running that manually). Not run automatically here
# since it's a slow, heavier operation not worth doing on every switch.
sddm_main_qml="/usr/share/sddm/themes/omarchy-look/Main.qml"
plymouth_script="/usr/share/plymouth/themes/omarchy-look/omarchy-look.script"
if [[ -f "$sddm_main_qml" || -f "$plymouth_script" ]]; then
  sudo -v
fi

if [[ -f "$sddm_main_qml" ]]; then
  rendered_sddm="$(mktemp)"
  sed -f "$sed_script" "$CACHY_DOTS_PATH/sddm/omarchy-look/Main.qml" >"$rendered_sddm"
  sudo cp "$rendered_sddm" "$sddm_main_qml" || echo "warning: couldn't update SDDM theme" >&2
  rm -f "$rendered_sddm"
fi

if [[ -f "$plymouth_script" ]]; then
  rendered_plymouth="$(mktemp)"
  sed -f "$sed_script" "$CACHY_DOTS_PATH/plymouth/omarchy-look/omarchy-look.script" >"$rendered_plymouth"
  sudo cp "$rendered_plymouth" "$plymouth_script" || echo "warning: couldn't update Plymouth theme" >&2
  rm -f "$rendered_plymouth"
  echo "note: Plymouth's shutdown/reboot screen is updated; run 'sudo mkinitcpio -P' to also update the early-boot splash."
fi

# Point the background symlink at the theme's first wallpaper, if any.
first_bg="$(find "$STATE_DIR/theme/backgrounds" -maxdepth 1 -type f 2>/dev/null | sort | head -n1 || true)"
if [[ -n "$first_bg" ]]; then
  ln -sf "$first_bg" "$STATE_DIR/background"
fi

# Restart consumers so they pick up the new fragments. Alacritty/GTK apps just
# read the fragment on next launch, so nothing to restart there.
makoctl reload 2>/dev/null || systemctl --user restart mako.service 2>/dev/null || true
systemctl --user restart walker.service 2>/dev/null || true

# DMS owns wallpaper rendering itself (not swaybg) and has its own color
# theme separate from the fragments above - set both via its IPC/settings so
# this is a single switch for "everything", not just Alacritty/Walker/mako.
if [[ -n "$first_bg" ]] && command -v dms >/dev/null 2>&1; then
  dms ipc call wallpaper set "$first_bg" 2>/dev/null || true
fi

dms_theme_id_file="$theme_src/dms-theme-id"
if [[ -f "$dms_theme_id_file" ]]; then
  dms_theme_id="$(<"$dms_theme_id_file")"
  dms_settings="$HOME/.config/DankMaterialShell/settings.json"
  dms_theme_json="$HOME/.config/DankMaterialShell/themes/$dms_theme_id/theme.json"
  if [[ -f "$dms_settings" && -f "$dms_theme_json" ]] && command -v jq >/dev/null 2>&1; then
    tmp_settings="$(mktemp)"
    if jq --arg f "$dms_theme_json" \
      '.currentThemeName = "custom" | .customThemeFile = $f' \
      "$dms_settings" >"$tmp_settings"; then
      # Write through the existing file (which install.sh symlinks into the
      # repo) instead of `mv`, which would replace the symlink itself with a
      # plain file and silently break the live-edit relationship.
      cat "$tmp_settings" >"$dms_settings"
    fi
    rm -f "$tmp_settings"
  fi
fi

# Fallback wallpaper setter for testing without DMS running - harmless no-op
# otherwise, since DMS's own rendering draws over/instead of this anyway.
pkill -x swaybg 2>/dev/null || true
if [[ -n "$first_bg" ]] && ! command -v dms >/dev/null 2>&1 && command -v swaybg >/dev/null 2>&1; then
  (setsid swaybg -i "$first_bg" -m fill &>/dev/null &) || true
fi

systemctl --user restart dms.service 2>/dev/null || true

echo "Theme set to '$theme_name'."
