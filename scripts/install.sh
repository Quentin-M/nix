#!/bin/bash -ex

# Install nix
curl -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Darwin
if [[ $OSTYPE == 'darwin'* ]]; then
  sudo mv /etc/zshenv /etc/zshenv.before-nix
  sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .
# Linux
else
  # Remove any existing backup files to avoid interactive prompts
  find ~ -maxdepth 3 -name '*.backup' -type f -delete 2>/dev/null || true
  find /etc -maxdepth 3 -name '*.backup' -type f -delete 2>/dev/null || true
  nix run home-manager/release-26.05 -- switch -b backup --flake ~/.config/nixpkgs
fi

# Initialize zsh
zsh --login -c "
  echo 'Installing zimfw...'
  . /etc/zshrc
  . ~/.zshenv
  . ~/.config/zsh/.zshrc

  zimfw install

  fast-theme free

  echo 'Building fzf-tab...'
  # Make fzf-tab build non-fatal - will be built on first use if needed
  build-fzf-tab-module || echo 'Note: fzf-tab module build failed, will retry on first shell use'
"
