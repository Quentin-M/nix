"""BetterShot prefs plist <-> diffable repo JSON.

backup  <live.plist> <out.json> <home>
restore <in.json> <live.plist> <out.plist> <home>

Presets are JSON stored in Data values; they become {"$data": ...} objects so diffs stay readable,
and are encoded back on restore.
"""
import json
import plistlib
import sys

# Bound to this Mac: never synced, kept from live on restore.
DEVICE_KEYS = {
    "bs_fileNameCounter",
    "bs_lastRegionRect",
    "bs_onboardingSeenVersion",  # onboarding grants permissions on each Mac
    "bs_onboardingStep",
    "bs_overlayPinnedDisplayID",
    "bs_releaseNotesSeenVersion",
    "bs_screenCaptureGranted",
}
# AppKit window and panel state, Sparkle updater, cloud upload account
DEVICE_PREFIXES = ("NS", "SU", "bs_r2_")

HOME = "@HOME@"


def device_bound(key):
    return key in DEVICE_KEYS or key.startswith(DEVICE_PREFIXES)


def expand(key, value):
    if isinstance(value, (bytes, bytearray)):
        try:
            return {"$data": json.loads(value)}
        except ValueError:
            raise SystemExit(f"bettershot: {key} holds non-JSON data; add it to DEVICE_KEYS or handle it")
    return value


def fold(value):
    if isinstance(value, dict) and set(value) == {"$data"}:
        return json.dumps(value["$data"], separators=(",", ":")).encode()
    return value


def rewrite(value, old, new):
    if isinstance(value, str):
        return value.replace(old, new)
    if isinstance(value, list):
        return [rewrite(v, old, new) for v in value]
    if isinstance(value, dict):
        return {k: rewrite(v, old, new) for k, v in value.items()}
    return value


def backup(live_plist, out_json, home):
    with open(live_plist, "rb") as f:
        live = plistlib.load(f)
    synced = {k: expand(k, v) for k, v in live.items() if not device_bound(k)}
    with open(out_json, "w") as f:
        f.write(json.dumps(rewrite(synced, home, HOME), indent=2, sort_keys=True, ensure_ascii=False) + "\n")


def restore(in_json, live_plist, out_plist, home):
    with open(in_json) as f:
        synced = json.load(f)
    with open(live_plist, "rb") as f:
        live = plistlib.load(f)
    merged = {k: v for k, v in live.items() if device_bound(k)}
    for key, value in rewrite(synced, HOME, home).items():
        if not device_bound(key):
            merged[key] = fold(value)
    with open(out_plist, "wb") as f:
        plistlib.dump(merged, f)


if __name__ == "__main__":
    {"backup": backup, "restore": restore}[sys.argv[1]](*sys.argv[2:])
