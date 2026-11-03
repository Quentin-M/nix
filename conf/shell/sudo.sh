#!/bin/bash
# Grants admin through Privileges.app before sudo, for every caller on PATH (make, scripts, shells).
# Agents never self-elevate: they get the plain sudo and its refusal.
set -euo pipefail

privileges=/Applications/Privileges.app/Contents/MacOS/PrivilegesCLI

if [[ -z ${CLAUDECODE:-}${CODEX_THREAD_ID:-}${OMPCODE:-} && $("$privileges" --status 2>&1) != *"has administrator"* ]]; then
  "$privileges" --add --reason "To run sudo commands for a while" >&2
fi

exec /usr/bin/sudo "$@"
