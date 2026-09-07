# Icarus AI — Game Design

Player-facing design for the game we want to play. Charter: [`00-VISION.md`](00-VISION.md). Architecture bundle: [`README.md`](README.md). Backlog: [`feature-list.md`](feature-list.md).

This document is the source of truth for **what the game is**. It is not an implementation plan for the current working tree. Bootstrap / Living Town graybox code may exist as a pipeline prototype; it does not override this design.

---

## Pitch

A single-player, persistent anime-fantasy RPG. You make a character in extreme depth, wake on an empty floating sanctum that becomes your home, and leave through a portal into worlds that may be random, continued, or prompted by you.

The **Sanctum** is the cozy hub. The portal is the adventure. You farm and build at home, level the Sanctum itself, collect home designs from stories, and bring people back when they trust you. Out in the worlds you take a small squad, earn 100% trust, and grow skills the way you fight.

---

## Pillars

1. **Mystical anime look** — stylized characters and spaces, deep shadows, bright lights, a world that feels otherworldly rather than naturalistic.
2. **Home you grow** — the Sanctum starts almost empty and becomes a **cozy sim** through play: farming, simple building, collectible home designs from stories, and people you earned. Not a pre-authored town.
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
| Mood | Mystical, slightly otherworldly; Sanctum warmer on stone + cooler in the dusk-void sky; worlds harsher; same lock |
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
 EMPTY SANCTUM  ◄────────────────────────────────┐
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
        └─ 100% trust → live in Sanctum + eligible for future quests
```

### Title menu

Four options only at boot:

- **New** — full character creation, then first spawn on the Sanctum.
- **Load** — existing save / character.
- **Settings** — game options, including graphics, audio, and controls (keyboard/mouse and gamepad).
- **Quit**

### New game

New always goes through **full** character customization before the Sanctum. No “skip with default hero” as the intended path (a debug skip for development is fine).

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

Technical contract (hybrid bone scale + blend shapes, record schema, apply→capsule): [`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md).

### Creator preview lighting

The atelier includes a **lighting preset** toggle so players can judge shadows and shading before Confirm:

| Preset | Intent |
| --- | --- |
| **Full** | Bright, even light — clear materials and colors |
| **Dawn** | Warm low sun, longer soft shadows |
| **Dusk** | Cool jewel dusk, deeper shadows (Sanctum-adjacent mood) |

Preview-only. Does not change Sanctum or world time. Default **Full**. Gamepad-usable.

### Demi-human features (first ship)

Demi-human cosmetics for the first shippable creator:

| Feature | Notes |
| --- | --- |
| **Ears** | Animal / fantasy ear variants |
| **Horns** | Optional horn sets (dragon demi friendly) |
| **Tails** | Includes mammal-style and **lizard / dragon** tails |

| Lock | Meaning |
| --- | --- |
| Scope | **Ears**, **horns**, and **tails** (including lizard tails) |
| Optional | On creation the player may take **any combination or none** — nothing forced |
| Dragon demi | Ears/horns/lizard-tail combos are enough to read as a dragon demi; no separate “dragon race” required |
| Race | Demi-human race may offer presets; the player can clear them. Race still does not hard-lock other cosmetics |
| Unlocked | All listed options are available from the start (no story gate) |

### Visual identity

Anime style. Combinations should include (expand during implementation, do not treat as a closed list):

- face morphs, eyes, hair, scars, markings
- demi-human **ears**, **horns**, and **tails** (including lizard tails; optional; see above)
- clothing / starting outfit as cosmetics distinct from later combat **loadout** (see Gear and appearance)

---

## Hub — the Sanctum

The **Sanctum** is the cozy home away from home: a **floating space rock** hanging in an infinite dusk-void sky, not a ground village.

### Place fantasy

| Lock | Meaning |
| --- | --- |
| Form | One small climbable stone islet / sanctum rock in the void |
| Sky | Always **dusk-void**: ethereal purples, blues, soft nebula depth, sparse stars — never daytime blue |
| Atmosphere | Floaty **embers / stardust** drift around the rock; cool violet fill from the sky, lantern gold on the stone for coziness |
| Mood | Intimate and safe underfoot; infinite and ethereal when you look out |
| Scale | Small and fully materialized. One memorable home rock, not an open-world hub |

Composition from first spawn: **spawn terrace** → sheltered **home bowl** (empty pads for later buildings) → **portal overlook** at the rim, silhouetted against the void.

### First spawn

- The Sanctum is **empty**.
- **Exception:** the **portal** is present from the start.
- No pre-placed shopkeepers, neighbors, or quest givers living there yet.

The current Living Town prototype (named NPCs already in a square) is a bootstrap experiment. The destination hub is the empty Sanctum until the player earns people.

