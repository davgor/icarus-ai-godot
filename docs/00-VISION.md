# 00 — Vision

A single-player, persistent anime-fantasy RPG. The player inhabits worlds that can be resumed, rolled, or compiled from natural-language intent. Characters, factions, history, and events evolve whether or not the player is looking.

> **Build the game I want to come home and play.**

> **Give the player the feeling that they have entered a world that could continue existing without them.**

This is a personal game first: fun to play, cheap to experiment with, capable of growing if it ever earns a team. Until then: **optimize for fun, iteration speed, and experimentation.**

The primary design goal is **not** AI-generated dialogue. Dialogue is a surface. The goal is a world that persists, remembers, and keeps moving.

Player-facing systems (hub, creator, combat, parkour, companions, gear, art) are locked in [`game-design.md`](game-design.md). This note is the charter. Bundle index: [`README.md`](README.md).

---

## What the player does

1. Boot to title (New / Load / Settings / Quit).
2. Create or load a character (Code Vein-depth creator on New).
3. Live in the **Sanctum** (floating hub rock; empty at first except the portal; filled by 100% trust companions).
4. At the portal: continue a world, roll a new random one, or **prompt** one.
5. For prompted / new-compile worlds: watch the **world compiler** work (that screen is gameplay).
6. Pick up to two field companions from the roster (empty allowed).
7. Enter, play (explore, parkour, fight, recruit, change things).
8. Leave through the portal. State persists.
9. Return later and discover consequences.

The world is **deterministic where possible, agentic where useful, persistent once materialized.**

---

## Technology

- Godot 4 / GDScript
- Summer Engine as an **optional editor**, not a runtime dependency
- Cursor, Git, local hardware
- AI-assisted development; later, constrained NPC cognition

If Summer disappeared, `GODOT_BIN` or `godot` on `PATH` must still test, export, and run. Do not make architecture depend on Summer SDK.

Layers stay loosely coupled: **game** / **tools** / **AI**. Generative AI is never the authority for game state. The engine owns reality.

Favor: deterministic systems, explicit state, structured data, tool calls, batched cognition, local inference where practical, tests, playable builds, small composable systems.

Architectural priority order: iteration speed, fun, debuggability, determinism, modularity, persistence, agent accessibility, local execution, performance, visual fidelity. Simple first; refactor when the pain is real.

---

## Milestones (do not skip)

1. **Bootstrap** — proven: Cursor edit → `.\scripts\test.ps1` → build → play.
2. **First playable** — Sanctum hub loop in [`feature-list.md`](feature-list.md) (title, creator, empty Sanctum, parkour, portal, persist worn loadout). Not a pre-filled town.
3. **World nucleus** — the “holy shit” test in [`01-GAMEPLAY-LOOP.md`](01-GAMEPLAY-LOOP.md): compile, meet someone, change something, leave, return, they remember why.
4. **Expansion** — combat depth, art, huge maps, roster, romance. Architecture exists so we can keep stuffing features **without violating the locks above**.

The architecture is a place to grow. It is not permission to undecide the hub, the controller, or companion rules.

---

## The rule

The first version succeeds when:

> I can come home after work, launch the game, create or load a character, spend 30–60 minutes doing whatever sounds fun, quit, and genuinely want to see what happened when I return.
