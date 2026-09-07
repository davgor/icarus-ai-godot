# 01 — Gameplay loop

Canonical player-facing detail: [`game-design.md`](game-design.md). This note is the loop and the compiler-as-gameplay beat.

---

## Session

```text
BOOT / LOADING
        │
        ▼
   TITLE  (New / Load / Settings / Quit)
        │ New
        ▼
 CHARACTER CREATION
        │
        ▼
 HUB VILLAGE  ◄──────────────────────────────┐
        │                                    │
        │ portal                             │ return
        ▼                                    │
 PORTAL: Continue | New random | Prompt      │
        │                                    │
        ▼                                    │
 SQUAD SELECT (2 slots, 100% roster)         │
        │                                    │
        ▼                                    │
 [if new/prompt] WORLD COMPILER (in-game)    │
        │                                    │
        ▼                                    │
 ENTER WORLD → explore / interact / change ──┘
        │
        └─ persist; 100% trust → hub roster
```

**Continue** resumes materialized state. It does not re-run the compiler as a new genesis.

**New random** and **Prompt** go through the compiler. Prompted text is untrusted input that becomes a constitution and a seed ([`02-WORLD-COMPILER.md`](02-WORLD-COMPILER.md)).

---

## The compiler screen is gameplay

Not a spinner. The player watches the world come into being:

- geography
- kingdoms / factions
- major NPCs
- conflicts
- settlements
- local regions materializing

Agent activity is visible as **explanation of construction**, not as chat replacing the game. Then: **Enter world**.

---

## Inside a world

Play is a normal third-person action-RPG: parkour, soulslike-weight combat (fair difficulty), gear, companions. See `game-design.md`. Actions mutate simulation state. Leaving writes persistence ([`08-PERSISTENCE.md`](08-PERSISTENCE.md)). Returning must be able to show consequences.

---

## First playable (already locked)

Do not skip this for a compiler demo:

Title → thin creator → empty hub + portal → climb / wall-run → one world in and out still wearing a test loadout. Controller from boot. [`feature-list.md`](feature-list.md).

---

## World Compiler v0.1 (after the hub exists)

**Input (example):** a peaceful fantasy kingdom secretly controlled by vampires, dangerous northern frontier, powerful mage guild.

**Output (order of magnitude, not a quota to hit in code tomorrow):**

- 1 kingdom, ~3 regions, ~5 settlements
- 3–5 major factions, ~20 important NPCs
- historical events, active conflicts
- basic geography, economy, world map

Show progress (`WORLD SEED CREATED` → geography → civilizations → factions → settlements → NPCs → relationships). Then enter. Third-person character, walk into the first settlement, talk to generated NPCs.

Lazy: do not fully generate distant villagers before the player can walk ([`07-LAZY-GENERATION.md`](07-LAZY-GENERATION.md)).

---

## Holy shit test (world nucleus)

Not “can the AI write a cool NPC.” This:

1. Generate / compile a world.
2. Meet an NPC.
3. Do something unexpected.
4. Leave.
5. Come back later.
6. Something has changed because of what you did.
7. The NPC remembers why.

If that works, the nucleus exists. Combat polish, art, huge maps, and hundreds of NPCs are expansion.
