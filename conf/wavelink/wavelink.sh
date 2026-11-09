#!/usr/bin/env bash
# Wave Link config <-> repo, driven by appsync. Wave Link rewrites config.json atomically while
# running, so it can't be a symlink: backup copies live -> repo, restore copies repo -> live.
set -euo pipefail
live="$HOME/Library/Application Support/com.elgato.WaveLink3/config.json"
repo="$(cd "$(dirname "$0")" && pwd)/config.json"

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
  seed)
    # make nix: only a Mac without a Wave Link config gets the repo one.
    if [[ ! -f $live ]]; then
      mkdir -p "$(dirname "$live")"
      cp "$repo" "$live"
      chmod 644 "$live"
      echo "wavelink: seeded from $repo"
    fi
    for c in MONOCORE ElgatoNoiseRemoval ElgatoCompressor ElgatoEq ElgatoDeEsser; do
      ls -d "$HOME/Library/Audio/Plug-Ins/Components/$c"*.component &>/dev/null \
        || echo "Wave Link: install the $c plugin from Marketplace"
    done
    ;;
  level)
    # Break-glass for the main-output mix level: Wave Link's UI has no slider for it.
    rpc() {
      (jq -nc --arg m "$1" --argjson p "${2:-null}" '{jsonrpc:"2.0",id:1,method:$m} + if $p then {params:$p} else {} end'
       sleep 0.5) | websocat -t --origin streamdeck:// ws://127.0.0.1:1884 | jq -c .result
    }
    mix="$(rpc getOutputDevices | jq -r '.mainOutput as $m | .outputDevices[]
      | select(.id == $m.outputDeviceId) | .outputs[] | select(.id == $m.outputId) | .mixId')"
    [[ -n "$mix" ]] || { echo "wavelink: no mix on the main output (is Wave Link running?)" >&2; exit 1; }
    if [[ -n "${2:-}" ]]; then
      jq -en --argjson l "$2" '$l >= 0 and $l <= 1' >/dev/null 2>&1 \
        || { echo "wavelink: level must be 0..1, got '$2'" >&2; exit 1; }
      rpc setMix "$(jq -nc --arg id "$mix" --argjson l "$2" '{id:$id, level:$l, isMuted:false}')" >/dev/null
    fi
    rpc getMixes | jq -r --arg id "$mix" '.mixes[] | select(.id == $id) | "\(.name) \(.level * 100 | round)%\(if .isMuted then " muted" else "" end)"'
    ;;
  *)
    echo "usage: wavelink.sh backup|restore|seed|level [0..1]" >&2
    exit 1
    ;;
esac
