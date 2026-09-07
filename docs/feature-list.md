# Icarus AI — Feature list

Ordered backlog for the player-facing design in [`game-design.md`](game-design.md). Work top-down unless a later item is needed as a dependency.

Do not treat this as “implement everything in one branch.” Each slice should stay playable. Bootstrap / graybox work already in the tree is a pipeline, not a substitute for these features.

Status key: **Now** = next when we start this design. **Next** = after the previous slice is playable. **Later** = needs earlier systems. **Open** = blocked on a design question.

---

## 0. Already true (do not rebuild)

- Edit → test → build → play loop
- Headless tests via `.\scripts\test.ps1`
- Main scene at `res://game/main.tscn`
- Engine owns state; LLM is untrusted input

---

## 1. Boot and title — Now

The game must open as a game, not as a graybox drop-in.

| ID | Feature | Notes |
| --- | --- | --- |
| 1.1 | Loading screen | Standard boot splash / load, then title |
| 1.2 | Title menu | **New**, **Load**, **Settings**, **Quit** only |
| 1.3 | Quit | Leaves the game |
| 1.4 | Settings shell | Audio, graphics, and **controls** placeholders so the fourth button is real |
| 1.5 | Load shell | Empty state (“no saves”) until persistence exists |
| 1.6 | New → creator | New never skips customization in the real flow |
| 1.7 | Controller from boot | Title, settings, load, and quit are fully usable on a gamepad. Not a mouse-cursor overlay. |

**Input rule:** every slice after this one is incomplete until it works on a controller. Keyboard/mouse stays supported in parallel.

---

## 2. Character creation — Now / Next

Code Vein-class depth. Ship a vertical slice first, then deepen morphs.

| ID | Feature | Notes |
| --- | --- | --- |
| 2.1 | Creator screen | Dedicated flow after New, before hub spawn |
| 2.2 | Race select | Human, elf, dwarf, gnome, halfling, demi-human |
| 2.3 | Race as preset | Selecting a race applies defaults; player can override everything |
| 2.4 | Race as tag | Stored on the character for later story / world reactions |
| 2.5 | Height and weight | First-class sliders |
| 2.6 | Proportions | Body region morphs; expand over time |
| 2.7 | Muscle ↔ fat bar | Drives silhouette and jiggle |
| 2.8 | Jiggle / soft-body | Driven by the muscle–fat bar, not a pile of unrelated toggles |
| 2.9 | Face / hair / eyes | Anime kit; grow the catalog |
| 2.10 | Demi-human features | Ears, tails, horns, etc.; all unlocked |
| 2.11 | Starting cosmetics | Outfit distinct from later combat gear |
| 2.12 | Confirm → spawn | Writes the character, then loads the empty hub |
| 2.13 | Creator on controller | Sliders, race, camera orbit, and confirm without a mouse |

All cosmetics stay unlocked. Do not gate creator parts behind play.

---

## 3. Hub village — Next

Cozy home. Empty except the portal.

| ID | Feature | Notes |
| --- | --- | --- |
| 3.1 | Hub scene | Village space with a mystical anime read (can start gray, must not stay gray) |
| 3.2 | Empty-on-new | No residents, shops, or pre-authored neighbors on a new save |
| 3.3 | Portal present | The one exception; interactable |
| 3.4 | Player spawn | After creator, stand in the hub, not in a dungeon |
| 3.5 | Return point | Leaving a world always comes back here |
| 3.6 | Cozy-sim foundation | Place to stand, look, and later place buildings / storage (hooks only at first) |
| 3.7 | Hub on controller | Walk, look, interact with the portal without a mouse |

The existing Living Town sim with a pre-seeded cast is **not** this hub. Replace or isolate it when this slice starts; do not grow the prototype town as if it were home.

---

## 4. Portal modes — Next

Three choices when the player uses the portal.

| ID | Feature | Notes |
| --- | --- | --- |
| 4.1 | Portal UI | Continue / New random / Prompt |
| 4.2 | New randomized world | Seeded world, enter, play, return |
| 4.3 | Continue previous world | Resume last (or selected) world state |
| 4.4 | Prompted world | Player supplies story text → influences seed + story direction |
| 4.5 | World save | Engine-owned world state, distinct from hub state |
| 4.6 | Prompt storage | Remember the prompt with that world for Continue |

