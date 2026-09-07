# Icarus AI — Game Design

Player-facing design for the game we want to play. Charter: [`00-VISION.md`](00-VISION.md). Architecture bundle: [`README.md`](README.md). Backlog: [`feature-list.md`](feature-list.md).

This document is the source of truth for **what the game is**. It is not an implementation plan for the current working tree. Bootstrap / Living Town graybox code may exist as a pipeline prototype; it does not override this design.

---

## Pitch

A single-player, persistent anime-fantasy RPG. You make a character in extreme depth, wake in an empty village that becomes your home, and leave through a portal into worlds that may be random, continued, or prompted by you.

The village is the cozy hub. The portal is the adventure. You take a small squad into stories, earn 100% trust, and bring people home as full characters with their own gear and growth. Skills grow the way you fight.

---

## Pillars

1. **Mystical anime look** — stylized characters and spaces, deep shadows, bright lights, a world that feels otherworldly rather than naturalistic.
2. **Home you grow** — the village starts almost empty and becomes a cozy sim through play, not through a pre-authored town.
3. **Worlds on your terms** — resume a world, roll a new one, or prompt the story you want.
4. **Identity is yours** — Code Vein-class character creation; race is a tag and a preset, not a lock.
5. **You are what you wield** — two hands, gear-defined combat, Fable-style use-based progression.
6. **Heavy to play, not brutal to beat** — soulslike camera and weight; difficulty is not soulslike. Controller is a first-class input from day one.
7. **Light parkour** — wall climb and wall run in the Wuthering Waves / Tears of the Kingdom / Genshin family. Exploration is fluent; fights stay committed.
8. **Squad you earn** — Mass Effect field slots, Arknights roster. Companions are full characters; they grow from level and what they actually do, not from a player-built skill tree.

---

## Art direction

Canonical lock (agents generate from this, not from memory): [`art-style.md`](art-style.md). Prompt fragments: [`art/prompt-lock.md`](art/prompt-lock.md).

| Intent | Meaning |
| --- | --- |
| Style | Wuthering Waves–class 3D anime. Inspiration only, not IP copies. |
| Lighting | Deep darks, bright lights, high contrast, volumetric depth |
| Color | Dark high-depth jewel tones (ink navy, indigo, teal, wine) plus sparse moon-white / gold / cyan lights |
| Mood | Mystical, slightly otherworldly; hub warmer, worlds harsher, same lock |
| Characters | Anime faces, material-rich bodies and clothes, full creator range including demi-humans |

UI should match this lock. Graybox and Kenney town meshes are build scaffold, not destination art.

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
 EMPTY HUB VILLAGE  ◄─────────────────────────────┐
        │                                         │
        │ enter portal                            │ return through portal
        ▼                                         │
   PORTAL: Continue | New random | Prompt         │
        │                                         │
        ▼                                         │
   SQUAD SELECT (2 slots, 100% roster)            │
        │                                         │
        ▼                                         │
   [new/prompt] WORLD COMPILER (in-game)          │
        │                                         │
        ▼                                         │
   WORLD  (recruit in story, earn trust) ─────────┘
        │
        └─ 100% trust → live in hub + eligible for future quests
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
- clothing / starting outfit as cosmetics distinct from later combat **loadout** (see Gear and appearance)

---

## Hub village

The village is the **cozy home away from home**.

### First spawn

- The village is **empty**.
- **Exception:** the **portal** is present from the start.
- No pre-placed shopkeepers, neighbors, or quest givers living there yet.

The current Living Town prototype (named NPCs already in a square) is a bootstrap experiment. The destination hub is empty until the player earns people.

### What the hub becomes

As the player adventures, **100% trust** companions can be brought home. Over time that enables:

- residents (the roster lives here)
- helpers
- shops and services
- a cozy sim layer (decorate, build, live with the people you chose, including romance)
- squad select at the portal (who walks out with you next)

### Trust gate

Bringing someone home is **not** a recruit-at-first-meeting action. See **Companions** below. Until 100% trust they can fight in the story that recruited them; they do not live in the hub or join unrelated quests.

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

**New random** and **Prompt** run the **world compiler** as an in-game sequence (watch geography, factions, NPCs, conflicts form). That screen is gameplay, not a mute load. **Continue** skips genesis and resumes persisted mutations. See [`01-GAMEPLAY-LOOP.md`](01-GAMEPLAY-LOOP.md) and [`02-WORLD-COMPILER.md`](02-WORLD-COMPILER.md).

Before stepping through, the player fills **two field companion slots** from the 100% trust roster (empty allowed). Story recruits inside a world can fill or swap a slot for that world only until they hit 100% trust.

---

## Persistence

### What always travels with the player

Whatever the player is **currently equipped with** comes with them:

- hub → world
- world → hub
- world A → (via hub) → world B, still wearing it

### What stays safe at home

The player can eventually **build storage** in the village. Unequipped finds can be parked there so they are not lost when chasing a new world.

Until storage exists, the practical rule is: **worn loadout** (hands, armor, accessories) is what you keep.

Player body / identity persists across all worlds. Skills persist on the character, not on a given world. **Outfit / appearance** persists separately from loadout.

