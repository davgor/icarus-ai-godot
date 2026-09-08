# Icarus AI — Feature list

Ordered backlog for the player-facing design in [`game-design.md`](game-design.md). Work top-down unless a later item is needed as a dependency.

Do not treat this as “implement everything in one branch.” Each slice should stay playable. Bootstrap / graybox work already in the tree is a pipeline, not a substitute for these features.

All generated and imported visuals follow [`art-style.md`](art-style.md) and [`art/prompt-lock.md`](art/prompt-lock.md). Image `style` is `"anime"`. Architecture bundle: [`README.md`](README.md). Player-facing locks in [`game-design.md`](game-design.md) beat outside notes.

Status key: **Now** = next when we start this design. **Next** = after the previous slice is playable. **Later** = needs earlier systems. **Open** = blocked on a design question.

---

## 0. Already true (do not rebuild)

- Edit → test → build → play loop
- Headless tests via `.\scripts\test.ps1`
- Main scene at `res://game/main.tscn`
- Engine owns state; LLM is untrusted input

---

## 1. Boot and title — Now

Epics: [`epics/01-opening-screen.md`](epics/01-opening-screen.md) (OS-1…OS-6). Index: [`epics/README.md`](epics/README.md).

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

Epics: [`epics/02-character-creation.md`](epics/02-character-creation.md) (CC-1…CC-10, **Playable** vertical slice). Destination: [`epics/07-character-creator-complete.md`](epics/07-character-creator-complete.md) (CX-1…CX-10). Index: [`epics/README.md`](epics/README.md). Summer-first: scene build, generate/import, play, diagnostics.

Code Vein-class depth is the **target**. Pack 02 is the slice (New → customize → confirm). Pack 07 is the assembler + catalog + morph depth.

| ID | Feature | Notes |
| --- | --- | --- |
| 2.1 | Creator screen | Dedicated flow after New, before hub spawn |
| 2.2 | Race select | Human, elf, dwarf, gnome, halfling, demi-human |
| 2.19 | Male / female body | First-class Male and Female base kits; morphs and outfits apply to both; not a lock |
| 2.3 | Race as preset | Selecting a race applies defaults; player can override everything |
| 2.4 | Race as tag | Stored on the character for later story / world reactions |
| 2.5 | Height and weight | Height = tall/short; **weight = frame mass** (not fatness) |
| 2.6 | Proportions | Slice: head/torso/arms/legs. Destination: 14 named regions (2.23) |
| 2.7 | Muscle ↔ fat bar | **Composition** + jiggle driver; not overall size |
| 2.8 | Jiggle / soft-body | Driven by the muscle–fat bar only |
| 2.9 | Face / hair / eyes | Named starter morphs + anime kit; destination volume in 2.24–2.26 |
| 2.10 | Demi-human features | **Ears**, **horns**, **tails** (incl. lizard/dragon); **optional**; **in vertical slice** |
| 2.11 | Starting cosmetics | Outfit distinct from later combat gear |
| 2.12 | Confirm → spawn | Writes the character, then loads the empty hub |
| 2.13 | Creator on controller | Sliders, race, camera, lighting, reset/random, confirm without a mouse |
| 2.14 | Preview lighting | **Full / Dawn / Dusk** (preview-only) |
| 2.15 | Skin color | First-class; ≥6 swatches in slice; undertone in 2.15 destination (CX-6) |
| 2.16 | Scars / markings | Thin starter (≥1 each + none); decal layers in 2.27 |
| 2.17 | Reset / randomize | Reset all/category; randomize all/category (crude OK) |
| 2.18 | Appearance authority | Every in-game character is creator-legal; tooling can load any valid record into the creator |

### Later — creator complete (pack 07)

Do not skip the Sanctum to only polish this. May run in parallel after pack 02 is Playable. Contract: [`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md) destination engine.

| ID | Feature | Notes |
| --- | --- | --- |
| 2.20 | Appearance assembler | Staged apply: bones → morphs → slots/occlusion → materials → decals. Hot vs cold |
| 2.21 | Appearance catalog as data | Approved rows under `content/catalog/appearance/`; generators sample ids only |
| 2.22 | Schema v2 + migration | Semantic record; v1 loads; no raw bone/morph save blob |
| 2.23 | Body region complete | 14 named proportions; group sliders optional; bust is not a jiggle toggle |
| 2.24 | Face morph complete | Fine named keys (brows through human ears) + ≥3 face shape ids |
| 2.25 | Makeup | Eyeshadow, liner, lipstick, blush; unlocked; none-able |
| 2.26 | Hair highlight + heterochromia | Optional; hair ≥12, eyes ≥8 |
| 2.27 | Decal compositor | Scars / markings / tattoos as layers + region + coarse UV; pad-usable |
| 2.28 | Demi catalog complete | Volume ears/horns/tails; conflict/occlusion data; wings/scales stay deferred |
| 2.29 | Outfit occlusion + pieces | Fit to morphs; hide body under clothes; colors; still not loadout |
| 2.30 | Framing, pose, compare, undo | Atelier studio; pad-first |
| 2.31 | Creator draft save | Explicit draft; does not overwrite a confirmed character |
| 2.32 | Generator sampling + apply performance | Legal v2 only; hot sliders stay interactive with the grown catalog |

All cosmetics stay unlocked. Do not gate creator parts behind play. Morph tech + character record: [`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md). Explicitly not: unique NPC faces the player cannot rebuild in the creator; a C# engine-agnostic DTO as the save; a third `genderPreset` body kit.

