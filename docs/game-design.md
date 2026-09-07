# Icarus AI — Game Design

Player-facing design for the game we want to play. Development philosophy and tooling stay in [`vision.md`](vision.md). The ordered backlog is [`feature-list.md`](feature-list.md).

This document is the source of truth for **what the game is**. It is not an implementation plan for the current working tree. Bootstrap / Living Town graybox code may exist as a pipeline prototype; it does not override this design.

---

## Pitch

A single-player, persistent anime-fantasy RPG. You make a character in extreme depth, wake in an empty village that becomes your home, and leave through a portal into worlds that may be random, continued, or prompted by you.

The village is the cozy hub. The portal is the adventure. Companions you earn trust with can be brought home to live, work, and open shops. Gear you wear travels with you. Skills grow the way you fight.

---

## Pillars

1. **Mystical anime look** — stylized characters and spaces, deep shadows, bright lights, a world that feels otherworldly rather than naturalistic.
2. **Home you grow** — the village starts almost empty and becomes a cozy sim through play, not through a pre-authored town.
3. **Worlds on your terms** — resume a world, roll a new one, or prompt the story you want.
4. **Identity is yours** — Code Vein-class character creation; race is a tag and a preset, not a lock.
5. **You are what you wield** — two hands, gear-defined combat, Fable-style use-based progression.
6. **Heavy to play, not brutal to beat** — soulslike camera and weight; difficulty is not soulslike. Controller is a first-class input from day one.

---

## Art direction

| Intent | Meaning |
| --- | --- |
| Style | Anime / stylized, not realistic |
| Lighting | Deep darks, bright lights, high contrast |
| Mood | Mystical, slightly otherworldly, cozy in the hub and dangerous beyond the portal |
| Characters | Full anime-body range, including demi-human features |

UI should match: readable, atmospheric, not generic sci-fi graybox as the destination look (graybox is only a build scaffold).

---

## Session flow

```text
BOOT / LOADING SCREEN
        │
        ▼
   TITLE MENU
   ├─ New
   ├─ Load
   ├─ Settings
   └─ Quit
        │ New
        ▼
 CHARACTER CREATION
        │
        ▼
 EMPTY HUB VILLAGE  ◄──────────────┐
        │                          │
        │ enter portal             │ return through portal
        ▼                          │
   PORTAL CHOICE                   │
   ├─ Continue previous world ─────┤
   ├─ New randomized world ────────┤
   └─ Prompt a world ──────────────┘
```

### Title menu

Four options only at boot:

- **New** — full character creation, then first spawn in the hub.
- **Load** — existing save / character.
- **Settings** — game options, including graphics, audio, and controls (keyboard/mouse and gamepad).
- **Quit**

### New game

New always goes through **full** character customization before the village. No “skip with default hero” as the intended path (a debug skip for development is fine).

---

## Character creation

Target depth: **Code Vein-class**. Every slider, morph, and combination we can reasonably support. All cosmetic options are unlocked from the start.

### Races

Playable races:

- Human
- Elf
- Dwarf
- Gnome
- Halfling
- Demi-human

Race does **not** lock customization. Race does:

- apply a **preset** (starting proportions, typical features)
- act as a **story tag** (dialogue, world reactions, prompted-story hooks)

The player can then override the preset freely.

### Body

The player has full control of:

- proportions (head, torso, limbs, etc.)
- height
- weight
- a **muscle ↔ fat** bar

**Soft-body / jiggle** is driven by that muscle–fat bar: higher fat increases motion, higher muscle reduces it. This is a customization/readability system, not a separate toggle maze.

### Visual identity

Anime style. Combinations should include (expand during implementation, do not treat as a closed list):

- face morphs, eyes, hair, scars, markings
- ears, horns, tails, and other demi-human features
- clothing / starting outfit as cosmetics distinct from later combat gear

---

## Hub village

The village is the **cozy home away from home**.

### First spawn

- The village is **empty**.
- **Exception:** the **portal** is present from the start.
- No pre-placed shopkeepers, neighbors, or quest givers living there yet.

The current Living Town prototype (named NPCs already in a square) is a bootstrap experiment. The destination hub is empty until the player earns people.

### What the hub becomes

As the player adventures, they can bring people back to live in the village. Over time that enables:

- residents
- helpers
- shops and services
- a cozy sim layer (decorate, build, live with the people you chose)

### Trust gate

Bringing someone home is **not** a recruit-at-first-meeting action.

A character must become a **highly trusted companion** before they can be invited to the village. Trust is earned in the worlds (and later in the hub through ongoing relationship). Until then they belong to their world, not to home.

---

## Portal and worlds

The portal is the only way into adventure spaces. On use, the player chooses one of three modes:

