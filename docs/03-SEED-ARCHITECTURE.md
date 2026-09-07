# 03 — Seed architecture

Seeds are hierarchical. The seed is **baseline reality**. Agentic and player changes are explicit mutations on top ([`08-PERSISTENCE.md`](08-PERSISTENCE.md)).

```text
WORLD SEED
 ├── Geography Seed
 ├── Culture Seed
 ├── History Seed
 ├── Magic Seed
 └── Civilization Seed
       │
       ├── Kingdom Seed
       │    ├── Region Seed
       │    │    ├── Settlement Seed
       │    │    │    ├── Faction Seed
       │    │    │    ├── NPC Seed
       │    │    │    └── Event Seed
       │    │    └── Dungeon Seed
       │    └── ...
       └── ...
```

Child seeds derive deterministically:

```text
child_seed = Hash(parent_seed, type, stable_identifier)
```

That gives reproducibility, stable identity, regeneration, debugging, provenance, and compact storage.

---

## Identity

Prefer stable IDs that encode provenance, e.g. `world_481927.region_17.town_2.npc_41`. Regenerating from seed without mutations must yield the same baseline entity at that ID.

The **hub** has its own save identity. It is not a child of a world seed. Companions who move to the hub keep a stable ID when they leave their birth world.

---

## Player and companions

Character creator output, loadout, outfit, path XP, and roster trust are **not** world seeds. They are character/hub persistence that the world may reference.

NPC baseline (name, occupation, starting faction) can come from an NPC seed. Relationship to the player, romance, jealousy flags, companion affinities, and “alive” are mutations.

---

## Catalog content

Approved **buildings / items / props** live in the content catalog ([`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md)), not as one-off seed prose. A settlement seed may resolve to:

```text
instance = { world_entity_id, catalog_id, transform, mutations }
```

`catalog_id` is stable across worlds. Regenerating a settlement without mutations should pick the same catalog ids for the same child seeds when the selection function is deterministic.
