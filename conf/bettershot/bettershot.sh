#!/usr/bin/env bash
# BetterShot settings <-> repo, driven by appsync. BetterShot has no sync of its own: backup
# copies live -> prefs.json, restore copies it back and relaunches the app. Device-bound keys
# (permissions, onboarding, last region, cloud upload account) never leave the Mac.
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
prefs="$dir/prefs.json"
domain=com.bettershot.app
app=BetterShot
seeded="$HOME/Library/Application Support/BetterShot/.seeded-from-repo"

quit_app() {
  osascript -e "quit app \"$app\"" >/dev/null 2>&1 || true
  for _ in {1..50}; do pgrep -qx "$app" || return 0; sleep 0.1; done
  pkill -x "$app" || true
}

# Writes the repo prefs into the live domain, keeping the device-bound keys already there.
apply() {
  [[ -f $prefs ]] || { echo "bettershot: no $prefs; set BetterShot up on a Mac, then run appsync backup" >&2; exit 1; }
  tmp="$(mktemp -d)"
  defaults export "$domain" "$tmp/live.plist" 2>/dev/null || plutil -create xml1 "$tmp/live.plist"
  python3 -I "$dir/prefs.py" restore "$prefs" "$tmp/live.plist" "$tmp/new.plist" "$HOME"
  defaults import "$domain" "$tmp/new.plist"
  rm -rf "$tmp"
}

case "${1:-}" in
  backup)
    tmp="$(mktemp -d)"
    defaults export "$domain" "$tmp/live.plist"
    python3 -I "$dir/prefs.py" backup "$tmp/live.plist" "$prefs" "$HOME"
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
    # make nix: once per Mac, so live tweaks survive later switches. BetterShot writes its own
    # defaults on first launch, so only this marker tells a seeded Mac apart.
    [[ -f $seeded ]] && exit 0
    quit_app
    apply
    mkdir -p "${seeded%/*}"
    touch "$seeded"
    open -a "$app"
    echo "bettershot: seeded from $prefs"
    ;;
  *)
    echo "usage: bettershot.sh backup|restore|seed" >&2
    exit 1
    ;;
esac
