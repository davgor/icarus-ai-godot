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

Project MCP servers often stay **disabled until approved**. After a Cursor restart, open Settings → MCP and enable `summer-engine` if tools are still missing.

The proven inspect → modify → play → inspect cycle, including value formats and traps, is in [`agent-operating-loop.md`](agent-operating-loop.md).

## Character creator in tooling

The creator is **dev-tooling exposed**, not only a New Game UI:

| Need | Approach |
| --- | --- |
| Inspect atelier | Summer: open creator `scenePath`, tree, lights, preview |
| Preview any face | Apply a valid schema v1 `CharacterRecord` to the preview (same applier as runtime) |
| Verify generated NPCs | Round-trip: record → apply → serialize; reject illegal catalog ids |
| Add a new look | Add part to creator catalog + UI first; then world gen may sample it |

**Rule:** any character generated in the game must be makeable in the creator ([`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md)). Do not ship unique NPC meshes that the creator cannot rebuild.

## Git LFS

Generated art and audio (`.glb`, textures, audio, HDR) are stored with [Git LFS](https://git-lfs.com/). `.import`, GDScript, scenes, and docs stay in normal Git.

After clone (Git for Windows already ships `git-lfs`):

```powershell
git lfs install
git lfs pull
```

`.\scripts\test.ps1` fails if `game/art` still contains LFS pointer files instead of real payloads.

This repo did **not** rewrite history when LFS was added. Old commits still embed the original blobs; new commits store pointers. Shrinking clone size would take a later `git lfs migrate` plus a coordinated history rewrite — do not force-push `main` for that unless asked.

Do not add large binaries outside these LFS patterns. If GitHub’s compare UI times out on an asset PR, merge from Git locally (`git checkout main; git merge feat/…; git push origin main`) instead of opening a second copy of the files.

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

If `builds/latest/IcarusAI.exe` is locked because the game is running, the build must still succeed; the new exe is under `builds/windows/` and `builds/<id>-<commit>/`.

Export preset name is `WindowsDesktop` (no space).
