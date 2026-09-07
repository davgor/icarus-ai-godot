# 05 — NPC cognition

An NPC is primarily **structured state**, not a chat session.

```text
NPC
├── Identity
├── Appearance  (creator-legal CharacterRecord / appearance slice — same catalog as the player)
├── Personality
├── Skills / path XP / affinities
├── Needs
├── Goals
├── Beliefs
├── Memories
├── Knowledge
├── Relationships (incl. player: trust, romance)
├── Occupation
├── Loadout + outfit  (same slot rules as the player; outfit ids from creator catalog)
└── Current State    (location, downed, field-slot, …)
```

Companions are NPCs plus roster/field-slot rules. They are full characters ([`game-design.md`](game-design.md)). No player-built talent tree. Low-level recruits stay plastic; high-level recruits stay mostly locked.

**Appearance:** every NPC/companion face and body must be **makeable in the character creator** ([`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md)). Generators pick catalog ids + morphs; they do not invent unique meshes.

A frontier model does not run every tick.

```text
WORLD EVENTS
      │
      ▼
RELEVANCE FILTER
      │
      ▼
COGNITIVE UPDATE   (batched, async, local if practical)
      │
      ▼
STRUCTURED NPC MUTATIONS
      │
      ▼
DETERMINISTIC BEHAVIOR
```

The player should feel the **results** (they remember why you burned the mill; the shop is closed; a jealous line only if they met the other partner), not a thinking-aloud overlay.

Relevance filter must encode **meet-only** jealousy and hub-vs-world knowledge. An NPC in another world does not witness hub romance.

---

## Holy shit test

Meet → unexpected action → leave → return → world changed → NPC remembers why. That is the cognition acceptance test, not “the model wrote a poetic greeting.”
