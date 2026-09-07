# Icarus AI — Vision

A single-player, persistent sandbox RPG built around autonomous characters, emergent stories, and a world that continues to exist beyond the player's immediate control.

The primary goal is simple:

> **Build the game I want to come home and play.**

This is not initially a commercial production project. It is a personal game that should be enjoyable to play, enjoyable to modify, and cheap enough to experiment with continuously.

If it eventually becomes good enough to justify building a team or seeking investment, the architecture should be capable of growing into that.

Until then:

> **Optimize for fun, iteration speed, and experimentation.**

---

## Technology direction

Initial implementation:

- Godot 4
- GDScript
- Summer Engine (evaluated as a development environment)
- Cursor
- Git
- Local development hardware
- AI-assisted development through Cursor / Summer MCP

**Do not make the game's architecture dependent on Summer Engine.** The project must remain a normal, inspectable Godot 4 project, developable with Summer, Godot directly, Cursor, another IDE, or command-line tooling.

## Tooling layers

Keep these loosely coupled:

- **Game** — engine, scenes, resources, systems, assets, save data
- **Development environment** — Summer, Cursor, MCP, Git, CI, scripts, tests
- **AI** — coding agents, later NPC cognition and playtesting

Do not allow a development tool's proprietary functionality to become a runtime dependency unless explicitly justified.

## Development philosophy

This is an AI-native development project. Use AI extensively to accelerate implementation, refactoring, testing, debugging, content, and systems.

**Generative AI must not be the authoritative source of game state.** The game engine owns reality. AI reasons about reality and requests actions through constrained interfaces.

Favor:

- deterministic systems over continuous LLM inference
- explicit state over hidden state
- structured data over prose
- tool calls over free-form world manipulation
- asynchronous / batched AI cognition
- local inference where practical
- automated testing
- continuously playable builds
- small composable systems
- agent-readable interfaces
- rapid iteration

## Player-facing design

What the game *is* (hub village, portal worlds, creator, combat) lives in [`game-design.md`](game-design.md). The ordered backlog is [`feature-list.md`](feature-list.md).

## First playable milestone

Do not attempt the full RPG first. The first meaningful game milestone is the **hub village**: create a character, spawn in an empty home village with a portal, leave through it, return, save, quit, relaunch, and verify the character and worn gear persist.

That hub is the evolved Living Town: it starts empty and is populated later by highly trusted companions, not by a pre-authored cast.

The bootstrap phase before that is proving:

> Cursor can modify the project, Summer can operate it, tests run automatically, and a successful change becomes a playable build.

## Architectural priorities

1. Iteration speed
2. Fun
3. Debuggability
4. Determinism
5. Modularity
6. Persistence
7. Agent accessibility
8. Local execution
9. Performance
10. Visual fidelity

If a system can be implemented simply, implement it simply. Refactor when the pain is real.

## The rule

> **Make the game you want to play.**

The first version succeeds when this is true:

> I can come home after work, launch the game, create or load a character, spend 30–60 minutes doing whatever sounds fun, quit, and genuinely want to see what happened when I return.
