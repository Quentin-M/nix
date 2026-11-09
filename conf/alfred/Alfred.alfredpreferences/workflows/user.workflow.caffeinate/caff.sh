#!/usr/bin/env bash
# caff [N | Nh | Nm | off]: keep the display awake. N alone is hours; no argument lasts until "caff off".
# Only the caffeinate this script started is stopped: Claude Code and others run their own.
set -euo pipefail
pidfile="${alfred_workflow_data:-$HOME/Library/Application Support/Alfred/Workflow Data/caffeinate}/caffeinate.pid"
usage="Usage: caff 1h | 30m | off"

arg="${1:-}"
args=(-di)
if [[ $arg == off ]]; then
  :
elif [[ $arg =~ ^([0-9]+)(h|hr)?$ ]] && ((10#${BASH_REMATCH[1]} > 0)); then
  n=$((10#${BASH_REMATCH[1]}))
  args+=(-t $((n * 3600)))
  msg="Awake for $n h"
elif [[ $arg =~ ^([0-9]+)(m|min)$ ]] && ((10#${BASH_REMATCH[1]} > 0)); then
  n=$((10#${BASH_REMATCH[1]}))
  args+=(-t $((n * 60)))
  msg="Awake for $n min"
elif [[ -z $arg ]]; then
  msg="Awake until caff off"
else
  echo "$usage"
  exit 0
fi

if [[ -f $pidfile ]]; then
  pid="$(<"$pidfile")"
  [[ $pid =~ ^[0-9]+$ && $(ps -p "$pid" -o command= 2>/dev/null) == *"caffeinate -di"* ]] && kill "$pid"
  rm -f "$pidfile"
fi

if [[ $arg == off ]]; then
  echo "Sleep allowed"
  exit 0
fi

mkdir -p "${pidfile%/*}"
# Detached and silent: Alfred waits for stdout to close before it shows the notification.
nohup caffeinate "${args[@]}" </dev/null >/dev/null 2>&1 &
echo $! > "$pidfile"
echo "$msg"