### 1. Continue previous world

Resume a world they already started. Pick up where they left off: location, story state, NPCs, and that world’s inventory/progress as designed for persistence.

### 2. New randomized world

Generate a fresh world from a seed. No player prompt required.

### 3. Prompt the world

The player writes (or pastes) the story they want to experience. That text:

- influences the **seed**
- drives **agentic story development** (beats, factions, characters, tone)

The engine still owns authoritative state. The prompt is untrusted input that shapes generation; it does not rewrite the save by prose alone.

Worlds are places you visit. The hub is where you return.

---

## Persistence

### What always travels with the player

Whatever the player is **currently equipped with** comes with them:

- hub → world
- world → hub
- world A → (via hub) → world B, still wearing it

### What stays safe at home

The player can eventually **build storage** in the village. Unequipped finds can be parked there so they are not lost when chasing a new world.

Until storage exists, the practical rule is: **worn gear is the persistent loadout**.

Player body / identity persists across all worlds. Skills persist on the character, not on a given world.

---

## Input

**Controller support ships with the first playable flow**, not as a later polish pass. Title, character creation, hub, portal menus, and combat must all be fully usable on a gamepad.

Keyboard and mouse remain supported. Neither layout is a second-class afterthought: if a screen cannot be completed with a controller, it is not done.

Default assumption: Xbox-layout gamepad (expand to other layouts as needed). Camera, movement, lock-on, and menus should feel native on stick + face buttons, not like a mouse UI with a cursor overlay.

---

## Combat and progression

Combat is **gear-centered**. The character has **two hands**. What is equipped in those hands decides both how you fight and which skill path gains XP.

### Feel and camera

Combat and camera should read **soulslike**:

- third-person, over-the-shoulder / follow cam
- lock-on
- committed, **heavy** attacks (startup, recovery, stamina-like commitment)
- spacing, rolls / avoidance, and reading the opponent matter

Difficulty should **not** be soulslike. Encounters can feel weighty without being a punishment gauntlet: generous reads, fair telegraphs, recoverable mistakes, no “git gud or stop playing” tuning. The toy is Souls. The difficulty curve is not.

Hub traversal can stay lighter than combat (walk, look, interact) but still uses the same camera and controller language so the game never swaps control schemes.

### Paths (Fable-style)

Three paths:

| Path | Grows when you… |
| --- | --- |
| Strength | Fight with strength-tagged gear |
| Agility | Fight with agility-tagged gear |
| Magic | Fight with magic-tagged gear |

The more you use a path, the more XP that path gets. No abstract “pick a class, then ignore it.” Play style is class.

### Weapon tags

| Gear | Path |
| --- | --- |
| Bow | Agility |
| Wand | Magic |
| Dagger | Agility |
| Sword / Axe / Mace | Strength |
| Shield | Strength |

### Two-hand splits

Each hand contributes its tag. If both hands are used, XP is split by the equipped pair.

Example:

- **Wand + Shield** → Magic 50% / Strength 50%

Same idea for other pairs (dagger + dagger = full agility, sword + shield = full strength, wand + wand if dual-wield is allowed = full magic, and so on). Two-handing a single two-handed weapon (if added later) should assign 100% to that weapon’s path.

Empty hands and unarmed are not specified yet; see open questions.

---

## Relationship to existing docs

| Doc | Owns |
| --- | --- |
| [`vision.md`](vision.md) | Why we build, tech, AI-vs-engine rules |
| This file | What the player experiences |
| [`feature-list.md`](feature-list.md) | What to build, in order |
| [`agent-operating-loop.md`](agent-operating-loop.md) | How agents implement without breaking the loop |

**Living Town** in earlier writing maps to the **hub village**, with one design change: it starts empty and is populated by trusted companions, not by a pre-authored cast.

Generative AI (prompted worlds, later NPC cognition) still must not be the authority for game state. The engine stores the village, the character, gear, trust, and world saves.

---

## Open questions

Recorded so we do not silently invent them during implementation:

- How many “previous worlds” can be continued (one active world vs many slots).
- Death, durability, and what happens to worn gear on failure.
- Unarmed / empty-hand XP.
- Dual-wield rules and two-handed weapons as a distinct slot vs two occupied hands.
- Stamina (or equivalent) as a combat resource vs simpler recovery.
- What “demi-human” covers in the first shippable creator (ears/tails only vs broader kitsune/horned/etc.).
- Settings extras beyond graphics / audio / controls (accessibility, AI/provider).
- Whether hub time advances while the player is in a world.
- Romance / family as a cozy-sim layer, or companions-only.
- How prompted-world text is stored, versioned, and shown in the continue list.