---

## 3. Hub — Sanctum — Next

Cozy floating home rock in a dusk-void sky. Empty except the portal.

| ID | Feature | Notes |
| --- | --- | --- |
| 3.1 | Sanctum scene | Floating space rock + ethereal purple/blue dusk-void skybox; mystical anime read (can start gray, must not stay gray) |
| 3.2 | Empty-on-new | No residents, shops, or pre-authored neighbors on a new save |
| 3.3 | Portal present | Freestanding arch on the overlook; interactable. Form may change later / become player-swappable |
| 3.4 | Player spawn | After creator, stand on the Sanctum, not in a dungeon |
| 3.5 | Return point | Leaving a world always comes back here |
| 3.6 | Cozy-sim foundation | Home bowl pads + farm plot hooks for later building / farming (hooks only in first Sanctum slice) |
| 3.7 | Hub on controller | Walk, look, interact with the portal without a mouse |
| 3.8 | Parkour-legal hub | Rim cliffs, stacks, and the portal approach are climbable; no waist-high invisible walls |
| 3.9 | Dusk-void + stardust | Always dusk-void sky; floaty embers / stardust around the rock |
| 3.10 | Soft fall return | Fall off → free fall a few seconds → return to Sanctum center |

The existing Living Town sim with a pre-seeded cast is **not** this hub. Replace or isolate it when this slice starts; do not grow the prototype town as if it were home.

---

## Movement and parkour — Next

Ships with the hub, required in every world. North stars: Wuthering Waves, Tears of the Kingdom, Genshin. Light, not a precision platformer. Same kit on controller and KBM.

| ID | Feature | Notes |
| --- | --- | --- |
| MV.1 | Walk / run / sprint | Analog; sprint is a hold |
| MV.2 | Jump | Ground, off-wall, short air control |
| MV.3 | Mantle / vault | Low ledges do not eat the character |
| MV.4 | Wall climb | Attach and climb near-vertical faces; world-default climbable |
| MV.5 | Wall run | Limited horizontal run along walls (WuWa-class) |
| MV.6 | Ledge hang | Shimmy, climb up, or drop |
| MV.7 | Traversal meter | Shared drain for sprint / climb / wall-run; generous; slide/drop on empty, not death |
| MV.8 | Gamepad parkour | Jump, sprint, attach, drop fully on a controller |
| MV.9 | Camera on walls | Follow cam stays readable during climb and wall-run |

Body size scales capsule and anims. It does not unlock a different move list.

Not in this slice: glider, grapple, swim.

---

## 4. Portal modes — Next

Three choices when the player uses the portal.

| ID | Feature | Notes |
| --- | --- | --- |
| 4.1 | Portal UI | Continue / New random / Prompt |
| 4.2 | New randomized world | Seeded world, enter, play, return |
| 4.3 | Continue previous world | Resume last (or selected) world state |
| 4.4 | Prompted world | Player supplies story text → constitution + seed + compiler screen |
| 4.5 | World save | Engine-owned world state, distinct from hub state |
| 4.6 | Prompt storage | Remember the prompt with that world for Continue |
| 4.7 | Parkour-legal worlds | Generated / authored spaces default to climbable; traversal kit works the moment you step through |
| 4.8 | Squad select | Two field slots from the 100% trust roster before enter; empty allowed; controller-usable |
| 4.9 | Compiler screen | In-game genesis for new/prompt worlds (watch factions/NPCs form). Continue skips it |

Prompted worlds still obey: AI suggests, engine commits. Runtime: [`epics/06-agent-runtime.md`](epics/06-agent-runtime.md) (planned infra; do not skip the hub to build it).

---

## 5. Loadout persistence — Next

Worn **loadout** is the character’s through-line. Outfit is saved too, and is not the loadout.

