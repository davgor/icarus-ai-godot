# Epic pack 03 — Sanctum hub (inhabit + Arrange)

**Status:** Planned  
**Feature-list:** [`feature-list.md`](../feature-list.md) §3 Hub — Sanctum  
**Design:** [`game-design.md`](../game-design.md) Hub — the Sanctum (two ways to play)  
**Art:** [`art-style.md`](../art-style.md), [`art/prompt-lock.md`](../art/prompt-lock.md) — Hub / Sanctum / furniture / light / path suffixes  
**Catalog:** [`../12-CONTENT-CATALOG.md`](../12-CONTENT-CATALOG.md) — `place_kind`, starter kit, `sanctum_placeable`  
**Persistence:** [`../08-PERSISTENCE.md`](../08-PERSISTENCE.md) — Arrange layout on the hub save  
**Import roots:** `game/art/hub/` (rock, sky, portal, starter kit), `game/art/ui/` (Arrange chrome / glyphs), `game/art/vfx/` (embers, stardust, fall return)  
**Operating loop:** [`agent-operating-loop.md`](../agent-operating-loop.md) + [`.summer/AGENTS.md`](../../.summer/AGENTS.md)

Creator **Confirm** already hands off to [`game/hub/hub_stub.tscn`](../../game/hub/hub_stub.tscn) (CC-8). This pack **replaces that stub** with the real Sanctum. Keep the character record and creator scene.

The Sanctum is not a third-person lobby. It is playable two ways:

1. **Inhabit** — third-person follow. Walk the rock, look at the void, use the portal, fall and return.
2. **Arrange** — camera **flips to top-down**. Reorganize the island: buildings, furniture, lights, ground/path paints.

Worlds never get this split. Parkour **moves** stay pack 04; this pack still ships **parkour-legal geometry**. Portal **modes** stay pack 05; this pack still ships a present, interactable arch.

Suggested ship order: **SH-1 → SH-2 → SH-3 → SH-4 → SH-5 → SH-6 → SH-7 / SH-8 / SH-9 / SH-10 (parallel after SH-6) → SH-11 → SH-12**.  
SH-11 (persist) can start as soon as SH-6 writes instances. SH-12 can start as soon as SH-5 has focusable chrome.

**Vertical-slice cut** (minimum Playable): SH-1, SH-2, SH-3, SH-5, SH-6, one building + one furniture + one light + one path paint from the starter kit, SH-11 round-trip, inhabit + Arrange on pad (SH-2 + SH-12). SH-4 geometry can land with SH-1.

---

## Shared locks (all SH epics)

- **Two modes, Sanctum only.** Inhabit = third-person follow (same language as worlds). Arrange = top-down over the islet. Toggle is a dedicated action. Worlds do not flip.
- **Empty of people.** No shopkeepers, neighbors, or pre-authored residents. Millbrook Living Town is not home — isolate or hide it; do not grow it.
- **Empty of houses.** Portal is the only pre-placed structure. Starter kit is **unlocked, not pre-placed**.
- **Not a voxel editor.** Place catalog pieces and paint ground. No stud-by-stud walls, no sculpting a new island silhouette.
- **Legal volume, not numbered lots.** Home bowl + terraces are the buildable surface. Engine volumes/pads are fine under the hood; the player places things *on the rock*.
- **Buildings:** one active instance per catalog id. Furniture and lights: multiples OK. Ground paints: brush / splat, not a mesh instance.
- **Starter kit is free.** New Game can Arrange immediately. Wood / metal / fiber spend on collected designs is later cozy-sim ([`feature-list.md`](../feature-list.md) §7) — Deferred: [`DEF-021`](../backlog/deferred/DEF-021-arrange-material-spend.md).
- **Dusk-void always.** No daytime sky. Placed lights always read. Embers / stardust around the rock.
- **Controller is first-class.** No mouse-cursor-emulation gamepad path. KBM stays in parallel.
- **Engine owns layout.** LLM / generators do not write placed instances. Catalog rows must be `approved` (starter kit ships approved).
- Visuals: lock v2, warmer lantern gold on stone, cooler dusk-void sky. Image `style` is **`"anime"`**. Prepend the prompt-lock prefix; pass `options.negative_prompt`. Prefer `game/art/_style/hub_dusk_v1.png` as ref. Never use Kenney / `game/art/town/` as style.
- Import hub meshes/textures under `game/art/hub/`. Arrange chrome under `game/art/ui/`. Do not park finals in `_style/`. Existing `game/art/hub/*.glb` may seed the starter kit if they pass a lock read; replace if they read as village-graybox.
- Headless tests: `tests/run_tests.gd` (`extends SceneTree`), gate on `TEST_RESULT: PASS`.
- Canonical commands: `.\scripts\test.ps1` → Summer play/diagnostics when scene work lands → `.\scripts\build.ps1` / `.\scripts\play.ps1` when the slice should be playable.
- Do **not** add Summer SDK or editor-only APIs to shipped game code. Do **not** run `godot --import` while Summer is open on this repo.

