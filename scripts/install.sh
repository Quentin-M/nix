#!/bin/bash -ex
cd "$(dirname "$0")/.."

# Install nix
if [[ ! -e /nix/var/nix/profiles/default/bin/nix ]]; then
  curl -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
fi
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Darwin
if [[ $OSTYPE == 'darwin'* ]]; then
  # Build as the user, then switch with the pinned nix-darwin's own darwin-rebuild.
  # src/darwin.nix moves installer/IT-written /etc shell rc files aside on activation.
  system=$(nix build --no-link --print-out-paths ".#darwinConfigurations.$(scutil --get LocalHostName).system")
  sudo "$system/sw/bin/darwin-rebuild" switch --flake .
# Linux
else
  # Remove any existing backup files to avoid interactive prompts
  find ~ -maxdepth 3 -name '*.backup' -type f -delete 2>/dev/null || true
  find /etc -maxdepth 3 -name '*.backup' -type f -delete 2>/dev/null || true
  nix run home-manager/release-26.05 -- switch -b backup --flake .
fi

# First interactive shell installs zim modules and compiles the fsh theme (conf/zsh/zshrc)
zsh --login --interactive -c true
