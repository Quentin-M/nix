# DockDoor Pro

DockDoor Pro replaces the macOS Dock. It has no iCloud sync, so this folder carries its settings:

- `prefs.json` - every setting, dock profiles and widgets included. Every Mac gets the same
  file; pick the profile for the machine inside DockDoor.
- `icons/` - custom dock icons, referenced as `@ICONS@/<uuid>.png`.

`make nix` seeds them once per Mac. After that, sync by hand:

- `appsync backup` - copy the live settings into the repo, then commit.
- `appsync restore` - quit DockDoor Pro, apply the repo settings, relaunch.

The license token, updater state, window frames, onboarding state, file-tray bookmarks and the
profile picked per display stay on each Mac (`DEVICE_KEYS` in `prefs.py`). Grant Accessibility
and Screen Recording once per Mac.

`nas-folder.swift` draws an SF Symbol embossed on the macOS folder icon, like Downloads:
`swift nas-folder.swift out.png "$(mktemp -d)" server.rack`.