---

## Summer workflow (required for this pack)

This pack is **Summer-first**. Sanctum scene, cameras, placement ghosts, sky/VFX, and play smokes go through Summer MCP when connected. Edit GDScript in Cursor.

### Required cycle (after any scene or runtime-affecting change)

```text
summer_get_project_context
        ↓
summer_get_diagnostics          ← always before console/debugger
        ↓
summer_open_main_scene          ← if currentScene is null; then open Sanctum scene
        ↓
summer_get_scene_tree(scenePath=<sanctum or flow scene>)
        ↓
mutate with that same scenePath
        ↓
edit GDScript in Cursor (modes, placement, save)
        ↓
summer_get_script_errors
        ↓
.\scripts\test.ps1
        ↓
summer_clear_console → summer_play → wait → summer_get_diagnostics
        ↓
fix → play → inspect again
        ↓
summer_stop
```

Main flow still roots at `res://game/main.tscn`. Sanctum should be a **dedicated scene** (replace `res://game/hub/hub_stub.tscn` or swap the packed scene CC-8 instantiates). Do not rename Millbrook town into the hub.

```text
❌ position: { "x": 2, "y": 1, "z": 0 }
✅ position: "Vector3(2, 1, 0)"
❌ parent: "Main/Player"
✅ parent: "./" or path: "./Player"
```

### Summer generate / import

| Job | Tool | Hard rules |
| --- | --- | --- |
| Rock / sky / portal / furniture / lantern / path stills | `summer_generate_image` | `style: "anime"` only; prepend lock; negative from lock; `Read` `localPath` before import |
| Rock, portal, starter meshes | `summer_generate_3d` | Prefer image-to-3d from a style-locked concept; `assetIntent` environment / prop as appropriate |
| Live look checks | `summer_screenshot` | Prefer `target: "game"` while playing Inhabit **and** Arrange; top-down stills must be real play, not editor ortho |
| Hierarchy / volumes | `summer_get_scene_tree`, add/set tools | Always pass explicit `scenePath` |

**Pipeline per asset:** read art docs → prepend lock → generate → `Read` preview → compare to bible → import under `game/art/hub/` or `game/art/ui/` → wire via Summer → play both modes → diagnostics.

### Summer play acceptance (pack-level)

Pad- or KBM-driven smoke when the vertical slice lands:

