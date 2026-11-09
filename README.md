# nix

## Installation

```
git clone git@github.com:Quentin-M/nix.git ~/.config/nixpkgs
./scripts/install.sh
```

## Post-installation

### MacOS

Launch each app once and grant what it asks in System Settings → Privacy & Security. Nix sets
Login Items from `loginItems` in `conf/pkgs/homebrew.nix`:

| App | Permissions | Notes |
| --- | --- | --- |
| Alfred 5 | Accessibility | Activate the Powerpack (Mega Supporter) license. Settings live in `conf/alfred` (`conf/alfred/README.md`); on a fresh Mac launch Alfred once, then rerun nix for the Cmd+Space hotkey (Spotlight's shortcut is disabled) |
| Dimble | Accessibility, Screen Recording | Screen Recording is optional: animations and Live Activities need it |
| DockDoor Pro | Accessibility, Screen Recording | Replaces the Dock. Settings: `conf/dockdoor/README.md`. Paid: $20 license, 14-day trial |
| Hammerspoon | Accessibility | Volume keys -> Wave Link |
| Better Shot | Screen Recording, Accessibility | Input Monitoring for cursor effects, Microphone/Camera for narrated recordings |
| Stats | | |
| LuLu (personal only) | System Settings → General → Login Items & Extensions → Network Extensions: allow LuLu, then Allow its filter configuration | |
| OpenDisk | Full Disk Access, to scan system folders | |

- Set 1Password to Cmd+Shift+P
  - Enable its menu bar icon to keep it alive

- Wave Link: install the Marketplace plugins listed in `conf/wavelink/README.md`

- App settings (DockDoor Pro, Wave Link, Alfred): `appsync backup` copies live settings into the
  repo, then commit; `appsync restore` applies the repo settings after a pull

## TODO

Test the YouTube Music TUIs on a Mac with YouTube Premium (log in to music.youtube.com in Chrome first):
```
ytm setup && ytm                                   # ytm-player, reads Chrome cookies
ymc login && ymc whoami && ymc                     # youtube-music-cli, OAuth device flow
ymc login --cookies-from-browser chrome            # ymc fallback if OAuth fails
```
Keep the better one, drop the other from `conf/pkgs/homebrew.nix` / `src/home.nix`.

## Update & Testing

Once you have updated any of nixpkgs configuration, execute the following command to update the live configuration & test the changes:
```
git add . && make nix
```

If herdr needs to be fully restarted (not just reloaded with Prefix+r):
```
herdr server stop
```