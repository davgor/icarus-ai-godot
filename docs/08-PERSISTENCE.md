# 08 — Persistence

```text
BASE WORLD  (seed + constitution)
+ DETERMINISTIC GENERATION
+ PERSISTED MUTATIONS
= CURRENT WORLD
```

Do not require serializing every generated bush. Persist **changes** (and anything the player could notice that generation would not stably recreate).

Example:

```json
{
  "entity_id": "world_481927.region_17.town_2.npc_41",
  "base_seed": 918273,
  "mutations": {
    "relationship_player": 0.82,
    "occupation": "innkeeper",
    "alive": true
  }
}
```

Regenerate from seed, then apply mutation history. Meaningful mutations should have **provenance** when practical.

---

## What we already locked

From [`game-design.md`](game-design.md):

- Character body, race tag, path XP, **loadout**, **outfit** persist across quit/relaunch and hub ↔ world.
- Worn loadout travels through the portal both ways. Sanctum storage is later (materials + unequipped finds).
- Hub / Sanctum save is distinct from world saves.
- Sanctum level, farm plots, placed buildings, and the **home-design catalog** (player unlocks of `catalog_id`s) persist on the hub save.
- The **shipped content catalog** (approved buildings/items/props) lives in the repo, not in the save ([`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md)).
- 100% trust companions persist on the hub roster (loadout, outfit, levels, affinities) and travel when selected into a field slot.
- Story-only recruits stay in that world until the trust gate.
- Prompt text is stored with a prompted world for Continue.

A “previous world” Continue path is resume-of-mutations, not a new compile.

Party wipe retreats to last heal node or entrance; loadout is kept.

---

## Schema

Version saves. Migrate. The Living Town `user://living_town_v1.json` prototype is not the destination schema.