| ID | Feature | Notes |
| --- | --- | --- |
| 5.1 | Two-hand equipment | Left / right (or main / off) slots |
| 5.2 | Armor slots | Helmet, torso, gloves, **cape**, legs, boots |
| 5.3 | Cape physics | Cloth sim on the cape slot / visible outfit cape |
| 5.4 | Accessory slots | Necklace, **2 rings**, **2 earrings**. Gear, not deferred flavor |
| 5.5 | Outfit layer | Full cosmetic control. Armor ≠ appearance. Does not change playstyle |
| 5.6 | Same slots on companions | Player can fully kit and dress them |
| 5.7 | Equip in hub and worlds | Same character, same loadout + outfit |
| 5.8 | Travel rule | Current loadout and outfit always come through the portal both ways |
| 5.9 | Character save | Body, race tag, skills, loadout, outfit survive quit / relaunch |
| 5.10 | Sanctum storage | **Later** — buildable stash / home storage so finds and materials can stay home unequipped |

Until 5.10, worn loadout = what you keep. Dressing someone in a different outfit must not rewrite their combat role.

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
| 6.12 | Companion combat | Field companions fight with the same gear/XP rules; AI-driven, not player-specced |
| 6.13 | Downed | Player and companions can go down and be healed back up |
| 6.14 | Heal nodes | World crystal shards (Arknights originium-shard analog); range heal + raise downed |
| 6.15 | Party wipe | Everyone down, no node in range → retreat to last node or entrance; keep loadout |

Unarmed, two-handed weapons, and shared-vs-separate combat stamina wait on open questions in the design doc. Parkour stays available in combat spaces; attacks stay heavy. First down is not permadeath.

---

## 7. Companions and a living Sanctum — Later

Mass Effect field slots, Arknights roster. Companions are full characters. The player does not spec their trees. The Sanctum is a **cozy sim** that grows with people, farms, and collectible home designs.

| ID | Feature | Notes |
| --- | --- | --- |
| 7.1 | Companion identity | Named full characters: same loadout slots, outfit layer, Fable paths |
| 7.2 | Story recruit | Recruited in a world; may fill/swap a field slot **in that story** before 100% trust |
| 7.3 | Trust 0–100% | Earned in stories (and later in the hub). Not instant. |
| 7.4 | 100% gate | Unlocks hub residence **and** roster eligibility for further quests |
| 7.5 | Roster | All 100% companions live in the Sanctum |
| 7.6 | Field slots | **Two** + player. Portal picker. Empty OK. |
| 7.7 | Action-driven growth | No player talent screen. Affinities from what they actually do |
| 7.8 | Plastic vs locked | Low-level recruits reshape (healer vs mage from whether they had to heal). High-level recruits stay mostly the person you hired |
| 7.9 | Combat AI | Engine picks actions from affinities + party state. LLM does not spend their XP |
| 7.10 | Outfit companions | Player dresses them; look ≠ playstyle |
| 7.11 | Kit companions | Player may equip their hands/armor/accessories; weapons still drive XP |
| 7.12 | Romance | Supported. **Polyamory allowed** — not a one-partner lock |
| 7.13 | Jealousy | Some companions only. **Procs if they meet**, never omniscient |
| 7.14 | Residents | Presence in the Sanctum when you return |
| 7.15 | Help / labor | Companions assist farming, harvest, and light upkeep |
| 7.16 | Shops | Trusted companions can open services in the Sanctum |
| 7.17 | Sanctum level | Home progression separate from combat paths; XP from materials, harvests, designs, builds, companions housed |
| 7.18 | Farming | Plots on the rock; plant → **real-time** grow → harvest materials; capacity gated by Sanctum level |
| 7.19 | Simple building | Place unlocked designs with wood/metal/fiber on pads; **one instance per design**; no voxel editor |
| 7.20 | Home design collectibles | Study building in world → unlock; Sanctum places **same catalog mesh** |
| 7.21 | Starter camp design | Humble early unlock so building can start before rare story finds |
| 7.22 | Materials bank | **Wood / metal / fiber** only (v0); world finds + farm → Sanctum storage → builds |
| 7.23 | Cozy dwell | Live with roster, romance, decorate (decorate layers after structures) |
| 7.24 | Squad UI on controller | Pick/swap field slots without a mouse |

Do not pre-place shop NPCs “for now” in the destination hub. Temporary debug spawns are fine if they cannot be invited without 100% trust. Do not ship a companion skill menu the player points at. Do not ship a freeform house editor.

---

## 8. Worlds and story — Later

Deepen what happens beyond the portal.

