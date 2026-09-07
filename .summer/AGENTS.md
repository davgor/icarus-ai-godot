# Agent Notes

This is a Godot 4 / GDScript project. Summer Engine is an optional editor, not a runtime dependency.

## Before changing code

1. Inspect the existing system.
2. Understand relevant interfaces.
3. Identify existing tests.
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

## After implementation

1. Run `.\scripts\test.ps1`
2. Run `.\scripts\build.ps1` when the change should be playable
3. Launch the game when appropriate
4. Inspect runtime errors
5. Fix failures
6. Report exactly what changed

Never declare a feature complete merely because the code compiles.

## Boundaries

- Do not add Summer SDK or other editor-only APIs to game runtime code.
- Do not implement Living Town / RPG systems during bootstrap unless asked.
- Generative AI is not the authority for game state.
