#!/usr/bin/env bash
# App settings <-> repo, for every app the repo carries settings for.
#   backup   live -> repo: DockDoor and Wave Link copy; Alfred already writes into the repo
#   restore  repo -> live: each app quits, takes the repo settings, relaunches
#   seed     make nix: a new Mac takes the repo settings once; later runs leave live settings alone
# Apps not installed are skipped; one failing app does not stop the others.
set -euo pipefail
conf="${APPSYNC_CONF:-$(cd "$(dirname "$0")/.." && pwd)}"
apps="${APPSYNC_APPS:-/Applications}"

rc=0
sync() { # sync <app> <script> <cmd>
  if [[ ! -d "$apps/$1.app" ]]; then
    echo "$1: not installed, skipped"
  elif ! "$2" "$3"; then
    echo "$1: $3 failed" >&2
    rc=1
  fi
}

case "${1:-}" in
  backup)
    sync "DockDoor Pro" "$conf/dockdoor/dockdoor.sh" backup
    sync "Elgato Wave Link" "$conf/wavelink/wavelink.sh" backup
    echo "alfred: writes into $conf/alfred live, nothing to copy"
    git -C "$conf" status --short -- dockdoor wavelink alfred 2>/dev/null || true
    ;;
  restore)
    sync "DockDoor Pro" "$conf/dockdoor/dockdoor.sh" restore
    sync "Elgato Wave Link" "$conf/wavelink/wavelink.sh" restore
    sync "Alfred 5" "$conf/alfred/alfred.sh" restore
    ;;
  seed)
    sync "DockDoor Pro" "$conf/dockdoor/dockdoor.sh" seed
    sync "Elgato Wave Link" "$conf/wavelink/wavelink.sh" seed
    sync "Alfred 5" "$conf/alfred/alfred.sh" seed
    ;;
  *)
    echo "usage: appsync backup|restore|seed" >&2
    exit 1
    ;;
esac
exit $rc
