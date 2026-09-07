# 07 — Lazy generation

The world does **not** need to be fully generated before the player enters.

```text
MACRO WORLD
    ↓
KNOWN WORLD   (names, rumors, map silhouettes)
    ↓
PLAYER INTEREST / APPROACH
    ↓
REGIONAL → LOCAL → MICRO MATERIALIZATION
```

The player can know Queen Elara, Asterhold, an enemy kingdom, a famous hero, a dangerous forest, without the game having generated distant villagers, house interiors, minor shops, or daily schedules.

Resolution:

```text
Distant → Regional → Local → Fully materialized
```

Cost drops. The illusion of a complete world holds.

---

## Hub vs worlds

The **hub village** is small and should be fully materialized (empty except the portal at first, then residents you brought). Do not lazy-delete someone who lives there.

**Worlds** are lazy. Heal nodes, climbable geo, and the first settlement on the critical path materialize before Enter is offered for v0.1. Everything else can wait until approach.

Known-world facts (names, wars, capitals) live in compact constitution/history records, not in full actor instances.
