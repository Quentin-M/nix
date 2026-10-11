#!/bin/bash -ex
darwin-uninstaller
/nix/nix-installer uninstall

rm -rf /etc/zshrc
rm -rf /etc/zshenv
rm -rf /etc/profile.d/nix.sh*

# macos
sudo mv /etc/zshrc.backup-before-nix /etc/zshrc
sudo mv /etc/bashrc.backup-before-nix /etc/bashrc
sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc

sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo rm /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo launchctl unload /Library/LaunchDaemons/org.nixos.darwin-store.plist
sudo rm /Library/LaunchDaemons/org.nixos.darwin-store.plist

sudo dscl . -delete /Groups/nixbld
for u in $(sudo dscl . -list /Users | grep _nixbld); do sudo dscl . -delete /Users/$u; done

sudo rm -rf /etc/nix /var/root/.nix-profile /var/root/.nix-defexpr /var/root/.nix-channels ~/.nix-profile ~/.nix-defexpr ~/.nix-channels /nix
sudo diskutil apfs deleteVolume /nix

# linux
for i in $(seq 1 32); do userdel nixbld$i; done
groupdel nixbld
rm -rf /nix
find /etc/systemd | grep nix | xargs rm
systemctl daemon-reload
