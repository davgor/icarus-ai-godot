# 02 — World compiler

The world behaves like a compiler. The LLM does **not** emit the final game world as prose or as a scene tree.

```text
USER PROMPT  (or silent random intent)
     │
     ▼
WORLD CONSTITUTION   (structured constraints)
     │
     ▼
MASTER SEED
     │
     ▼
MACRO GENERATION
     │
     ▼
REGIONAL / SETTLEMENT / NPC / FACTION / EVENT SEEDS
     │
     ▼
PLAYABLE WORLD  (engine state + lazy materialization)
```

Agents translate creative intent into **structured decisions**. Deterministic systems turn those into state. Validation sits between the model and any mutation ([`04-SIMULATION.md`](04-SIMULATION.md)).

The **Sanctum** (hub) is **not** compiled from the world prompt. The Sanctum is the player’s persistent home ([`game-design.md`](game-design.md)). Worlds hang off the portal.

---

## Constitution (example, not a frozen schema)

```json
{
  "genre": "fantasy",
  "tone": "dark_adventure",
  "magic_prevalence": 0.3,
  "government": "feudal",
  "major_conflict": "border_war",
  "religious_structure": "authoritarian",
  "monster_activity": 0.7
}
```

Prompted-world text is stored with the world for Continue ([`game-design.md`](game-design.md) open questions still include versioning/display). Race tags, companion roster, and player loadout are **not** in the constitution; they are character/hub state that enters the world.

Random new worlds skip the player prompt and still produce a constitution from the master seed.

---

## Rules

- Untrusted input: prompts, NPC speech, agent plans.
- Engine commits: maps, NPCs, inventories, time, combat results.
- Compiler UI is part of the game ([`01-GAMEPLAY-LOOP.md`](01-GAMEPLAY-LOOP.md)).
- Child content derives from seeds ([`03-SEED-ARCHITECTURE.md`](03-SEED-ARCHITECTURE.md)), then lazy-fills ([`07-LAZY-GENERATION.md`](07-LAZY-GENERATION.md)).

Settlements and loot should feel **stocked**. The compiler places **approved catalog** buildings, items, and props by id — it does not invent mesh paths as free prose. Generate → approve → ship catalog is [`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md). Players learn collectible entries in-world; they do not start owning the whole library.

**NPCs and faces** use the **character creator** vocabulary only ([`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md)). Compiler/directors sample creator-legal `CharacterRecord` slices; they do not invent one-off character art.
