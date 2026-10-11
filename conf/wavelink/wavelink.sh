#!/usr/bin/env bash
# Wave Link config <-> repo. Wave Link rewrites config.json atomically while running,
# so it can't be a symlink: backup copies live -> repo, restore copies repo -> live.
set -euo pipefail
live="$HOME/Library/Application Support/com.elgato.WaveLink3/config.json"
repo="$(dirname "$0")/config.json"

case "${1:-}" in
  backup)
    cp "$live" "$repo"
    echo "saved -> $repo"
    ;;
  restore)
    osascript -e 'quit app "Elgato Wave Link"'
    while pgrep -x WaveLinkMacOS >/dev/null; do sleep 0.2; done
    mkdir -p "$(dirname "$live")"
    cp "$repo" "$live"
    open -a "Elgato Wave Link"
    echo "restored <- $repo"
    ;;
  *)
    echo "usage: wavelink backup|restore" >&2
    exit 1
    ;;
esac
