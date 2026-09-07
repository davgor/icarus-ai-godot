# Icarus AI — Design bundle

North star for Cursor and humans. These notes evolve independently. **Repo locks beat outside notes.**

## Priority

If two docs disagree, this order wins:

1. [`game-design.md`](game-design.md) — what the player experiences (hub, creator, combat, parkour, companions, gear)
2. [`art-style.md`](art-style.md) + [`art/prompt-lock.md`](art/prompt-lock.md) — how it looks
3. [`feature-list.md`](feature-list.md) — what to build, in order
4. [`agent-operating-loop.md`](agent-operating-loop.md) — how agents implement
5. Numbered architecture notes below — how worlds, sim, and cognition are structured

The numbered set is the **living architecture**. It does not replace the player-facing lock. An outside draft that skipped the hub, controller, parkour, or companion rules is incomplete; those stay in `game-design.md`.

## Architecture notes

| Note | Owns |
| --- | --- |
| [`00-VISION.md`](00-VISION.md) | Why we build; inhabit a world that continues |
| [`01-GAMEPLAY-LOOP.md`](01-GAMEPLAY-LOOP.md) | Session loop, compiler-as-gameplay, milestones |
| [`02-WORLD-COMPILER.md`](02-WORLD-COMPILER.md) | Prompt → constitution → deterministic world |
| [`03-SEED-ARCHITECTURE.md`](03-SEED-ARCHITECTURE.md) | Hierarchical seeds, provenance |
| [`04-SIMULATION.md`](04-SIMULATION.md) | Engine sim vs cognition |
| [`05-NPC-COGNITION.md`](05-NPC-COGNITION.md) | Structured NPCs, relevance-filtered thought |
| [`06-AGENT-ARCHITECTURE.md`](06-AGENT-ARCHITECTURE.md) | Director hierarchy and contracts |
| [`07-LAZY-GENERATION.md`](07-LAZY-GENERATION.md) | Materialize on approach |
| [`08-PERSISTENCE.md`](08-PERSISTENCE.md) | Seed + mutations, hub vs worlds |
| [`09-GODOT-ARCHITECTURE.md`](09-GODOT-ARCHITECTURE.md) | Sim vs engine; target layout |
| [`10-AI-DEVELOPMENT-WORKFLOW.md`](10-AI-DEVELOPMENT-WORKFLOW.md) | Pointer to the proven agent loop |
| [`11-UE5-MIGRATION.md`](11-UE5-MIGRATION.md) | Portable sim; disposable engine layer |

## Also in `docs/`

| Doc | Owns |
| --- | --- |
| [`game-design.md`](game-design.md) | Player-facing design (source of truth) |
| [`feature-list.md`](feature-list.md) | Ordered backlog |
| [`art-style.md`](art-style.md) | Visual lock |
| [`agent-operating-loop.md`](agent-operating-loop.md) | Test / Summer / play contract |
| [`development-loop.md`](development-loop.md) | Personal edit → play loop |
| [`tooling.md`](tooling.md) | Engine binary, MCP |
| [`git-workflow.md`](git-workflow.md) | Git is source of truth |

`vision.md` is a stub that points at [`00-VISION.md`](00-VISION.md).
