# Alfred 5

Alfred reads its settings straight from `Alfred.alfredpreferences` here: `make nix` points
Alfred's preferences folder at it (`~/Library/Application Support/Alfred/prefs.json`). Changes in
Alfred Preferences land in the repo as you make them; commit them.

- `preferences/` - features, terminal (opens `>` commands in a new herdr tab), clipboard retention.
- `preferences/local/<hash>/` - per-Mac settings: Cmd+Space hotkey, clipboard on/off, snippet
  auto-expand. A new Mac copies them once from the Mac that last seeded: launch Alfred, then
  rerun `make nix`.
- `snippets/`, `workflows/` - Gallery workflows update themselves in place.
- `workflows/user.workflow.caffeinate/` - `caff 1h`, `caff 30m`, `caff off` (also `decaf`, `uncaffeinate`). Blocks every sleep, display unplug included, via a sudoers rule in `src/darwin.nix`.

`appsync restore` relaunches Alfred after a pull. Out of git: `remote/` (Alfred Remote cache) and
`workflows/*/prefs.plist` (workflow configuration, which can hold API keys). The license and the
clipboard history stay in `~/Library/Application Support/Alfred`.

Tests: `./alfred_test.sh`, `Alfred.alfredpreferences/workflows/user.workflow.caffeinate/caff_test.sh`.