| ID | Feature | Notes |
| --- | --- | --- |
| 8.1 | Random world content | Places, encounters, loot that make 4.2 worth repeating |
| 8.2 | Agentic story | Prompt + play feed structured story development. Consumes pack 06; does not invent a second LLM client |
| 8.3 | Race tags in story | Worlds and NPCs can react to the stored race tag |
| 8.4 | Continue fidelity | A previous world is recognizably the same place you left |
| 8.5 | Multi-world | If we allow more than one continued world, a picker (open question) |
| 8.6 | Heal nodes | Place crystal shards in generated/authored worlds as revive/heal infrastructure |
| 8.7 | World compiler v0.1 | Constitution → seed → map/factions/major NPCs; compiler UI; enter first settlement |
| 8.8 | Holy shit test | Generate, meet NPC, change something, leave, return, they remember why |
| 8.9 | Content catalog | Approved buildings/items/props library; compiler places by `catalog_id` ([`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md)) |
| 8.10 | Generate → approve loop | Agent pre-screen (**mesh required**) → you final-approve → catalog. Agents never set `approved` alone |
| 8.11 | Dense placement | Settlements sample many approved buildings/props; gate: **≥20 approved buildings** |
| 8.12 | Learn → collect | **Study** interact on building → unlock collection / Sanctum designs |
| 8.13 | Flexible content defs | Stable core + open `properties` bag; unknown keys ignored; schema_version for core breaks |
| 8.14 | First building pump | **Log cabin set** — cozy timber dwellings + cabin kit variations |

Architecture notes: [`02-WORLD-COMPILER.md`](02-WORLD-COMPILER.md), [`01-GAMEPLAY-LOOP.md`](01-GAMEPLAY-LOOP.md), [`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md). Do not skip the hub first-playable slice for this.

---

## Suggested first playable slice

Smallest thing that feels like *this* game rather than a walker:

1. Loading screen → title (New / Load / Settings / Quit), **on a controller**
2. New → race + **male/female** + a few body sliders → confirm, **on a controller**
3. Empty Sanctum (floating rock, dusk-void, freestanding portal arch), same camera language
4. Sprint, jump, mantle, **climb a wall**, **wall-run a stretch**, all on a controller
5. Portal → one graybox “random world” (still climbable) → return still wearing a test item

Character morph depth (pack 07), Fable combat, **companion roster**, **Sanctum cozy sim** (farm / build / design collectibles), and prompted story come after that loop is real. The first fight, when it lands, should already feel heavy and lock-on-based — not a placeholder twin-stick. Traversal should already feel like light WuWa / TotK / Genshin parkour, not a walker. The first companion slice is: recruit in a story, watch them grow from actions, hit 100% trust, bring them home, take them out again in a field slot. Combat should already support **downed + heal node** before permadeath fantasies creep in.

---

## Agent runtime — Later (infra)

Epics: [`epics/06-agent-runtime.md`](epics/06-agent-runtime.md) (AR-1…AR-6). Contract: [`14-AGENT-RUNTIME.md`](14-AGENT-RUNTIME.md). Index: [`epics/README.md`](epics/README.md).

Not first-playable. Needed **before** prompted worlds (4.4) and agentic story (8.2). Gameplay stays complete with AI off. Local-first (Ollama); Player2 optional. No developer-hosted LLM.

| ID | Feature | Notes |
| --- | --- | --- |
| AR.1 | Statemachine | Owns world state: save, serve snapshots, commit/reject tools |
| AR.2 | Orchestrator | Host worker inventory, queue, score by requirements × urgency (weak devices may still take heavy jobs) |
| AR.3 | Local workers | Ollama + custom OpenAI-compat; three-layer tool decode |
| AR.4 | Player2 worker | Optional loopback worker; never required to play |
| AR.5 | AI settings | Enable workers, test connection, AI off; gamepad |
| AR.6 | Tool jobs | Job-scoped catalogs + host complete/commit loop; portal UI is pack 05 |

Do not let jobs HTTP a provider. Do not let workers mutate saves. Multiplayer peer routing: [`DEF-016`](backlog/deferred/DEF-016-multiplayer-worker-routing.md). Player2 voice: [`DEF-017`](backlog/deferred/DEF-017-player2-voice.md).

---

## Explicitly not this list

- Summer / Cursor / MCP features (tooling, not the game)
- Replacing the test/build/play scripts
- Making the LLM own Sanctum, inventory, farm, or building state
- Treating Kenney / graybox town meshes as the art target
- A player-facing talent tree for companions
- A freeform voxel / stud-by-stud house editor
- Treating armor/loadout as the character’s visible outfit
- Omniscient jealousy (if they have not met, it does not fire)
- Permadeath on a single down
- Dumping the full home-design / content catalog on New Game
- Auto-approving every generated asset into the playable catalog
- Letting agents mark catalog rows `approved` without your final say-so
- Letting runtime directors invent new catalog art ids without the approval loop
- Unique NPC / companion faces that cannot be rebuilt in the character creator
- Vendoring the Player2 Godot NPC plugin or Player2 cloud saves as world authority
- Shipping a managed llama.cpp runtime inside Godot
- A developer-hosted LLM / agent dispatcher
- Hard-banning weak devices (e.g. Steam Deck) from heavy agent jobs — score them, do not veto
