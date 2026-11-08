# DockDoor Pro

DockDoor Pro replaces the macOS Dock. It has no iCloud sync, so this folder carries its settings:

- `prefs.home.json` / `prefs.pro.json` - every setting, dock profiles and widgets included.
- `icons/` - custom dock icons, referenced as `@ICONS@/<uuid>.png`.

`make nix` seeds them on a Mac where DockDoor was never configured. After that, sync by hand:

- `dockdoor backup` - copy the live settings into the repo, then commit.
- `dockdoor restore` - quit DockDoor Pro, apply the repo settings, relaunch.

The license token, updater state, window frames, onboarding state and file-tray bookmarks stay
on each Mac (`DEVICE_KEYS` in `prefs.py`). Grant Accessibility and Screen Recording once per Mac.

`nas-folder.swift` draws an SF Symbol embossed on the macOS folder icon, like Downloads:
`swift nas-folder.swift out.png "$(mktemp -d)" server.rack`.
