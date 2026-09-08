# 04 — Simulation

Split **simulation** (engine, authoritative, deterministic) from **cognition** (optional, structured, untrusted until validated).

```text
LLM / director
      ↓
structured decision
      ↓
validation
      ↓
game system
      ↓
world mutation
```

The LLM does not drive Godot nodes, combat math, inventories, or physics.

---

## Deterministic simulation owns

Time, movement, parkour, schedules, combat, downed/heal nodes, economy, inventory, loadout vs outfit, **appearance application** (creator-legal records only), relationships, romance/jealousy flags, faction mechanics, quests, world events, production, population, navigation, physics.

Player-facing rules for combat, parkour, gear, and companions live in [`game-design.md`](game-design.md). This layer **implements** those rules; it does not invent a second combat model.

**Appearance validation:** reject NPC/companion/player mutations that reference unknown creator catalog ids or out-of-range morphs ([`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md)).

---

## Agentic cognition owns (when present)

Interpreting events, updating beliefs, forming goals, memories, what an NPC treats as important, proposing relationship changes, rumors, long-term behavioral *suggestions*.

Cognition emits structured mutations. Simulation applies or rejects them. Runtime path: [`14-AGENT-RUNTIME.md`](14-AGENT-RUNTIME.md) (Statemachine commits; Orchestrator routes; workers only infer).

Jealousy still only applies if NPCs **meet** (same scene). Cognition must not invent off-screen omniscience.

Companion **action-driven growth** (healer vs mage from what they did in fights) is simulation, not an LLM class pick.

---

## Existing bootstrap

`game/sim/game_state.gd` is a Living Town prototype with a pre-seeded cast. Destination hub is the empty Sanctum. Do not grow that prototype as if it were home. New sim should match this split and the Sanctum lock (farm, **Arrange layout**, design catalog, Sanctum level are engine state).