**100% trust companions** persist on the hub roster with their own loadout, outfit, levels, and affinities. They travel through the portal when selected into a field slot. Story-only recruits stay in that world until the trust gate.

---

## Input

**Controller support ships with the first playable flow**, not as a later polish pass. Title, character creation, hub, portal menus, and combat must all be fully usable on a gamepad.

Keyboard and mouse remain supported. Neither layout is a second-class afterthought: if a screen cannot be completed with a controller, it is not done.

Default assumption: Xbox-layout gamepad (expand to other layouts as needed). Camera, movement, lock-on, parkour, **squad select**, and menus should feel native on stick + face buttons, not like a mouse UI with a cursor overlay.

---

## Movement

Traversal is **light parkour**, not a precision platformer and not “walk and jump only.” North stars: **Wuthering Waves**, **Tears of the Kingdom**, **Genshin Impact** — fluent vertical mobility, generous attach, readable stamina, almost any reasonable surface is in play.

The same kit exists in the **hub and in worlds**. Combat does not replace it. When you are fighting, attacks stay soulslike-heavy; when you are moving, you can still climb, run a wall, and mantle out. Parkour is not an i-frame cheat and not a locked-off exploration toy.

### Kit (locked)

| Move | Intent |
| --- | --- |
| Walk / run / sprint | Analog stick; sprint is a hold, not a toggle maze |
| Jump | Ground jump, jump-off wall, short directed air control |
| Mantle / vault | Low ledges and obstacles are grabbed, not stuck-on-knee |
| Wall climb | Attach to near-vertical surfaces and climb freely (TotK / Genshin) |
| Wall run | Sprint into or along a wall for a limited horizontal run (WuWa-class) |
| Ledge hang | Pause on a lip, shimmy, climb up or drop |
| Drop from climb | Let go without a dedicated “fail state” animation as the default |

### Surfaces

Default: **the world is climbable**. Marked yellow ledges only are the wrong target.

Exceptions are allowed (ice, grease, sacred / story-blocked faces, interiors we do not want cheesed). Those should read as exceptions in material or VFX, not as “you forgot to tag the mesh.”

Hub architecture should still be parkour-legal (roofs, walls, the portal approach). Cozy is not an excuse for invisible walls at waist height.

### Feel

- **Light** means: easy to attach, easy to recover, wide climbable angles, stamina that is a budget not a punishment.
- Not Mirror’s Edge timing trials. Not Mario precision jumps. Not Souls runbacks as the traversal fantasy.
- Camera stays third-person follow; it should not fight the wall. Climb and wall-run keep the character readable.
- Body size from the creator scales the capsule and anims. It does **not** gate who can parkour. A gnome and a tall demi-human both climb; they do not use different move lists.

### Traversal stamina

Sprint, climb, and wall-run share a **traversal meter** in the Genshin / TotK sense: it drains while committed to those moves, recovers on ground / idle, and failing it means a slide/drop, not death.

Keep it generous. Combat stamina (if we add a Souls-style attack meter later) should not become a second HUD bar without a decision — prefer one body, one meter. Until that decision, traversal meter is locked; combat commitment can stay in animation recovery.

### Explicitly later / not locked

Do not invent these as required for the first movement slice:

- Glider / hover
- Grapple / hookshot
- Swim / dive
- Shield-surf, flight mounts, character-unique traversal ults

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

Traversal stays the light-parkour kit above even in combat spaces. The camera and controller language never swap. What changes in a fight is attack commitment, not the sudden loss of climb.

### Downed and heal nodes

Going down in a fight is **not** the end of that person. Player and companions enter a downed state and can be **healed back up** (ally heal, item, or a world node).

Worlds contain **heal nodes** — crystalline shards in the world, in the spirit of Arknights originium shards. Standing in range ticks health and can raise the downed. They are field infrastructure, not a Souls bonfire that resets the map.

If the **whole party** is down with no node in range, that is a wipe: retreat to the last used heal node or the world entrance. Worn loadout is kept. Fair difficulty; no “lose your save.”

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

## Gear and appearance

Two layers. Do not collapse them.

| Layer | What it does |
| --- | --- |
| **Loadout** | Gameplay. Hands, armor, accessories. Stats, defense, weapon XP paths. |
| **Outfit** | Looks. Full cosmetic control for the player **and** every companion. Does not change playstyle. |

**Armor is not character appearance.** Plate can live under a dress. A healer can look like a street kid. Dressing someone must not rewrite their affinities, weapon paths, or AI role.

The player may fully outfit companions the same way they outfit themselves (loadout + outfit). Changing a companion’s **weapons** still changes how they fight and grow (that is the Fable rule). Changing their **outfit** must not.

### Loadout slots

Everyone (player and companions) has the same slots.

**Hands**

- Main / off (two hands). Weapons and shield as already specified.

**Armor**

| Slot | Notes |
| --- | --- |
| Helmet | |
| Torso | |
| Gloves | |
| Cape | Cloth physics. Required, not optional polish. |
| Legs | |
| Boots | |

**Accessories** (gear, not flavor, not deferred)

