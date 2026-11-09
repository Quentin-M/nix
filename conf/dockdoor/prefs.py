"""DockDoor Pro prefs plist <-> diffable repo JSON.

backup  <live.plist> <out.json> <home> <live-icons-dir> <repo-icons-dir>
restore <in.json> <live.plist> <out.plist> <home> <live-icons-dir>

DockDoor stores profiles and widgets as JSON strings; they are expanded to objects under
{"$json": ...} so diffs stay readable, and folded back on restore.
"""
import json
import os
import plistlib
import shutil
import sys

# Bound to this Mac or to one app session: never synced, kept from live on restore.
DEVICE_KEYS = {
    "cachedEntitlement",  # license token
    "desktopProfileMapping",  # profile per display and desktop, keyed by local ids
    "desktopProfileSessions",
    "displayProfileMapping",
    "fileTrayPinnedFolders",  # security-scoped bookmarks
    "hasCompletedOnboarding",  # onboarding grants permissions on each Mac
    "knownSettingsSearchIDs",
    "lastAutomaticBackupDate",
    "licenseValidatedBuild",
    "marketplaceWidgetIdsWithUpdates",
    "nativeDockWasAutohidden",
    "seenNewSettingIDs",
    "settingsWindowVisible",
    "setupIntroStep",
    "stashedWindowIDs",
}
DEVICE_PREFIXES = ("SU", "NS")  # Sparkle updater, AppKit window and panel state
SECRET_MARKERS = ("license_key", "device_id", "signedData")

HOME, ICONS = "@HOME@", "@ICONS@"


def device_bound(key):
    return key in DEVICE_KEYS or key.startswith(DEVICE_PREFIXES)


def expand(value):
    if isinstance(value, list):
        return [expand(v) for v in value]
    if isinstance(value, str) and value[:1] in "{[":
        try:
            return {"$json": json.loads(value)}
        except ValueError:
            return value
    return value


def fold(value):
    if isinstance(value, dict) and set(value) == {"$json"}:
        return json.dumps(value["$json"], separators=(",", ":"))
    if isinstance(value, list):
        return [fold(v) for v in value]
    return value


def rewrite(value, pairs):
    if isinstance(value, str):
        for old, new in pairs:
            value = value.replace(old, new)
        return value
    if isinstance(value, list):
        return [rewrite(v, pairs) for v in value]
    if isinstance(value, dict):
        return {k: rewrite(v, pairs) for k, v in value.items()}
    return value


def icon_paths(value, live_icons):
    if isinstance(value, str):
        return [value] if value.startswith(live_icons + "/") else []
    items = value.values() if isinstance(value, dict) else value if isinstance(value, list) else []
    return [p for v in items for p in icon_paths(v, live_icons)]


def backup(live_plist, out_json, home, live_icons, repo_icons):
    with open(live_plist, "rb") as f:
        live = plistlib.load(f)
    synced = {}
    for key, value in live.items():
        if device_bound(key):
            continue
        if isinstance(value, (bytes, bytearray)):
            raise SystemExit(f"dockdoor: {key} holds binary data; add it to DEVICE_KEYS or handle it")
        synced[key] = expand(value)
    for path in icon_paths(synced, live_icons):
        shutil.copy2(path, os.path.join(repo_icons, os.path.basename(path)))
    # Icons dir first: it sits under home.
    synced = rewrite(synced, [(live_icons, ICONS), (home, HOME)])
    text = json.dumps(synced, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    if any(marker in text for marker in SECRET_MARKERS):
        raise SystemExit("dockdoor: a license field leaked into the synced keys; refusing to write")
    with open(out_json, "w") as f:
        f.write(text)


def restore(in_json, live_plist, out_plist, home, live_icons):
    with open(in_json) as f:
        synced = json.load(f)
    with open(live_plist, "rb") as f:
        live = plistlib.load(f)
    merged = {k: v for k, v in live.items() if device_bound(k)}
    for key, value in rewrite(synced, [(ICONS, live_icons), (HOME, home)]).items():
        merged[key] = fold(value)
    with open(out_plist, "wb") as f:
        plistlib.dump(merged, f)


if __name__ == "__main__":
    {"backup": backup, "restore": restore}[sys.argv[1]](*sys.argv[2:])
