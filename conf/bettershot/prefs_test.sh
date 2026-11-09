#!/usr/bin/env bash
# prefs.py backup/restore on synthetic plists: device keys stay local, Data presets round-trip, home rewritten.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

python3 -I - "$tmp" <<'EOF'
import plistlib, sys
t = sys.argv[1]
mac_a = {
    "bs_copyAfterSave": True,
    "bs_saveDirectory": "/Users/alice/Pictures/Screenshots",
    "annotationStylePreset": b'{"strokeWidth":4,"swatchID":"red"}',
    "bs_lastRegionRect": "{{1, 2}, {3, 4}}",
    "bs_screenCaptureGranted": True,
    "bs_r2_publicBaseURL": "https://bucket.example",
    "NSWindow Frame Settings": "0 0 10 10",
}
mac_b = {
    "bs_copyAfterSave": False,
    "bs_lastRegionRect": "{{9, 9}, {9, 9}}",
    "bs_screenCaptureGranted": False,
    "bs_r2_publicBaseURL": "https://other.example",
}
plistlib.dump(mac_a, open(f"{t}/a.plist", "wb"))
plistlib.dump(mac_b, open(f"{t}/b.plist", "wb"))
EOF

python3 -I "$here/prefs.py" backup "$tmp/a.plist" "$tmp/prefs.json" /Users/alice
python3 -I "$here/prefs.py" restore "$tmp/prefs.json" "$tmp/b.plist" "$tmp/out.plist" /Users/bob

python3 -I - "$tmp" <<'EOF'
import json, plistlib, sys
t = sys.argv[1]
repo = json.load(open(f"{t}/prefs.json"))
out = plistlib.load(open(f"{t}/out.plist", "rb"))
fail = 0
def check(want, got, label):
    global fail
    ok = want == got
    fail |= not ok
    print(("ok   " if ok else "FAIL ") + label + ("" if ok else f": want {want!r} got {got!r}"))
check(sorted(["annotationStylePreset", "bs_copyAfterSave", "bs_saveDirectory"]), sorted(repo), "repo holds only shared keys")
check("@HOME@/Pictures/Screenshots", repo["bs_saveDirectory"], "repo has no home path")
check({"$data": {"strokeWidth": 4, "swatchID": "red"}}, repo["annotationStylePreset"], "Data preset readable in repo")
check(True, out["bs_copyAfterSave"], "restore applies shared settings")
check("/Users/bob/Pictures/Screenshots", out["bs_saveDirectory"], "restore rewrites home")
check({"strokeWidth": 4, "swatchID": "red"}, json.loads(out["annotationStylePreset"]), "Data preset round-trips")
check(bytes, type(out["annotationStylePreset"]), "Data preset restored as Data")
check("{{9, 9}, {9, 9}}", out["bs_lastRegionRect"], "device key kept from live")
check(False, out["bs_screenCaptureGranted"], "permission flag kept from live")
check("https://other.example", out["bs_r2_publicBaseURL"], "cloud account kept from live")
check(False, "NSWindow Frame Settings" in out, "window state not imported")
sys.exit(fail)
EOF

python3 -I -c 'import plistlib,sys; plistlib.dump({"blob": b"\x00\x01"}, open(sys.argv[1], "wb"))' "$tmp/bad.plist"
if python3 -I "$here/prefs.py" backup "$tmp/bad.plist" "$tmp/bad.json" /Users/alice 2>/dev/null; then
  echo "FAIL non-JSON data accepted"; exit 1
fi
echo "ok   non-JSON data refused"
