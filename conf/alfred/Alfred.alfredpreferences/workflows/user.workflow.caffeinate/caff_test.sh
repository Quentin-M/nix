#!/usr/bin/env bash
# caff.sh against a stub caffeinate on PATH: argument parsing, pid tracking, foreign caffeinate untouched.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'pkill -f "$tmp/bin/caffeinate" 2>/dev/null || true; rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
printf '#!/bin/bash\necho "$*" >> "%s/calls"\nsleep 30\n' "$tmp" > "$tmp/bin/caffeinate"
chmod +x "$tmp/bin/caffeinate"
export PATH="$tmp/bin:$PATH" alfred_workflow_data="$tmp/data"

fail=0
check() { # check <want> <got> <label>
  if [[ $1 == "$2" ]]; then echo "ok   $3"; else echo "FAIL $3: want [$1] got [$2]"; fail=1; fi
}
caff() { "$here/caff.sh" "$@"; }
last_call() { sleep 0.3; tail -1 "$tmp/calls"; }
running() { pgrep -f "$tmp/bin/caffeinate" | wc -l | tr -d ' '; }

"$tmp/bin/caffeinate" foreign >/dev/null 2>&1 &
foreign=$!
sleep 0.2

check "Awake for 1 h" "$(caff 1)" "bare number is hours"
check "-di -t 3600" "$(last_call)" "1 -> 3600 s"
check "Awake for 2 h" "$(caff 2hr)" "hr suffix"
check "-di -t 7200" "$(last_call)" "2hr -> 7200 s"
check "2" "$(running)" "previous caff run replaced, foreign kept"
check "Awake for 30 min" "$(caff 30m)" "m suffix"
check "-di -t 1800" "$(last_call)" "30m -> 1800 s"
check "Awake until caff off" "$(caff)" "no argument"
check "-di" "$(last_call)" "no argument -> no timeout"
check "Usage: caff 1h | 30m | off" "$(caff 0)" "zero rejected"
check "Usage: caff 1h | 30m | off" "$(caff 'x; rm -rf /')" "garbage rejected"
check "Usage: caff 1h | 30m | off" "$(caff -t 5)" "flag rejected"
check "2" "$(running)" "rejected input keeps the running caff"
check "Sleep allowed" "$(caff off)" "off"
check "1" "$(running)" "off stops only our caffeinate"
kill -0 "$foreign" && check "alive" "alive" "foreign caffeinate survives"

echo 99999 > "$tmp/data/caffeinate.pid"
check "Sleep allowed" "$(caff off)" "stale pid file"

exit $fail
