# Tooling

The game must remain a normal Godot 4 project. Summer Engine is optional development infrastructure.

## Engine binary

Canonical scripts look for a Godot-compatible editor in this order:

1. `GODOT_BIN`
2. `godot` on `PATH`
3. `%LOCALAPPDATA%\SummerEngine\current\Summer.exe`

Summer's editor binary understands the same `--headless`, `-s`, `--export-release`, and `--path` flags as Godot 4.7.

## Cursor + Summer MCP

Project MCP config: [`.cursor/mcp.json`](../.cursor/mcp.json).

After cloning:

1. Open this folder in Cursor.
2. Open the same folder in Summer Engine (`npx --yes summer-engine run .`).
3. Confirm `summer-engine` appears under Cursor Settings → MCP.

If MCP tools are missing, restart Cursor so it reloads `.cursor/mcp.json`.

MCP is for scene inspection, node edits, running the game, and diagnostics. Do not call Summer SDK APIs from game runtime code.

## Canonical commands

| Command | Meaning |
| --- | --- |
| `.\scripts\test.ps1` | Run the automated validation suite |
| `.\scripts\build.ps1` | Test, export, and write a uniquely identified local build |
| `.\scripts\play.ps1` | Launch the newest local build, or the project in game mode |

Agents should run `test` after implementation and `build` before calling a change playable.

## Tests

Headless GDScript in `tests/` extends `SceneTree` and calls `quit(code)`. The wrapper:

- syntax-checks scripts with `--check-only`
- times out hung runs
- fails if stdout lacks `TEST_RESULT: PASS`
- fails if stderr contains `SCRIPT ERROR` or `Parse Error`

Do not add GUT or other addons until the current runner is insufficient.

## Builds

Outputs go to `builds/` (gitignored). Each build writes `BUILD.txt` with:

- monotonic build id (git commit count plus working-tree fingerprint)
- commit hash
- platform
- test/export status

`.\scripts\play.ps1` launches `builds/latest/`.
