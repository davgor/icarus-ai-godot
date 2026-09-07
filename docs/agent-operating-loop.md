# Agent operating loop

This is the proven development path for this repository. Do not invent a replacement.

Design north star: [`README.md`](README.md). Player-facing locks: [`game-design.md`](game-design.md). This file is **how** to implement, not what the game is.

Verified 2026-09-07 on branch `bootstrap/dev-loop` with Cursor + Summer Engine MCP + `.\scripts\test.ps1` / `build.ps1` / `play.ps1`.

## Layers

Keep these separate:

| Layer | What belongs here | What does not |
| --- | --- | --- |
| Game | Godot 4, GDScript, `game/`, saves | Summer SDK, MCP, Cursor |
| Tools | Cursor, Summer editor, Git, `scripts/` | Runtime gameplay |
| AI | Coding agents, later NPC cognition | Authoritative world state |

The shipped game must remain a normal Godot 4 project. If Summer disappeared, `GODOT_BIN` or `godot` on `PATH` must still test, export, and run.

## Canonical commands

From the repo root, on Windows:

```powershell
.\scripts\test.ps1
.\scripts\build.ps1
.\scripts\play.ps1
```

That is the whole agent-facing build system. Do not add GUT, gdUnit, CMake, npm scripts, or a second runner unless the current `tests/run_tests.gd` SceneTree suite is actually insufficient.

Engine resolution (already implemented in `scripts/lib/engine.ps1`):

1. `GODOT_BIN`
2. `godot` on `PATH`
3. `%LOCALAPPDATA%\SummerEngine\current\Summer.exe`

## After every implementation

1. Inspect the existing system and tests.
2. Review Open tickets in [`backlog/deferred/`](backlog/deferred/) and rope in any that fit this change (same scene/system/art pass). File a new `DEF-NNN` ticket if you newly defer work — do not leave deferrals only in epic “Out of scope” notes. See [`backlog/deferred/README.md`](backlog/deferred/README.md).
3. Make a focused change.
4. Run `.\scripts\test.ps1`.
5. If Summer MCP is connected: play the affected scene, wait, `summer_get_diagnostics`, fix, repeat.
6. `.\scripts\build.ps1` when the change should be playable.
7. `.\scripts\play.ps1` or Summer play as appropriate.
8. Report exactly what changed (include deferred review: roped in / none).

Compiling is not done.

## Summer MCP cycle (proven)

Summer must be open on this project. Project config is `.cursor/mcp.json`. If tools are missing, enable **summer-engine** in Cursor Settings → MCP (project servers can sit disabled until approved). Restarting Cursor is not enough if it is still off.

```text
summer_get_project_context
        ↓
summer_get_diagnostics          ← always this before console/debugger
        ↓
summer_open_main_scene          ← if currentScene is null
        ↓
summer_get_scene_tree(scenePath="res://game/main.tscn")
        ↓
mutate with the same scenePath (add_node / set_prop / …)
        ↓
edit GDScript in Cursor (not Summer SDK)
        ↓
summer_get_script_errors
        ↓
.\scripts\test.ps1
        ↓
summer_clear_console → summer_play → wait → summer_get_diagnostics
        ↓
fix → play → inspect again
        ↓
summer_stop
```

Main scene is **`res://game/main.tscn`**. Do not guess `res://main.tscn`.

Mutations take explicit `scenePath`. Node paths use `./` from the scene root (`./Player`, parent `./`).

Value formats:

```text
❌ "position": { "x": 2, "y": 1, "z": 0 }
✅ "position": "Vector3(2, 1, 0)"
✅ "albedo_color": "Color(1, 0.45, 0.1, 1)"
✅ mesh: "BoxMesh"
```

`summer_screenshot` `target: "scene"` is a synthetic offscreen camera (not lighting truth, not the game camera). `target: "game"` needs the game running.

## Headless tests (proven)

`tests/run_tests.gd` is the suite.

```gdscript
❌ extends Node
❌ extends EditorScript
❌ func _run():           # hangs forever under `engine -s`, no output
✅ extends SceneTree
✅ work from _init / call_deferred("_start")
✅ always quit(code)
✅ print("TEST_RESULT: PASS") or FAIL
```

`--check-only` and a missing script path can still exit 0. `scripts/test.ps1` gates on `TEST_RESULT: PASS` and fails on `SCRIPT ERROR` / `Parse Error`.

Benign and must be ignored: `WARNING: N ObjectDB instance(s) were leaked at exit`.

`-s` headless scripts are safe while the editor is open. **`--import` is not.** `--import` is a full editor boot; it overwrites `~/.summer/api-token` / port and can knock MCP offline. Do not import while Summer is open.

Player movement in tests uses `forced_move_input`, not OS key events.

## Build / export (proven)

- Export preset **name** is `WindowsDesktop` (no space). Platform is still `Windows Desktop`.
- Passing `--export-release "Windows Desktop"` through `Start-Process -ArgumentList @(...)` splits on the space (`Invalid export preset name: Windows`). Quote a single argument string, or keep the preset name spaceless.
- Headless export uses a batch API on another port (observed `6551`) and does not steal the editor on `6550`.
- `builds/latest/IcarusAI.exe` is locked while the game is running. Copy to `builds/windows/` and `builds/<id>-<commit>/` first; updating `latest` is best-effort, not a build failure.
- Playable identity lives in `BUILD.txt` (build id, commit, tree dirty/clean, platform, status).

## GDScript pitfall already hit

`PhysicsBody3D.test_move()` exists. A field named `test_move` produces:

```text
SHADOWED_VARIABLE_BASE_CLASS
The local variable "test_move" is shadowing an already-declared method
in the base class "PhysicsBody3D".
```

Use `forced_move_input`. Summer diagnostics caught this on the first play; compile-only checks did not.

## Asset generation

Do not invent a second art pipeline. Visual generate/import goes through Summer MCP (or an explicit user-named provider) **and** the style lock.

1. Read [`art-style.md`](art-style.md) and [`art/prompt-lock.md`](art/prompt-lock.md).
2. Prepend the lock prefix. Set image `style` to `"anime"` (never default `"realistic"`).
3. Attach `game/art/_style/` stills when they exist. Never use `game/art/town/` Kenney/graybox as style.
4. Generate → `Read` the preview → import into `game/art/{characters,hub,worlds,ui,vfx,gear}/`.
5. To change the look, bump the lock version in both art docs in the same change.

## Do not go back to

- Hand-rolling `godot --headless -s addons/gut/...`
- Calling `godot` and failing because it is not on PATH (use `scripts/lib/engine.ps1`)
- Adding Summer SDK autoloads or `extends SummerGame` to this product
- Using Summer Cloud instead of Git
- Skipping `summer_get_diagnostics` after `summer_play`
- Declaring a scene change complete from a `.tscn` edit with no play/inspect
- Running `--import` against a project whose editor is open
- Treating ObjectDB leak lines as test failures
- Treating engine exit code 0 as test success without `TEST_RESULT: PASS`
- Generating art with Summer’s default `style: "realistic"` or without the art-style lock
- Deferring work only inside an epic footnote without a [`backlog/deferred/`](backlog/deferred/) ticket + source link
- Starting a slice without checking Open deferred tickets for rope-ins
