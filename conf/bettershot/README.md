# BetterShot

BetterShot has no sync of its own, so `prefs.json` carries its settings: after-capture actions,
the floating preview layout, region selection, annotation style and the default beautifier look.
Presets BetterShot stores as JSON data appear as `{"$data": ...}`; the save folder is written
under `@HOME@`.

`make nix` seeds them once per Mac. After that, `appsync backup` copies the live settings into the
repo (then commit) and `appsync restore` quits BetterShot, applies the repo settings and relaunches.

Permissions, onboarding, the last region, the file name counter and the cloud upload account stay
on each Mac (`DEVICE_KEYS` in `prefs.py`). Test: `./prefs_test.sh`.
