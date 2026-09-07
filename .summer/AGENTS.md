# Agent Notes

This is a Godot 4 / GDScript project. Summer Engine is an optional editor, not a runtime dependency.

**Follow [`docs/agent-operating-loop.md`](../docs/agent-operating-loop.md).** That document is the proven path. Do not invent a parallel test, build, play, or scene workflow.

## Before changing code

1. Inspect the existing system.
2. Understand relevant interfaces.
3. Identify existing tests (`tests/run_tests.gd`, `.\scripts\test.ps1`).
4. Avoid duplicate systems.
5. Put the change in an existing abstraction when one already fits.

## During implementation

- Keep changes focused.
- Prefer small composable systems.
- Preserve deterministic behavior.
- Avoid unnecessary dependencies and hidden global state.
- Keep authoritative state in the engine.
- Treat LLM output as untrusted input.
- Do not rewrite unrelated systems.
- Do not add Summer SDK to game runtime code.
- Do not name fields `test_move` on physics bodies.

## After implementation

1. Run `.\scripts\test.ps1`
2. If Summer MCP is connected: play, wait, `summer_get_diagnostics`, fix
3. Run `.\scripts\build.ps1` when the change should be playable
4. Launch with `.\scripts\play.ps1` when appropriate
5. Report exactly what changed

Never declare a feature complete merely because the code compiles.

## Canonical paths

- Main scene: `res://game/main.tscn`
- Export preset: `WindowsDesktop`
- Player test hook: `forced_move_input`
- Art style lock: [`docs/art-style.md`](../docs/art-style.md)
- Generation prompt lock: [`docs/art/prompt-lock.md`](../docs/art/prompt-lock.md)
- Style reference stills: `res://game/art/_style/`
- Movement lock: [`docs/game-design.md`](../docs/game-design.md) (section Movement)
- Companion lock: [`docs/game-design.md`](../docs/game-design.md) (section Companions)
- Gear vs outfit: [`docs/game-design.md`](../docs/game-design.md) (section Gear and appearance)
- Design bundle: [`docs/README.md`](../docs/README.md)

## Art generation

Before `summer_generate_image`, `summer_generate_3d`, `summer_generate_video`, or any other visual generate/import:

1. Read the style lock and prepend the prompt lock. Do not paraphrase the lock away.
2. Image `style` must be `"anime"`. Default `"realistic"` is wrong.
3. Do not use Kenney / `game/art/town/` prototypes as style references.
4. Import finals under `game/art/{characters,hub,worlds,ui,vfx,gear}/`.
5. To change the look, bump the lock version in both art docs in the same change.