| Slot | Count |
| --- | --- |
| Necklace | 1 |
| Rings | 2 |
| Earrings | 2 |

Cape physics and existing muscle–fat jiggle are both appearance-time motion. Outfit capes still simulate; a transmog that hides the cape hides the sim.

---

## Companions

North stars: **Mass Effect** (two people in the field, you pick them) and **Arknights** (a roster of full operators you earned, each with their own kit). They are not pets, not summonable stats, and not characters the player specs by menu.

### Roster and field slots

| Layer | What it is |
| --- | --- |
| Roster | Every companion at **100% trust**. They live in the hub. Arknights-like collection. |
| Field slots | **Two** active companions plus the player (Mass Effect-like). Chosen at the portal from the roster. Slots may be empty. |

A story can recruit someone who is not on the roster yet. They may occupy a field slot **in that world** (swap if both slots are full). They cannot be taken home or onto other quests until trust hits 100%.

Trust is a 0–100% relationship, earned in stories (and later in the hub). **100%** unlocks both:

1. Follow the player back to the hub to live.
2. Join the roster for further quests (portal squad select).

### Full characters

Companions use the same combat and equipment rules as the player:

- two hands, **full armor, full accessories**
- outfit layer independent of loadout
- Strength / Agility / Magic paths
- Fable-style XP from what they actually fight with

They keep their own loadout, outfit, and progression. The player may **dress and kit** them. The player does **not** open a talent screen and build them.

### Growth: level and actions, not a player spec

How locked their identity is depends on **where they already are** when you recruit them.

- **High-level recruit** (e.g. a level 20 adventurer): their path, affinities, and habits are mostly baked. Further XP still lands, but you are not turning a veteran healer into a dual-dagger assassin by standing near them.
- **Low-level recruit** (e.g. level 1 with a wand and a book): plastic. What they become is written by **what they do while aiding you**.

Action-driven affinities (engine-owned weights, not LLM prose):

- The game records how they spent fights: healed allies, cast offensive magic, blocked, scored melee hits, and so on.
- Those actions bias future AI choices and where new path XP / skill emphasis goes.
- Example: wand + book. If you keep your health up and they rarely need to heal, offensive spell actions dominate → they grow as a **mage**. If you are constantly in the red, heal actions dominate → they grow as a **healer**. Same weapons, different person, because of how the party actually played.

They still only grow along paths their **gear and actions** support. A wand-user does not secretly become a greatsword specialist without ever holding one.

### Combat AI

The engine owns what they do in a fight. Party state (your HP, their HP, enemy pressure) plus affinities pick the action. Generative AI may color dialogue and personality; it does not spend their skill points or author their save.

The player is not a tactical pause-and-order RTS commander by default. Companions act. (A later ping / focus-target is allowed; a full player-driven skill bar for each companion is not the target.)

### Romance, polyamory, jealousy

Romance is in the game. **Polyamory is supported** — multiple concurrent relationships are allowed. This is not a one-partner lock.

Some companions can be **jealous**. That is a character trait, not a global “the whole roster knows.”

Jealousy and related beats **only fire if the NPCs meet** — same scene, same hub space, same field party, a conversation they are both in. No omniscient off-screen jealousy, no letters from another world about a romance they never witnessed. If they have not met, it does not proc.

Trust, romance, and jealousy are engine-owned flags and scores. LLM may color the line they say; it does not invent a breakup the state does not support.

---

## Relationship to existing docs

| Doc | Owns |
| --- | --- |
| [`README.md`](README.md) | Bundle index and priority order |
| [`00-VISION.md`](00-VISION.md) | Why we build; inhabit a world that continues |
| This file | What the player experiences |
| [`art-style.md`](art-style.md) | How it looks; generator lock |
| [`feature-list.md`](feature-list.md) | What to build, in order |
| [`agent-operating-loop.md`](agent-operating-loop.md) | How agents implement without breaking the loop |

**Living Town** in earlier writing maps to the **hub village**, with one design change: it starts empty and is populated by trusted companions, not by a pre-authored cast.

Generative AI (prompted worlds, later NPC cognition) still must not be the authority for game state. The engine stores the village, the character, loadout, outfit, trust, romance, jealousy, companion affinities, and world saves.

---

## Open questions

Recorded so we do not silently invent them during implementation:

- How many “previous worlds” can be continued (one active world vs many slots).
- Unarmed / empty-hand XP.
- Dual-wield rules and two-handed weapons as a distinct slot vs two occupied hands.
- Whether combat shares the traversal stamina meter or stays animation-recovery only.
- Glider, grapple, and swim (not required for the first parkour slice).
- What “demi-human” covers in the first shippable creator (ears/tails only vs broader kitsune/horned/etc.).
- Settings extras beyond graphics / audio / controls (accessibility, AI/provider).
- Whether hub time advances while the player is in a world.
- How prompted-world text is stored, versioned, and shown in the continue list.
- Whether a story can force a third field member or always respects the two-slot cap via swap.
- Family / kids as a cozy-sim layer on top of romance.
- Whether heal nodes are placeable by the player or only found in the world.
