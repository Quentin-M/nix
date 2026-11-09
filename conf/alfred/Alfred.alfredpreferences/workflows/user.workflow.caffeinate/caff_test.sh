#!/usr/bin/env bash
# caff.sh against a stub caffeinate on PATH: parsing, preview rows, state, foreign caffeinate untouched.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'pkill -f "$tmp/bin/caffeinate" 2>/dev/null || true; kill "${holder:-}" 2>/dev/null || true; rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
printf '#!/bin/bash\necho "$*" >> "%s/calls"\nsleep 30\n' "$tmp" > "$tmp/bin/caffeinate"
printf '#!/bin/bash\necho "${@: -1}" >> "%s/alerts"\n' "$tmp" > "$tmp/bin/hs"
chmod +x "$tmp/bin/caffeinate" "$tmp/bin/hs"
# Like Alfred: stdin is an open pipe, which makes a real hs read it after -c and hang.
exec < <(sleep 600)
holder=$!
export PATH="$tmp/bin:$PATH" alfred_workflow_data="$tmp/data" CAFF_HS="$tmp/bin/hs"

fail=0
check() { # check <want> <got> <label>
  if [[ $1 == "$2" ]]; then echo "ok   $3"; else echo "FAIL $3: want [$1] got [$2]"; fail=1; fi
}
matches() { # matches <regex> <got> <label>
  if [[ $2 =~ $1 ]]; then echo "ok   $3"; else echo "FAIL $3: [$2] !~ [$1]"; fail=1; fi
}
run() { "$here/caff.sh" run "$@"; }
preview() { "$here/caff.sh" preview "$@"; }
title() { preview "$@" | python3 -I -c 'import json,sys; i=json.load(sys.stdin)["items"][0]; print(i["title"], "|", i["subtitle"], "|", i["arg"], "|", i["valid"])'; }
last_call() { sleep 0.3; tail -1 "$tmp/calls"; }
last_alert() { tail -1 "$tmp/alerts"; }
running() { pgrep -f "$tmp/bin/caffeinate" | wc -l | tr -d ' '; }

"$tmp/bin/caffeinate" foreign >/dev/null 2>&1 &
foreign=$!
sleep 0.2

check "Keep awake for 1 min | Now: sleep allowed | 1min | True" "$(title 1min)" "preview 1min, nothing running"
check "0" "$(cat "$tmp/alerts" 2>/dev/null | wc -l | tr -d ' ')" "preview never alerts"
check "Keep awake for 2 h | Now: sleep allowed | 2hr | True" "$(title 2hr)" "preview 2hr"
check "Keep awake until caff off | Now: sleep allowed |  | True" "$(title)" "preview empty"
check "Allow sleep | Now: sleep allowed | off | True" "$(title off)" "preview off"
check "Usage: caff 1h · 30m · off | Now: sleep allowed |  | False" "$(title '"x\"}')" "preview garbage: invalid row, valid JSON"

matches "^Awake for 1 min, until [0-9]{2}:[0-9]{2}$" "$(run 1min 2>&1)" "1min runs, says until when"
check "-di -t 60" "$(last_call)" "1min -> 60 s"
matches '^hs.alert.show\("☕ Awake for 1 min, until [0-9]{2}:[0-9]{2}", 2\)$' "$(last_alert)" "1min: on-screen alert"
matches "\\| Now: awake until [0-9]{2}:[0-9]{2} \\|" "$(title 5m 2>&1)" "preview shows the running state"
matches "^Awake for 1 h, until [0-9]{2}:[0-9]{2}$" "$(run 1 2>&1)" "bare number is hours"
check "-di -t 3600" "$(last_call)" "1 -> 3600 s"
check "2" "$(running)" "previous caff replaced, foreign kept"
matches "^Awake for 30 min, until [0-9]{2}:[0-9]{2}$" "$(run 30minutes 2>&1)" "minutes spelled out"
check "-di -t 1800" "$(last_call)" "30minutes -> 1800 s"
check "Awake until caff off" "$(run)" "no argument"
check "-di" "$(last_call)" "no argument -> no timeout"
check "Keep awake for 5 min | Now: awake until caff off | 5m | True" "$(title 5m)" "preview shows endless state"
check "Usage: caff 1h · 30m · off" "$(run 0)" "zero rejected"
check 'hs.alert.show("☕ Usage: caff 1h · 30m · off", 2)' "$(last_alert)" "rejected input: on-screen alert"
check "Usage: caff 1h · 30m · off" "$(run -t 5)" "flag rejected"
check "2" "$(running)" "rejected input keeps the running caff"
check "Sleep allowed" "$(run off)" "off (decaf)"
check 'hs.alert.show("☕ Sleep allowed", 2)' "$(last_alert)" "off: on-screen alert"
check "1" "$(running)" "off stops only our caffeinate"
kill -0 "$foreign" && check "alive" "alive" "foreign caffeinate survives"
check "Keep awake for 5 min | Now: sleep allowed | 5m | True" "$(title 5m)" "preview after off"

echo "99999 -" > "$tmp/data/caffeinate.pid"
check "Now: sleep allowed" "$(title 5m | cut -d'|' -f2 | xargs)" "stale state file reads as asleep"
check "Sleep allowed" "$(run off)" "stale state file"

exit $fail