### Portal form

v1 portal is a **freestanding arch** on the overlook. It may change later, and the player may eventually be allowed to change or decorate the portal — do not treat the arch mesh as permanent lore.

### Falling off

There is no waist-high invisible rail at the cliff. If the player walks or falls off the rock:

1. Free fall for a **few seconds** into the dusk-void.
2. Softly return / warp back onto the **center of the Sanctum** (home bowl), not a hard death.

This is a recovery beat, not a punishment run. Keep it readable and brief.

### What the Sanctum becomes

The Sanctum is not a lobby between adventures. It is a **cozy-sim home loop** that grows beside the portal loop.

As the player adventures and returns, the Sanctum enables:

- **farming** — plots, crops, materials grown at home
- **simple building** — place unlocked home designs with materials (no complex construction UI)
- **home design collectibles** — encounter architecture in stories → unlock the design → build it on the Sanctum
- **Sanctum level** — a home progression track (separate from combat path XP), fed by materials, builds, harvests, designs unlocked, and companions brought home
- residents (100% trust roster lives here)
- helpers / labor (companions can assist farming and upkeep)
- shops and services
- decorate / dwell / romance on top of the built home
- squad select at the portal (who walks out with you next)

### Dual loop

```text
SANCTUM (cozy sim)  ◄── materials, designs, people ──►  WORLDS (adventure)
   farm / build / level home                              fight / recruit / explore
   bank storage                                           bring designs + materials home
```

Neither loop is optional flavor. Adventure feeds the Sanctum; the Sanctum makes coming home matter.

### Sanctum level

**Sanctum level** is home progression. It is **not** the player’s Strength / Agility / Magic path level and not companion combat level.

| Feeds Sanctum XP (examples) | Intent |
| --- | --- |
| Materials collected / banked at home | Bring the world back |
| Crops planted and harvested | Cozy loop pays into growth |
| Home designs unlocked | Collectible discovery |
| Homes / structures placed | Building is progress |
| Companions brought to 100% and housed | People are the biggest unlock |

Sanctum level gates **capacity**, not combat power: more farm plots, more build pads, storage size, maybe rock terraces / expansions later. It does not raise attack damage.

Exact XP weights and level curve are tuning. The split (home level vs combat paths) is locked.

### Farming

- Farm plots live on the Sanctum (unlocked / expanded by Sanctum level).
- Plant → grow → harvest into **materials** (and later food / gifts if we add them).
- Growth is **real-time** (wall clock). Crops advance while you are in a world or away from the game; keep timers readable, not a spreadsheet farm MMO.
- 100% trust companions can **help** (plant, harvest, tend) once labor exists — see Companions.
- Farming is a Sanctum activity. Worlds may drop rare seeds or crop unlocks; they do not replace the home farm.

### Sanctum materials (v0)

Simplified bank for building and farm loops. Three types only for now:

| Material | Role |
| --- | --- |
| **Wood** | Framing, cabins, most early builds |
| **Metal** | Hardware, fittings, sturdier structures |
| **Fiber** | Cloth, rope, soft goods, farm-adjacent crafts |

Do not invent a fourth Sanctum material without updating this lock. World loot can still be richer; when spent on Sanctum builds it converts or maps into these three.

### Building — keep it simple

Building is **place unlocked designs**, not a freeform voxel / wall-piece editor.

| Rule | Meaning |
| --- | --- |
| Simple | Pick a design you own → spend materials → snap/place on a pad or clear site |
| No construction minigame | No stud-by-stud framing, no blueprint puzzle |
| Relocate / replace OK | Moving or swapping a placed home should stay easy |
| Pads grow with Sanctum level | Empty rock first; more build sites as home level rises |
| Parkour stays legal | Placed homes have climbable roofs / walls where it reads as architecture |
| One instance | **One active placed instance per design** for now (lean). Unlock once; place once unless you relocate/replace |

v1 decorate is optional furniture-light or none. **Structure placement first.** Deep interior decorating can layer later.

### Home designs as collectibles

