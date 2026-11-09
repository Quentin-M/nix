#!/usr/bin/env bash
# alfred.sh seed against a temp bundle and stubbed osascript/open/pgrep/pkill: no real Alfred involved.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
local_dir="$repo/Alfred.alfredpreferences/preferences/local"
mkdir -p "$repo" "$tmp/bin" "$local_dir/AAA/hotkey"
cp "$here/alfred.sh" "$repo/"
printf '{"default":{"key":49,"mod":1048576}}' | plutil -convert xml1 -o "$local_dir/AAA/hotkey/prefs.plist" -
touch "$local_dir/AAA/.seeded"

# Stubs: Alfred "runs" while $tmp/running exists; osascript quit removes it.
printf '#!/bin/bash\necho "osascript $*" >> "%s/calls"; rm -f "%s/running"\n' "$tmp" "$tmp" > "$tmp/bin/osascript"
printf '#!/bin/bash\necho "open $*" >> "%s/calls"\n' "$tmp" > "$tmp/bin/open"
printf '#!/bin/bash\n[[ -f "%s/running" ]]\n' "$tmp" > "$tmp/bin/pgrep"
printf '#!/bin/bash\necho "pkill $*" >> "%s/calls"\n' "$tmp" > "$tmp/bin/pkill"
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" ALFRED_SUPPORT="$tmp/support"
pointer="$tmp/support/prefs.json"

fail=0
check() { # check <want> <got> <label>
  if [[ $1 == "$2" ]]; then echo "ok   $3"; else echo "FAIL $3: want [$1] got [$2]"; fail=1; fi
}
seed() { : > "$tmp/calls"; "$repo/alfred.sh" seed; }
calls() { tr '\n' ';' < "$tmp/calls"; }
mod() { plutil -extract default.mod raw "$local_dir/$1/hotkey/prefs.plist" 2>/dev/null || echo none; }

out="$(seed)"
check "$repo/Alfred.alfredpreferences" "$(plutil -extract current raw "$pointer")" "fresh Mac: current points at repo"
check "$repo" "$(plutil -extract syncfolders.5 raw "$pointer")" "fresh Mac: sync folder is repo"
check "" "$(calls)" "fresh Mac, Alfred not running: no quit, no launch"
[[ $out == *"launch Alfred once"* ]] && check y y "fresh Mac: asks for a first launch" || check y n "fresh Mac: asks for a first launch"

# First launch: Alfred names this Mac BBB and writes its own default hotkey (Option+Space).
plutil -replace localhash -string BBB "$pointer"
mkdir -p "$local_dir/BBB/hotkey"
printf '{"default":{"key":49,"mod":524288}}' | plutil -convert xml1 -o "$local_dir/BBB/hotkey/prefs.plist" -
touch "$tmp/running"
seed >/dev/null
check "1048576" "$(mod BBB)" "second run: hotkey copied from the seeded Mac"
check "osascript -e quit app \"Alfred 5\";open -a Alfred 5;" "$(calls)" "second run: Alfred quit before the copy, relaunched after"
[[ -f $local_dir/BBB/.seeded ]] && check y y "second run: marks BBB seeded" || check y n "second run: marks BBB seeded"

touch "$tmp/running"
plutil -replace default.mod -integer 262144 "$local_dir/BBB/hotkey/prefs.plist"
seed >/dev/null
check "" "$(calls)" "third run: nothing to do, Alfred left alone"
check "262144" "$(mod BBB)" "third run: live tweaks on BBB survive"

plutil -replace current -string /elsewhere "$pointer"
seed >/dev/null
check "$repo/Alfred.alfredpreferences" "$(plutil -extract current raw "$pointer")" "repointed when moved away"
check "BBB" "$(plutil -extract localhash raw "$pointer")" "localhash kept"
check "262144" "$(mod BBB)" "repoint leaves local settings alone"

rm -f "$local_dir/AAA/.seeded" "$local_dir/BBB/.seeded"
plutil -replace localhash -string CCC "$pointer"
rm -f "$tmp/running"
seed >/dev/null
check "none" "$(mod CCC)" "first Mac ever: nothing to copy from"
[[ -f $local_dir/CCC/.seeded ]] && check y y "first Mac ever: becomes the seed" || check y n "first Mac ever: becomes the seed"

touch "$tmp/running"
: > "$tmp/calls"
"$repo/alfred.sh" restore >/dev/null
check "osascript -e quit app \"Alfred 5\";open -a Alfred 5;" "$(calls)" "restore: always relaunches"

exit $fail
