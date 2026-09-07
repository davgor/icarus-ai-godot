# 06 — Agent architecture

Hierarchical agents. Each gets the **smallest context** that can justify its decision. None get unrestricted authority. Each operates against a **contract inherited from its parent** (constitution, seed, already-committed state).

| Agent | Knows |
| --- | --- |
| **World Director** | Constitution, major history, civilizations, global rules, major conflicts |
| **Regional Director** | Region, local geography, settlements, regional factions/economy/conflicts |
| **Settlement Director** | Settlement, population, businesses, local factions, important NPCs, local history |
| **NPC Agent** | That NPC’s memories, beliefs, relationships, goals, knowledge, personality |

Outputs are structured proposals. [`04-SIMULATION.md`](04-SIMULATION.md) validates and applies.

---

## Coding agents vs world agents

This hierarchy is **in-game / compile-time cognition**. Cursor and Summer are **development** agents ([`10-AI-DEVELOPMENT-WORKFLOW.md`](10-AI-DEVELOPMENT-WORKFLOW.md)). Do not call Summer SDK from shipped game code. Do not let a World Director edit `player.gd`.

During the compiler screen, directors may run so the player can watch construction. During play, prefer relevance-filtered NPC updates, not a full world-director tick every frame.

---

## Contracts (minimum)

- Cannot contradict committed engine state.
- Cannot grant hub residence or field-slot eligibility without 100% trust.
- Cannot spend companion XP or rewrite outfit into loadout.
- Cannot invent character appearance outside the **creator catalog** ([`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md)); propose schema fields + catalog ids only.
- Cannot omit validation.
