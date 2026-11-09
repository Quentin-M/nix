#!/usr/bin/env bash
# Alfred reads its settings straight from Alfred.alfredpreferences next to this script (Alfred's own
# "preferences folder" feature), so UI changes land in the repo as they happen: commit them.
# Per-Mac settings (hotkey, clipboard on/off, snippet auto-expand) sit under preferences/local/<hash>;
# a new Mac copies them once from the Mac that last seeded.
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
bundle="$dir/Alfred.alfredpreferences"
local_dir="$bundle/preferences/local"
support="${ALFRED_SUPPORT:-$HOME/Library/Application Support/Alfred}"
pointer="$support/prefs.json"
app="Alfred 5"

running() { pgrep -qx Alfred; }
quit_app() {
  osascript -e "quit app \"$app\"" >/dev/null 2>&1 || true
  for _ in {1..50}; do running || return 0; sleep 0.1; done
  pkill -x Alfred || true
}

pointed() { [[ "$(plutil -extract current raw "$pointer" 2>/dev/null)" == "$bundle" ]]; }

# Alfred reads prefs.json at launch: "current" is the bundle, syncfolders.5 its folder (Alfred 5).
point() {
  mkdir -p "$support"
  [[ -f $pointer ]] || printf '{"current":""}' > "$pointer"
  plutil -replace current -string "$bundle" "$pointer"
  plutil -replace syncfolders -json "{\"5\":\"$dir\"}" "$pointer"
}

# Alfred names the local folder after this Mac on first launch; empty until then.
this_hash() { plutil -extract localhash raw "$pointer" 2>/dev/null || true; }

seed_local() {
  local hash="$1" src
  src="$(ls -td "$local_dir"/*/.seeded 2>/dev/null | head -1)"
  src="${src%/.seeded}"
  mkdir -p "$local_dir/$hash"
  [[ -n $src && $src != "$local_dir/$hash" ]] && cp -R "$src/." "$local_dir/$hash/"
  touch "$local_dir/$hash/.seeded"
}

case "${1:-}" in
  seed)
    # make nix: point Alfred at the repo, and give a new Mac the per-Mac settings once.
    hash="$(this_hash)"
    need_point=0 need_local=0
    pointed || need_point=1
    [[ -n $hash && ! -f $local_dir/$hash/.seeded ]] && need_local=1
    ((need_point || need_local)) || exit 0
    was_running=0
    running && was_running=1 && quit_app
    ((need_point)) && point && echo "alfred: preferences -> $bundle"
    ((need_local)) && seed_local "$hash" && echo "alfred: seeded local settings for $hash"
    ((was_running)) && open -a "$app"
    [[ -z $hash ]] && echo "alfred: launch Alfred once, then rerun make nix to copy hotkey and clipboard settings"
    exit 0
    ;;
  restore)
    # After a pull: Alfred rereads the repo bundle on relaunch.
    quit_app
    pointed || point
    hash="$(this_hash)"
    [[ -n $hash && ! -f $local_dir/$hash/.seeded ]] && seed_local "$hash"
    open -a "$app"
    echo "alfred: restored <- $bundle"
    ;;
  *)
    echo "usage: alfred.sh seed|restore" >&2
    exit 1
    ;;
esac
