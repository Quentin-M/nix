#!/usr/bin/env bash
# DockDoor Pro settings <-> repo. DockDoor has no iCloud sync, so the repo carries them:
# backup copies live -> prefs.<variant>.json, restore copies it back and relaunches the app.
# Device-bound keys (license token, updater state, window frames, file bookmarks) never
# leave the Mac. Custom icons travel in icons/, with paths rewritten per machine.
set -euo pipefail
variant="${1:?usage: dockdoor <home|pro> backup|restore|seed}"
cmd="${2:-}"
dir="$(cd "$(dirname "$0")" && pwd)"
prefs="$dir/prefs.$variant.json"
domain=com.ejbills.DockDoorPro
app="DockDoor Pro"
icons_live="$HOME/Library/Application Support/DockDoorPro/CustomIcons"

quit_app() {
  osascript -e "quit app \"$app\"" >/dev/null 2>&1 || true
  for _ in {1..50}; do pgrep -qf "$app.app/Contents/MacOS" || return 0; sleep 0.1; done
  pkill -f "$app.app/Contents/MacOS" || true
}

# Writes the repo prefs into the live domain, keeping the device-bound keys already there.
apply() {
  [[ -f $prefs ]] || { echo "dockdoor: no $prefs yet; set DockDoor up here, then run dockdoor backup" >&2; exit 1; }
  mkdir -p "$icons_live"
  [[ -d $dir/icons ]] && cp "$dir/icons/"* "$icons_live/" 2>/dev/null || true
  tmp="$(mktemp -d)"
  defaults export "$domain" "$tmp/live.plist" 2>/dev/null || plutil -create xml1 "$tmp/live.plist"
  python3 -I "$dir/prefs.py" restore "$prefs" "$tmp/live.plist" "$tmp/new.plist" "$HOME" "$icons_live"
  defaults import "$domain" "$tmp/new.plist"
  rm -rf "$tmp"
}

case "$cmd" in
  backup)
    tmp="$(mktemp -d)"
    defaults export "$domain" "$tmp/live.plist"
    mkdir -p "$dir/icons"
    python3 -I "$dir/prefs.py" backup "$tmp/live.plist" "$prefs" "$HOME" "$icons_live" "$dir/icons"
    rm -rf "$tmp"
    echo "saved -> $prefs"
    ;;
  restore)
    quit_app
    apply
    open -a "$app"
    echo "restored <- $prefs"
    ;;
  seed)
    # make nix: only a Mac where DockDoor was never configured, so live tweaks survive switches.
    defaults read "$domain" dockProfiles &>/dev/null && exit 0
    [[ -f $prefs ]] || exit 0
    quit_app
    apply
    echo "dockdoor: seeded from $prefs"
    ;;
  *)
    echo "usage: dockdoor backup|restore|seed" >&2
    exit 1
    ;;
esac