Home designs are a **collection**, like gear catalogs — but for the Sanctum. Designs are **approved catalog buildings** flagged `sanctum_buildable` ([`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md)). Worlds place many catalog buildings; the player **learns** ones they encounter.

**Same mesh:** the approved catalog building mesh is what appears in the world **and** what you place on the Sanctum when it is `sanctum_buildable`. No second polish mesh required for home builds.

1. In a world, the player **encounters** a house, hall, cottage, ruin-turned-dwelling, etc. backed by a catalog id.
2. Default learn beat: **Study** — an interaction with the building that unlocks that catalog id in the Sanctum design catalog. Stories may add extra gates later; Study is the baseline.
3. Back home, if the player has the **materials** (wood / metal / fiber) and a **build site**, they can place that design (one active instance).

| Lock | Meaning |
| --- | --- |
| Designs come from play | Story encounters unlock builds. Do not dump the full approved library on New Game. |
| Empty first | New Sanctum has **no** pre-placed houses (portal only). |
| Starter design | A humble **starter camp / shelter** unlocks early (first return from a world, or first materials banked) so the cozy loop can start before rare finds. |
| Rarity | Ordinary cabins/cottages common; striking story architecture rarer / signature. |
| One instance | One active placed instance per unlocked design (lean). Relocate/replace OK. |
| Flexible defs | Building data uses a stable core + open `properties` bag so we can add fields later without a hard rewrite. |
| Shared art | World instance and Sanctum buildable share the catalog mesh. |

The freestanding portal arch is **not** a home design (unless a later cosmetic pack says otherwise).

### Content volume in worlds

Adventure spaces should feel **full of authored-looking stuff**: many generated-and-**approved** buildings, items, and props from the content catalog — not three graybox houses. Players learn about and collect what they find. See [`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md) for the generate → approve → place → collect loop.

**First pump:** a **log cabin set** (variations of cozy timber dwellings and related cabin kit pieces). **Minimum library before dense placement:** **20 approved buildings**.

### Trust gate

Bringing someone home is **not** a recruit-at-first-meeting action. See **Companions** below. Until 100% trust they can fight in the story that recruited them; they do not live in the Sanctum or join unrelated quests.

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

Worlds are places you visit. The Sanctum is where you return.

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

The player can **build storage** on the Sanctum (often as part of a placed home design or a dedicated stash structure). Unequipped finds and **materials** bank here so they are not lost when chasing a new world.

Until storage exists, the practical rule is: **worn loadout** (hands, armor, accessories) is what you keep. Materials for Sanctum building may need a minimal early stash once farming / designs land.

Player body / identity persists across all worlds. Skills persist on the character, not on a given world. **Outfit / appearance** persists separately from loadout. **Sanctum level**, farm state, placed buildings, and the home-design catalog persist on the hub save.

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

Hub architecture should still be parkour-legal (rim cliffs, stacks, the portal approach). Cozy is not an excuse for invisible walls at waist height. Falling off the Sanctum uses the soft return rule above.

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
| Roster | Every companion at **100% trust**. They live in the Sanctum. Arknights-like collection. |
| Field slots | **Two** active companions plus the player (Mass Effect-like). Chosen at the portal from the roster. Slots may be empty. |

A story can recruit someone who is not on the roster yet. They may occupy a field slot **in that world** (swap if both slots are full). They cannot be taken home or onto other quests until trust hits 100%.

Trust is a 0–100% relationship, earned in stories (and later in the hub). **100%** unlocks both:

1. Follow the player back to the Sanctum to live.
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
| [`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md) | Generate → approve → place → collect; flexible defs |
| [`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md) | Morph tech, character record, creator lighting, apply→capsule |
| [`agent-operating-loop.md`](agent-operating-loop.md) | How agents implement without breaking the loop |

**Living Town** in earlier writing maps to the **Sanctum** (hub), with two design changes: it starts empty and is populated by trusted companions, not by a pre-authored cast; and the place fantasy is a floating dusk-void rock, not a ground village.

Generative AI (prompted worlds, later NPC cognition) still must not be the authority for game state. The engine stores the Sanctum (level, farms, buildings, design catalog), the character, loadout, outfit, trust, romance, jealousy, companion affinities, and world saves.

---

## Open questions

Recorded so we do not silently invent them during implementation:

- How many “previous worlds” can be continued (one active world vs many slots).
- Unarmed / empty-hand XP.
- Dual-wield rules and two-handed weapons as a distinct slot vs two occupied hands.
- Whether combat shares the traversal stamina meter or stays animation-recovery only.
- Glider, grapple, and swim (not required for the first parkour slice).
- Broader demi-human kits beyond ears / horns / tails (wings, full scales body, etc.).
- Settings extras beyond graphics / audio / controls (accessibility, AI/provider).
- Exact Sanctum XP weights (materials vs designs vs companions vs harvests).
- Whether the freestanding portal arch stays fixed, becomes swappable cosmetics, or both.
- How prompted-world text is stored, versioned, and shown in the continue list.
- Whether a story can force a third field member or always respects the two-slot cap via swap.
- Family / kids as a cozy-sim layer on top of romance.
- Whether heal nodes are placeable by the player or only found in the world.
- Whether world loot maps 1:1 into wood/metal/fiber or uses a convert step.
