# nix

## Installation

```
git clone git@github.com:Quentin-M/nix.git ~/.config/nixpkgs
./scripts/install.sh
```

## Post-installation

### MacOS

Launch each app once, grant what it asks in System Settings → Privacy & Security, and turn on
`Launch at login` in its settings:

| App | Permissions | Notes |
| --- | --- | --- |
| Tinycast | Accessibility | Cmd+Space is set by nix (Spotlight's shortcut is disabled). Settings → Extensions: turn on, then Search extensions → install **Coffee** (`caff` → "Caffeinate for…", type a duration) |
| Loop | Accessibility | |
| Thaw | Accessibility, Screen Recording | |
| Hammerspoon | Accessibility | Volume keys -> Wave Link |
| Better Shot | Screen Recording, Accessibility | Input Monitoring for cursor effects, Microphone/Camera for narrated recordings |
| Stats | | |
| OpenDisk | Full Disk Access, to scan system folders | No login item needed |

- Set 1Password to Cmd+Shift+P
  - Enable its menu bar icon to keep it alive

- Wave Link: install the Marketplace plugins listed in `conf/wavelink/README.md`

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