1. Title → New → creator → Confirm → **Sanctum**, not Millbrook, not hub stub plaza-as-home.
2. Inhabit: walk spawn terrace → home bowl → portal overlook; dusk-void sky and stardust read.
3. Interact with the portal (stub “coming soon” / hook is OK; do not no-op with no feedback).
4. Walk off the rim → free fall a few seconds → warp to home bowl.
5. Toggle **Arrange** → camera flips top-down; whole islet readable; pan/zoom.
6. Place starter **building**, **furniture**, **light**, and paint a **path**; ghost preview before commit.
7. Move / rotate / remove at least one piece. Building one-instance rule holds (second place of same building relocates or refuses).
8. Exit Arrange → Inhabit camera restored; walk the new layout; placed light is visible; path is underfoot.
9. Quit / reload (or re-enter from title Load if wired) → layout still there — or headless save round-trip if Load is still empty ([`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md)).
10. Repeat 5–8 on a **gamepad** with no mouse.

After each smoke: `summer_get_diagnostics`. Fix before declaring the epic playable.

---

## SH-1 — Sanctum rock, sky, and portal

### Outcome

Confirm spawns the player on a **floating dusk-void rock** with a freestanding **portal arch** on the overlook. It reads as the Sanctum, not a graybox plane and not Millbrook.

### Maps to

| ID | Feature |
| --- | --- |
| 3.1 | Sanctum scene |
| 3.3 | Portal present |
| 3.4 | Player spawn |
| 3.9 | Dusk-void + stardust |

### In scope

- Dedicated Sanctum scene replacing `hub_stub` as the CC-8 destination
- Climbable stone islet: spawn terrace → home bowl → portal overlook
- Dusk-void sky (purple/blue nebula, never daytime)
- Embers / stardust around the rock
- Freestanding portal arch on the overlook (interactable hook can be SH-2)
- Player spawns as the created appearance (shared `AppearanceApplier`)
- Isolate / hide Living Town so it is not the home

### Out of scope

- Arrange camera (SH-5)
- Portal Continue / New random / Prompt UI (pack 05 — not a DEF ticket)
- Relocate / cosmetic-swap the portal — Deferred: [`DEF-020`](../backlog/deferred/DEF-020-portal-relocate-cosmetic.md)
- Parkour **moves** (pack 04). Geometry should still be rim-legal (SH-4 may land with this epic).
- Farming loop (later cozy-sim pack)

### Dependencies

- CC-8 hub handoff
- Style lock v2 + `hub_dusk_v1` ref

### Work

- `res://game/hub/sanctum.tscn` (name may vary; not `hub_stub` as the intended destination)
- Swap `HubStubPacked` in `game/main.gd` (or equivalent flow) to the Sanctum scene
- Sky, lighting, VFX, collision for the rock
- Tests: flow after Confirm is Sanctum; Millbrook is not the active home scene

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Sanctum rock concept | `game/art/hub/sanctum_rock_concept.png` | Start of epic | Hub — Sanctum suffix; one small islet; empty bowl; portal silhouette on rim |
| Rock mesh / textures | `game/art/hub/sanctum_rock.*` | After concept | image-to-3d; climbable stone; lantern-gold warm on rock |
| Dusk-void sky / panorama | `game/art/hub/sanctum_sky.*` | With rock | Ethereal purple/blue nebula; never daytime blue |
| Portal arch | `game/art/hub/portal_arch.*` | With rock | Freestanding mystical arch; cyan/gold emissive; not a door in a wall |
| Ember / stardust sprites | `game/art/vfx/sanctum_ember.png`, `sanctum_stardust.png` | With sky | Sparse floaty motes; readable; not particle soup |
| Optional: reuse | `game/art/hub/torii.glb` as portal stand-in | Only if lock-read passes | Replace before calling the scene done if it reads as village gate |

**Pipeline:** lock → `style: "anime"` → generate → `Read` → import `game/art/hub/` or `vfx/`.  
**Negative:** lock negative; no Kenney, no graybox, no daytime suburb.

### Acceptance

- [ ] Confirm lands on the Sanctum rock, not Millbrook, not a blank stub plane as home
- [ ] Dusk-void sky + stardust/embers read in play
- [ ] Portal arch present on the overlook
- [ ] Created appearance spawns via shared applier
- [ ] Assets under `game/art/hub/` (VFX under `vfx/`)
- [ ] Summer smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-2 — Inhabit: third-person home

### Outcome

On the Sanctum the player **walks and looks** in third-person, reaches the portal, and gets feedback on interact. This is living on the rock, not Arrange.

### Maps to

| ID | Feature |
| --- | --- |
| 3.2 | Empty-on-new |
| 3.3 | Portal present (interact) |
| 3.5 | Return point (hook) |
| 3.7 | Inhabit on controller |

### In scope

- Third-person follow cam (existing player cam language)
- Walk the terrace / bowl / overlook
- Portal interact: readable prompt; stub response OK (“The portal is quiet” / opens pack-05 hook) — never silent
- Empty of NPCs and pre-placed houses
- Gamepad: walk, look, interact, and the Arrange toggle *binding* (toggle may no-op until SH-5)
- Keyboard/mouse in parallel

### Out of scope

- Arrange placement (SH-5+)
- Portal modes UI (pack 05)
- Climb / wall-run (pack 04)
- Load from title of hub layout — Deferred: [`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md)

### Dependencies

- SH-1 scene
- Pack 01 / 02 input + player controller

### Work

- Interaction component on the portal
- Ensure Living Town HUD/NPCs are not in this flow
- Tests: spawn empty of residents; portal interact emits a known state; cam is follow not ortho

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Interact prompt glyphs | `game/art/ui/glyph_interact.png` | If OS-6 set lacks it | Reuse OS-6 mystical glyphs if present |
| Portal interact hint | `game/art/ui/prompt_portal.png` | With interact | Sparse dark-jewel prompt plate; no paragraph text baked in |

### Acceptance

- [ ] Third-person walk from spawn to portal
- [ ] Portal interact is readable (pad + KBM)
- [ ] No residents / no pre-placed houses
- [ ] Summer inhabit smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-3 — Soft fall return

### Outcome

Walking or falling off the rock is a short dusk-void drop, then a soft warp back to the **home bowl**. Not death. Inhabit only.

### Maps to

| ID | Feature |
| --- | --- |
| 3.10 | Soft fall return |

### In scope

- Detect leaving the rock (volume or height)
- Free fall **a few seconds** with readable void
- Warp to home-bowl marker (not last ledge, not a death screen)
- Brief, not a punishment run

### Out of scope

- Arrange (player is not a falling pawn in top-down)
- Damage / downed / heal nodes (combat pack)
- Invisible waist-high rails (forbidden)

### Dependencies

- SH-1 rock + bowl marker
- SH-2 inhabit movement

### Work

- Fall volume / kill plane under the islet
- Return marker in the home bowl
- Tests: leaving the rock eventually respawns in-bowl; no `queue_free` player

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Fall / return VFX | `game/art/vfx/sanctum_return_bloom.png` | Polish | Short mystical bloom; sparse; no text |

### Acceptance

- [ ] Walk off rim → fall → return to bowl
- [ ] No death UI
- [ ] No waist-high invisible rail
- [ ] Summer fall smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-4 — Parkour-legal hub geometry

### Outcome

Rim cliffs, stacks, and the portal approach are **climbable surfaces** with no waist-high invisible walls. The **move list** is pack 04; this epic is the mesh and collision so parkour has somewhere to go.

### Maps to

| ID | Feature |
| --- | --- |
| 3.8 | Parkour-legal hub |

### In scope

- Rock collision that a future climb can attach to (near-vertical rims, stacks)
- No invisible fences at waist height
- Portal approach has vertical play, not a corridor of walls
- Placed-building footprint notes: roofs/walls should be climbable when SH-7 lands (document collision layers)

### Out of scope

- Jump, mantle, climb, wall-run implementation (pack 04 — not a DEF ticket)
- Traversal meter (pack 04)
- Extreme morph retarget — [`DEF-009`](../backlog/deferred/DEF-009-extreme-morph-anim-retarget.md)

### Dependencies

- SH-1 rock mesh

### Work

- Collision / collision layers on the islet
- Tests or scene assertions: no `StaticBody` fence rings at player-waist height on the rim
- Comment / doc the intended climb faces for pack 04

### Asset generation

No new chrome. If the rock mesh is a pancake, regenerate per SH-1 (silhouette must have rims and stacks).

| Asset | Path | Generate when | Notes |
| --- | --- | --- | --- |
| *(none extra)* | — | — | Reuse / fix SH-1 rock; do not add Kenney walls |

### Acceptance

- [ ] Rim is open to the void (SH-3 fall still works)
- [ ] Approach to portal has climbable vertical, not a waist fence
- [ ] Summer walk the rim + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-5 — Arrange mode: flip to top-down

### Outcome

A dedicated action **flips** the Sanctum to a top-down island view. The whole islet is readable. Pan and zoom. This is the other way the hub is played.

### Maps to

| ID | Feature |
| --- | --- |
| 3.11 | Inhabit / Arrange |
| 3.12 | Arrange camera |
| 3.20 | Exit Arrange (camera restore; full restore with placement is SH-6+) |

### In scope

- Mode flag owned by the engine (not a debug fly-cam)
- Camera: orthographic or steep near-ortho top-down; islet framed; pan + zoom
- Enter / exit action on pad and KBM; documented default
- Exiting restores Inhabit follow cam and last inhabit pose (or bowl if invalid)
- Pause inhabit locomotion while Arranging (player pawn hidden, ghosted, or parked — pick one and keep it)
- Arrange HUD shell (empty catalog OK until SH-6)

### Out of scope

- Placement (SH-6+)
- Strategy-game fog of war / minimap
- World / combat camera changes
- Undo stack — Deferred: [`DEF-022`](../backlog/deferred/DEF-022-arrange-undo-redo.md)

### Dependencies

- SH-1 / SH-2
- Glyph language from OS-6 preferred

### Work

- `ArrangeMode` (or equivalent) on the Sanctum
- Camera rig swap; input map actions `sanctum_arrange_toggle`, pan, zoom
- Tests: toggle twice returns to inhabit cam; worlds/creator unaffected; mode persisted only as UI state (layout persist is SH-11)

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Arrange mode still (UI ref) | `game/art/ui/arrange_mode_ref.png` | Start of epic | Sanctum Arrange (top-down still) suffix; chrome-free atmosphere OK |
| Mode toggle glyph | `game/art/ui/glyph_arrange.png` | With toggle | Match OS-6 set; generic shape; no console trademarks |
| Arrange HUD frame | `game/art/ui/arrange_hud_frame.png` | With shell | Dark jewel editor chrome; sparse gold; not sci-fi RTS |

### Acceptance

- [ ] Toggle enters top-down; islet readable
- [ ] Pan / zoom work on pad and mouse
- [ ] Exit restores third-person Inhabit
- [ ] Not a mouse-cursor overlay as the pad path
- [ ] Summer both-mode screenshots + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-6 — Shared placement (ghost, rotate, move, remove)

### Outcome

Arrange can **select a catalog piece, ghost it, rotate it, commit it, pick it back up, and remove it** on the legal volume. Buildings, furniture, and lights all use this system. Ground paint is SH-10 (brush), but shares legal-volume and input.

### Maps to

| ID | Feature |
| --- | --- |
| 3.6 | Buildable surface + farm hooks (volume; farm **hooks** only) |
| 3.13–3.15 | Placement verbs (content catalogs fill in SH-7…9) |

### In scope

- Legal volume: home bowl + terraces (farm plot hook volumes marked, not plantable yet)
- Ghost preview; invalid pose reads as invalid (overlap, off-rock, void)
- Rotate (yaw); place; select existing; move; remove
- Grid snap optional; must still feel like placing on the rock
- Catalog picker shell (categories: building / furniture / light / ground) — empty rows OK until later SH
- Engine list of instances `{ catalog_id, place_kind, transform, instance_id }`

### Out of scope

- Per-kind catalogs (SH-7…10)
- Save/load (SH-11 can wire the same list)
- Interior rooms — Deferred: [`DEF-018`](../backlog/deferred/DEF-018-sanctum-interior-rooms.md)
- Terrain sculpt — Deferred: [`DEF-019`](../backlog/deferred/DEF-019-sanctum-terrain-sculpt.md)
- Material costs — Deferred: [`DEF-021`](../backlog/deferred/DEF-021-arrange-material-spend.md)

### Dependencies

- SH-5 camera + HUD shell

### Work

- Placement controller + legal-volume queries
- Instance container under the Sanctum scene
- Tests: invalid pose rejected; remove deletes instance; rotate changes yaw; farm hooks exist as volumes (count ≥ 1) but do not plant

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Ghost / invalid tint | `game/art/vfx/arrange_ghost_ok.png`, `arrange_ghost_bad.png` | With placer | Readable valid/invalid; sparse; not a red error dialog |
| Catalog slot chrome | `game/art/ui/arrange_slot.png` | With picker | Dark jewel slot; fits furniture thumb |

### Acceptance

- [ ] Ghost → place → select → move → remove on legal volume
- [ ] Off-rock / void rejects
- [ ] Farm hooks present, not planted
- [ ] Summer place/remove smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-7 — Building placement

### Outcome

In Arrange the player places a **home design** (starter camp/shelter). One active instance per building id. Relocate is move, not a second copy.

### Maps to

| ID | Feature |
| --- | --- |
| 3.13 | Building placement |
| 3.19 | Starter arrange kit (building piece) |

### In scope

- Starter camp / shelter catalog row: `place_kind: building`, `sanctum_buildable`, cost 0
- Place / rotate / move / remove via SH-6
- Second place of the same id relocates the existing instance or refuses with readable feedback
- Climbable roof/walls where the mesh reads as architecture (collision)
- Shared catalog mesh rule: no second “hub-only” polish mesh

### Out of scope

- Full world-unlocked design library (later cozy-sim / catalog pack — not a DEF ticket)
- Material spend — [`DEF-021`](../backlog/deferred/DEF-021-arrange-material-spend.md)
- Interior of the building — [`DEF-018`](../backlog/deferred/DEF-018-sanctum-interior-rooms.md)
- Voxel walls (never)

### Dependencies

- SH-6
- Catalog envelope in [`12-CONTENT-CATALOG.md`](../12-CONTENT-CATALOG.md)

### Work

- Starter building def + mesh wired into Arrange catalog
- One-instance enforcement in the engine
- Tests: two commits of same building id → one instance; remove clears; Inhabit can walk around it

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Starter camp concept | `game/art/hub/starter_camp_concept.png` | Start of epic | Sanctum home design suffix; humble shelter; empty Sanctum mood |
| Starter camp mesh | `game/art/hub/starter_camp.*` or `game/art/catalog/buildings/starter_camp/` | After concept | Same mesh the catalog will use later |
| Catalog thumb | `game/art/hub/starter_camp_thumb.png` | With picker | Readable from Arrange slot |

Reuse `game/art/hub/cottage.glb` only as a stand-in after a lock read; do not ship Kenney as the starter camp.

### Acceptance

- [ ] Place starter camp from Arrange
- [ ] One instance per building id
- [ ] Inhabit can walk the placed camp
- [ ] Summer + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-8 — Furniture placement

### Outcome

Arrange places **furniture** (bench, table, crate, planter). Multiples allowed. Readable in top-down and in Inhabit.

### Maps to

| ID | Feature |
| --- | --- |
| 3.14 | Furniture placement |
| 3.19 | Starter arrange kit (furniture) |

### In scope

- ≥3 starter furniture rows, `place_kind: furniture`, multiples OK, cost 0
- Place on island and on a building footprint (no interior room editor)
- SH-6 verbs

### Out of scope

- Wall hangings, second-floor rooms, roof-off interiors — [`DEF-018`](../backlog/deferred/DEF-018-sanctum-interior-rooms.md)
- Collected world furniture sets (later catalog / cozy-sim pack)

### Dependencies

- SH-6; SH-7 if footprint placement is in-slice (footprint can be rock-only until camp exists)

### Work

- Furniture defs + meshes
- Tests: two benches of the same id may both exist; building one-instance still holds

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Furniture concepts (×N) | `game/art/hub/furniture_{id}.png` | Start of epic | Sanctum furniture suffix |
| Furniture meshes | `game/art/hub/furniture_{id}.*` | After concepts | Isolated props; readable from above |

Vertical-slice minimum: **≥3 furniture**.

### Acceptance

- [ ] Place multiple copies of one furniture id
- [ ] Visible in Arrange and Inhabit
- [ ] Summer + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-9 — Light placement

### Outcome

Arrange places **lanterns / lamps that emit**. Dusk-void never goes day, so they always matter. Multiples allowed.

### Maps to

| ID | Feature |
| --- | --- |
| 3.15 | Light placement |
| 3.19 | Starter arrange kit (lights) |

### In scope

- ≥2 starter lights, `place_kind: light`, real `OmniLight3D` / equivalent (not albedo-only)
- Warm lantern gold; sparse; does not blow out the void
- SH-6 verbs; multiples OK

### Out of scope

- Sanctum time-of-day / weather — Deferred: [`DEF-023`](../backlog/deferred/DEF-023-sanctum-time-of-day.md)
- Interior-only fixtures — [`DEF-018`](../backlog/deferred/DEF-018-sanctum-interior-rooms.md)

### Dependencies

- SH-6
- SH-1 lighting so added lights read against dusk-void

### Work

- Light prefab: mesh + actual light node, intensity tuned in play
- Tests: placed light increases illuminance near it (or a proxy: light node exists and `visible`); remove extinguishes

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Lantern / lamp concepts | `game/art/hub/light_{id}.png` | Start of epic | Sanctum light fixture suffix |
| Light meshes | `game/art/hub/light_{id}.*` | After concepts | Emissive warm gold; isolated |

Reuse `game/art/hub/lantern.glb` after a lock read if it emits in-scene (mesh alone is not enough — add a light).

### Acceptance

- [ ] Placed light is visible in Inhabit at dusk
- [ ] Multiples OK
- [ ] Remove turns the light off
- [ ] Summer night-read screenshot + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-10 — Ground and path paints

### Outcome

Arrange **paints** the rock: stone path, packed dirt, moss (or equivalent). This is texture / decal / splat on the existing islet — not sculpting a new island.

### Maps to

| ID | Feature |
| --- | --- |
| 3.16 | Ground / path paints |
| 3.19 | Starter arrange kit (paints) |

### In scope

- ≥3 paint layers / brushes, `place_kind: ground_paint`
- Brush size + paint / erase on legal volume
- Readable in top-down and underfoot in Inhabit
- Does not change rock collision silhouette
- Does not block parkour

### Out of scope

- Heightmap / terrace sculpt / island resize — [`DEF-019`](../backlog/deferred/DEF-019-sanctum-terrain-sculpt.md)
- Voxel tiles (never)

### Dependencies

- SH-5 / SH-6 legal volume
- Rock mesh that can receive a splat, decal, or texture layer

### Work

- Paint buffer or decal projector owned by the hub save (SH-11 serializes it)
- Tests: paint then erase restores default; paint off-rock ignored; collision AABB of the rock unchanged

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Path / dirt / moss albedos | `game/art/hub/ground_{path,dirt,moss}.*` | Start of epic | Sanctum ground / path paint suffix; tileable |
| Brush cursor | `game/art/ui/arrange_brush.png` | With paint tool | Sparse circular glyph; dark jewel |

Reuse `game/art/hub/cobble_albedo.png` only if it passes a lock read as dusk cobble, not Kenney pavement.

### Acceptance

- [ ] Paint a path in Arrange; walk it in Inhabit
- [ ] Erase works
- [ ] Rock silhouette / fall volumes unchanged
- [ ] Summer + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## SH-11 — Layout persistence and starter kit

### Outcome

The starter kit is **unlocked on New Game**. Placed buildings, furniture, lights, and ground paints **survive** quit / relaunch and (once pack 05 exists) portal return. Engine-owned hub save. Not Millbrook `living_town_v1.json`.

### Maps to

| ID | Feature |
| --- | --- |
| 3.17 | Layout persistence |
| 3.19 | Starter arrange kit |
| 3.2 | Empty-on-new (kit unlocked, nothing pre-placed) |
| 3.5 | Return point (layout still there when return exists) |

### In scope

- Versioned hub layout blob: instances + paint layers + catalog unlocks
- New Game writes starter unlocks, zero instances
- Reload restores transforms and lights
- Distinct from character appearance record; may live beside it in the same save file
- Headless round-trip test

### Out of scope

- Title Load browser polish — [`DEF-004`](../backlog/deferred/DEF-004-load-browser-polish.md) / [`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md)
- Millbrook migration — [`DEF-005`](../backlog/deferred/DEF-005-millbrook-save-migration.md)
- Material bank spend — [`DEF-021`](../backlog/deferred/DEF-021-arrange-material-spend.md)
- World Continue (pack 05)

### Dependencies

- SH-6 instance list; SH-7…10 content; CC-8 character write

### Work

- Schema `hub_layout` (name may vary) with `schema_version`
- Grant starter catalog ids on New Game
- Tests: empty new save has unlocks and zero instances; place then serialize then load matches; building one-instance still holds after load

### Asset generation

No new world art. Optional save-slot thumb later is [`DEF-004`](../backlog/deferred/DEF-004-load-browser-polish.md).

| Asset | Path | Generate when | Notes |
| --- | --- | --- | --- |
| *(none)* | — | — | No new art — reuse Arrange / Sanctum assets |

### Acceptance

- [ ] New Game: starter kit in catalog, rock empty except portal
- [ ] Place kit → quit → launch → layout restored (or headless equivalent if Title Load still empty)
- [ ] Not `user://living_town_v1.json` as the hub schema
- [ ] `TEST_RESULT: PASS`

**Deferred review (implementation):** rope [`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md) if Title Load can already list character saves — do not leave Arrange layout unloadable from title if CC-8 saves are already continuable.

---

## SH-12 — Arrange on controller

### Outcome

Full Arrange is usable on a **gamepad**: toggle, pan/zoom, catalog, ghost, rotate, place, move, remove, paint, exit. Focus visible. No mouse-cursor overlay.

### Maps to

| ID | Feature |
| --- | --- |
| 3.18 | Arrange on controller |
| 3.7 | Inhabit on controller (toggle reachable from Inhabit) |

### In scope

- Documented pad map (toggle, camera, rotate, place, cancel, category rail, brush size)
- Focus ring on catalog and tools
- Glyphs (reuse OS-6; add Arrange-specific as needed)
- KBM still works

### Out of scope

- Full Controls rebind UI — [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md)
- Mouse-cursor stick emulation as the solution

### Dependencies

- SH-5…SH-10 chrome; OS-6 glyph language

### Work

- InputMap joypad bindings for Arrange
- Focus graph with no traps on the main path
- Tests: required actions exist
- Manual / **Summer play:** pad-only Confirm → Inhabit → Arrange → place all four kinds → exit → walk the layout

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Arrange glyphs | `game/art/ui/glyph_arrange_rotate.png`, `glyph_arrange_place.png` | With pad pass | Match OS-6; no console trademarks |
| Reuse | `game/art/ui/glyph_*.png`, `focus_ring.png` | Prefer reuse | Accept / Cancel / Navigate from OS-6 |

### Acceptance

- [ ] Pad-only Arrange of building, furniture, light, path
- [ ] Pad-only exit to Inhabit and walk
- [ ] Focus always visible
- [ ] Summer pad smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## Pack-level definition of done

This pack is **Playable** when:

1. CC-8 Confirm lands on the real Sanctum (floating dusk-void rock + portal), not Millbrook, not hub stub as home.
2. **Inhabit:** third-person walk, portal interact feedback, soft fall return, empty of people and pre-placed houses.
3. **Arrange:** dedicated toggle flips to top-down; pan/zoom; place starter building, furniture, light, and path paint; move/remove; one-instance buildings; multiple furniture/lights.
4. Exit Arrange restores Inhabit; the player walks the layout they made; lights emit.
5. Starter kit unlocked on New Game; layout persists (SH-11).
6. Gamepad path works for Inhabit and Arrange (SH-2 + SH-12).
7. Geometry is parkour-legal (SH-4) even if climb/wall-run are still pack 04.
8. Art under `game/art/hub/` (chrome `ui/`, motes `vfx/`), lock + `style: "anime"`.
9. `.\scripts\test.ps1` prints `TEST_RESULT: PASS`.
10. Implementation followed Summer workflow above.

**Not required for this pack:** climb/wall-run moves (pack 04), portal world modes (pack 05), farm grow loop / Sanctum XP / residents (later cozy-sim pack), world-unlocked design library (§8 catalog pump), interiors, terrain sculpt, material spend, portal relocate, undo stack, Sanctum time of day.

---

## Implementation notes for agents

- **Replace the stub, keep the character.** Swap `res://game/hub/hub_stub.tscn` out of the intended path; do not rewrite CC-8 appearance.
- **Do not grow Millbrook as home.** Isolate Living Town. New hub schema ≠ `living_town_v1.json`.
- **One placement system.** SH-7…9 are catalogs on SH-6, not three editors.
- **Ground paint is not a mesh instance.** Do not fake paths as stretched cubes if a splat/decal exists; cubes as a graybox hour are OK if listed as stand-ins in the PR.
- **Authoritative layout is engine state.** No LLM writes instances.
- **Reuse hub glb only after a lock read.** `game/art/hub/` from the village pump may be stand-ins; destination is dusk-void Sanctum, not a ground town.
- **Deferments:** file new ones under [`../backlog/deferred/`](../backlog/deferred/). Before implementing any SH epic, review Open `DEF-*` and rope matches (especially [`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md) with SH-11, [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md) skipped unless Controls settings is in the same PR).
- When pack 04 starts, climb the rims this pack already left legal. When pack 05 starts, the overlook arch is the interactable already here.
