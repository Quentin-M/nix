#!/usr/bin/env bash
# caff [N | Nh | Nm | off]: keep the Mac fully awake (idle, display, lid and display-unplug sleep).
# N alone is hours; no argument lasts until "caff off" (or "uncaffeinate"/"decaf").
# caffeinate only blocks idle sleep; "pmset disablesleep" blocks the rest. It needs root, so
# infra/nix/src/darwin.nix grants a NOPASSWD sudoers rule for exactly these two commands.
#   caff.sh preview <arg>   Alfred script filter: one row saying what Enter will do, and the current state
#   caff.sh run <arg>       start or stop; prints the notification text
# Only the caffeinate this script started is stopped: Claude Code and others run their own.
# Results also flash on screen through Hammerspoon: Alfred's notifications use the retired
# NSUserNotification API, which macOS no longer shows.
set -euo pipefail
hs="${CAFF_HS:-/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs}"
state="${alfred_workflow_data:-$HOME/Library/Application Support/Alfred/Workflow Data/caffeinate}/caffeinate.pid"
usage="caff 1h · 30m · off"
pmset_sudo=(sudo -n /usr/bin/pmset -a disablesleep)

# parse <arg>: sets secs (empty = no end) and label, or returns 1.
parse() {
  if [[ $1 =~ ^([0-9]+)(h|hr|hrs|hour|hours)?$ ]] && ((10#${BASH_REMATCH[1]} > 0)); then
    secs=$((10#${BASH_REMATCH[1]} * 3600)) label="$((10#${BASH_REMATCH[1]})) h"
  elif [[ $1 =~ ^([0-9]+)(m|min|mins|minute|minutes)$ ]] && ((10#${BASH_REMATCH[1]} > 0)); then
    secs=$((10#${BASH_REMATCH[1]} * 60)) label="$((10#${BASH_REMATCH[1]})) min"
  elif [[ -z $1 ]]; then
    secs="" label=""
  else
    return 1
  fi
}

# The state file holds "<pid> <end epoch or ->". Prints the pid while that caffeinate still runs.
running_pid() {
  [[ -f $state ]] || return 1
  local pid end
  read -r pid end < "$state" || true
  [[ $pid =~ ^[0-9]+$ && $(ps -p "$pid" -o command= 2>/dev/null) == *caff-hold* ]] || return 1
  echo "$pid"
}

status() {
  local pid end
  if pid="$(running_pid)"; then
    read -r _ end < "$state"
    if [[ $end == - ]]; then echo "Now: awake until caff off"; else echo "Now: awake until $(/bin/date -r "$end" +%H:%M)"; fi
  else
    echo "Now: sleep allowed"
  fi
}

stop() {
  local pid
  if pid="$(running_pid)"; then
    pkill -P "$pid" || true
    kill "$pid" || true
  fi
  rm -f "$state"
  "${pmset_sudo[@]}" 0 >/dev/null 2>&1 || true
}

# hold <seconds or empty>: caffeinate, then undo disablesleep when it ends or expires. Detached and
# silent: Alfred waits for stdout to close before it shows the notification. The binary travels in
# the environment so the wrapper's own command line stays free of it.
hold() {
  CAFF_BIN="$(command -v caffeinate)" CAFF_PMSET="${pmset_sudo[*]}" \
    nohup bash -c '"$CAFF_BIN" -dims ${1:+-t "$1"}; $CAFF_PMSET 0' caff-hold "$1" </dev/null >/dev/null 2>&1 &
  echo "$!"
}

# lock_note: empty when disablesleep took effect, a warning otherwise.
lock_note() {
  "${pmset_sudo[@]}" 1 >/dev/null 2>&1 && return 0
  echo " (sudo rule missing: run make nix)"
}

# say <msg>: Alfred's notification text, plus an on-screen alert. Messages hold fixed strings and
# parsed numbers only, never the raw query, so they are safe inside the Lua string.
say() {
  echo "$1"
  [[ -x $hs ]] && "$hs" -t 1 -c "hs.alert.show(\"☕ $1\", 2)" </dev/null >/dev/null 2>&1 || true
}

# Fixed strings and parsed numbers only: the raw query never reaches the JSON.
row() { # row <title> <subtitle> <arg> <valid>
  printf '{"items":[{"title":"%s","subtitle":"%s","arg":"%s","valid":%s}]}\n' "$1" "$2" "$3" "$4"
}

cmd="${1:-}" arg="${2:-}"
case "$cmd" in
  preview)
    now="$(status)"
    if [[ $arg == off ]]; then
      row "Allow sleep" "$now" off true
    elif parse "$arg"; then
      if [[ -n $secs ]]; then row "Keep awake for $label" "$now" "$arg" true
      else row "Keep awake until caff off" "$now" "" true; fi
    else
      row "Usage: $usage" "$now" "" false
    fi
    ;;
  run)
    if [[ $arg == off ]]; then
      stop
      say "Sleep allowed"
      exit 0
    fi
    parse "$arg" || { say "Usage: $usage"; exit 0; }
    stop
    mkdir -p "${state%/*}"
    note="$(lock_note)"
    if [[ -n $secs ]]; then
      pid="$(hold "$secs")"
      echo "$pid $(($(/bin/date +%s) + secs))" > "$state"
      say "Awake for $label, until $(/bin/date -r $(($(/bin/date +%s) + secs)) +%H:%M)$note"
    else
      pid="$(hold "")"
      echo "$pid -" > "$state"
      say "Awake until caff off$note"
    fi
    ;;
  *)
    echo "usage: caff.sh preview|run [arg]" >&2
    exit 1
    ;;
esac
