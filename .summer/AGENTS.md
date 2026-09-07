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
