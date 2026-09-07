# Icarus AI

A single-player, persistent sandbox RPG built around autonomous characters, emergent stories, and a world that continues while you are away.

This is a personal game first. Optimize for fun, iteration speed, and experimentation.

> **Build the game I want to come home and play.**

The long-term charter lives in [`docs/vision.md`](docs/vision.md). This README is the short path from clone to a playable loop.

## Current milestone

The **edit → test → build → play** loop is proven. The graybox walker exists to keep that pipeline cheap. Next game milestone, when asked, is The Living Town.

Agents must follow [`docs/agent-operating-loop.md`](docs/agent-operating-loop.md). Do not invent a second test/build/play path.

## Requirements

- [Godot 4.7](https://godotengine.org/) **or** [Summer Engine](https://summerengine.com/) (Godot-compatible editor)
- Git
- Windows PowerShell (canonical commands below)

Set `GODOT_BIN` if the editor is not on `PATH` and Summer Engine is not installed in the default location.

## Canonical commands

From the repository root:

| Intent | Command |
| --- | --- |
| Validate | `.\scripts\test.ps1` |
| Produce a playable build | `.\scripts\build.ps1` |
| Play the newest build | `.\scripts\play.ps1` |

`scripts\test.cmd`, `scripts\build.cmd`, and `scripts\play.cmd` call the same PowerShell entry points.

The game is a normal Godot 4 project. Summer Engine is an optional development environment, not a runtime dependency.

## Project layout

```text
/
├── project.godot
├── game/            # playable Godot content
├── tests/           # headless validation
├── scripts/         # canonical test / build / play commands
├── tools/           # development helpers (not shipped)
├── docs/            # charter and workflow
├── builds/          # local playable outputs (gitignored)
└── .github/         # PR template and lightweight CI
```

## Development environment

Three layers stay loosely coupled:

1. **Game** — Godot 4, GDScript, scenes, resources, save data
2. **Tools** — Cursor, Summer Engine, Git, scripts, CI
3. **AI** — coding agents, later NPC cognition

Coding agents should treat Git as source of truth, work on feature branches, and never treat the working tree as disposable.

Summer MCP setup for Cursor is in [`.cursor/mcp.json`](.cursor/mcp.json). The Summer editor must be open on this project for scene/runtime MCP tools. See [`docs/tooling.md`](docs/tooling.md).

## Git

Prefer:

```text
feature branch → implement → test → review → merge
```

Details: [`docs/git-workflow.md`](docs/git-workflow.md).

## What this is not yet

Not the Living Town. Not combat, NPCs, saves, or dungeons. Those start when asked, using the proven loop above.
