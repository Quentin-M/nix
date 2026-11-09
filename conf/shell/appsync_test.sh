#!/usr/bin/env bash
# appsync.sh against stub app scripts and a fake /Applications: dispatch, skips, failure isolation.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/conf/dockdoor" "$tmp/conf/wavelink" "$tmp/conf/bettershot" "$tmp/conf/alfred" "$tmp/apps/DockDoor Pro.app" "$tmp/apps/BetterShot.app" "$tmp/apps/Alfred 5.app"
for s in dockdoor/dockdoor.sh wavelink/wavelink.sh bettershot/bettershot.sh alfred/alfred.sh; do
  printf '#!/bin/bash\necho "%s $1" >> "%s/calls"\n' "${s%%/*}" "$tmp" > "$tmp/conf/$s"
done
printf '#!/bin/bash\necho "dockdoor $1" >> "%s/calls"; exit 3\n' "$tmp" > "$tmp/conf/dockdoor/dockdoor.sh"
chmod +x "$tmp/conf/"*/*.sh
export APPSYNC_CONF="$tmp/conf" APPSYNC_APPS="$tmp/apps"

fail=0
check() { if [[ $1 == "$2" ]]; then echo "ok   $3"; else echo "FAIL $3: want [$1] got [$2]"; fail=1; fi; }
run() { : > "$tmp/calls"; "$here/appsync.sh" "$@" > "$tmp/out" 2>&1 && echo 0 || echo $?; }
calls() { tr '\n' ';' < "$tmp/calls"; }

check 1 "$(run backup)" "backup: a failing app makes the run fail"
check "dockdoor backup;bettershot backup;" "$(calls)" "backup: Wave Link skipped (not installed), Alfred has no copy step"
grep -q "Elgato Wave Link: not installed, skipped" "$tmp/out" && check y y "backup: skip reported" || check y n "backup: skip reported"
grep -q "DockDoor Pro: backup failed" "$tmp/out" && check y y "backup: failure reported" || check y n "backup: failure reported"

mkdir -p "$tmp/apps/Elgato Wave Link.app"
check 1 "$(run restore)" "restore: failure still fails the run"
check "dockdoor restore;wavelink restore;bettershot restore;alfred restore;" "$(calls)" "restore: keeps going after DockDoor fails"

printf '#!/bin/bash\necho "dockdoor $1" >> "%s/calls"\n' "$tmp" > "$tmp/conf/dockdoor/dockdoor.sh"
check 0 "$(run seed)" "seed: all apps succeed"
check "dockdoor seed;wavelink seed;bettershot seed;alfred seed;" "$(calls)" "seed: every installed app"

check 1 "$(run nope)" "unknown command"
exit $fail