Prompted worlds still obey: AI suggests, engine commits.

---

## 5. Loadout persistence — Next

Worn gear is the character’s through-line.

| ID | Feature | Notes |
| --- | --- | --- |
| 5.1 | Two-hand equipment | Left / right (or main / off) slots |
| 5.2 | Equip in hub and worlds | Same character, same worn items |
| 5.3 | Travel rule | Current equipment always comes through the portal both ways |
| 5.4 | Character save | Body, race tag, skills, worn gear survive quit / relaunch |
| 5.5 | Village storage | **Later** — buildable stash so finds can stay home unequipped |

Until 5.5, worn = what you keep.

---

## 6. Combat and Fable XP — Later

Gear decides both moves and growth. Feel is soulslike; tuning is not.

| ID | Feature | Notes |
| --- | --- | --- |
| 6.1 | Strength / Agility / Magic | Three paths on the character |
| 6.2 | Use-based XP | Hitting / fighting with a path’s gear grants that path XP |
| 6.3 | Weapon tags | Bow, dagger → agility; wand → magic; sword / axe / mace / shield → strength |
| 6.4 | Split XP | Two different tags (e.g. wand + shield) → 50% / 50% |
| 6.5 | Same-tag pair | Both hands same path → 100% that path |
| 6.6 | Combat loop | Playable fights in a world, not a stats sheet only |
| 6.7 | Third-person camera | Follow / over-the-shoulder, combat and hub share the language |
| 6.8 | Lock-on | Target lock from the controller stick / shoulder pattern |
| 6.9 | Heavy commitment | Startup, recovery, readable swings — weight, not floaty hack-and-slash |
| 6.10 | Fair difficulty | Telegraphs and recovery room; not Souls-grade punishment |
| 6.11 | Gamepad combat | Attack, evade, lock, items, and two-hand swaps on a controller from the first fight |

Unarmed, two-handed weapons, stamina-as-resource, and death rules wait on open questions in the design doc.

---

## 7. Companions and a living hub — Later

The village fills because you chose people, not because the map shipped inhabited.

| ID | Feature | Notes |
| --- | --- | --- |
| 7.1 | Companion identity | Named characters in worlds |
| 7.2 | Trust | High-trust gate before invite |
| 7.3 | Invite home | Only after the gate; they appear in the hub |
| 7.4 | Residents | Live in the village, presence when you return |
| 7.5 | Help / labor | They can assist (scope TBD once trust exists) |
| 7.6 | Shops | Trusted companions can open services in the hub |
| 7.7 | Cozy sim loop | Decorate, build, dwell — layered on after people can arrive |

Do not pre-place shop NPCs “for now” in the destination hub. Temporary debug spawns are fine if they cannot be invited without trust.

---

## 8. Worlds and story — Later

Deepen what happens beyond the portal.

| ID | Feature | Notes |
| --- | --- | --- |
| 8.1 | Random world content | Places, encounters, loot that make 4.2 worth repeating |
| 8.2 | Agentic story | Prompt + play feed structured story development |
| 8.3 | Race tags in story | Worlds and NPCs can react to the stored race tag |
| 8.4 | Continue fidelity | A previous world is recognizably the same place you left |
| 8.5 | Multi-world | If we allow more than one continued world, a picker (open question) |

---

## Suggested first playable slice

Smallest thing that feels like *this* game rather than a walker:

1. Loading screen → title (New / Load / Settings / Quit), **on a controller**
2. New → race + a few body sliders → confirm, **on a controller**
3. Empty village with a portal, same camera language
4. Portal → one graybox “random world” → return still wearing a test item

Character morph depth, Fable combat, companions, and prompted story come after that loop is real. The first fight, when it lands, should already feel heavy and lock-on-based — not a placeholder twin-stick.

---

## Explicitly not this list

- Summer / Cursor / MCP features (tooling, not the game)
- Replacing the test/build/play scripts
- Making the LLM own village or inventory state
