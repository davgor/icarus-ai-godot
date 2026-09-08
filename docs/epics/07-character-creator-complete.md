# Epic pack 07 — Character creator complete

**Status:** Planned  
**Feature-list:** [`feature-list.md`](../feature-list.md) §2 Later — creator complete (2.20–2.32)  
**Design:** [`game-design.md`](../game-design.md) Character creation (destination depth) + Gear and appearance (outfit ≠ loadout)  
**Tech contract:** [`../13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) — destination engine, schema v2, named regions/face/makeup/decals, hot vs cold apply  
**Art:** [`art-style.md`](../art-style.md), [`art/prompt-lock.md`](../art/prompt-lock.md) — Character / creator / portrait suffix  
**Catalog loop:** [`../12-CONTENT-CATALOG.md`](../12-CONTENT-CATALOG.md) — appearance rows are approved data, not hardcoded id lists  
**Import roots:** `game/art/characters/` (bodies, parts, outfits), `game/art/ui/` (new category chrome), `content/catalog/appearance/` (defs)  
**Operating loop:** [`agent-operating-loop.md`](../agent-operating-loop.md) + [`.summer/AGENTS.md`](../../.summer/AGENTS.md)  
**Depends on:** Pack 02 **Playable** (atelier, schema v1, shared applier, Confirm → hub stub). Does **not** require pack 03 Sanctum art.

Pack 02 is the **vertical slice** (New → customize → confirm → spawn). This pack is the **Code Vein-class destination**: a real assembly pipeline, a data catalog, and the morph/part depth the slice deferred into footnotes.

Suggested ship order: **CX-1 → CX-2 → CX-3 / CX-4 (parallel after maps) → CX-5 / CX-6 / CX-7 (parallel) → CX-9 → CX-10**.  
CX-10 performance hooks may land with CX-1 (hot vs cold) and finish after catalogs exist. **Outfit work is pack 08**, not CX-8.

**Do not skip the empty Sanctum to only polish creator.** This pack may run **in parallel** with packs 03–05 after pack 02 is Playable. Do not invent a second appearance JSON or a C# engine. Do not treat an outside customization spec as the contract — translate it through [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) [Outside engine drafts](../13-CHARACTER-APPEARANCE.md#outside-engine-drafts).

Roped-in deepen tickets: [`DEF-014`](../backlog/deferred/DEF-014-body-proportion-deepen.md) → CX-3, [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md) → CX-4 / CX-5, [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md) → CX-7, [`DEF-007`](../backlog/deferred/DEF-007-creator-draft-save.md) → CX-9. Outfit wardrobe [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md) → [`08-outfit-engine.md`](08-outfit-engine.md). Creator-no-outfit: [`DEF-021`](../backlog/deferred/DEF-021-creator-no-outfit.md).

---

## Shared locks (all CX epics)

- Pack 02 locks still hold: unlocked cosmetics, race = preset + tag, outfit ≠ loadout, Male / Female kits, demi optional, pad-first, Full/Dawn/Dusk, Reset/Randomize, appearance authority, no Summer SDK in shipped code. **Creator has no Outfit category** (`outfit.id` stays `none` until pack 08).
- **Semantic save.** `CharacterRecord` stores player-facing ids and 0–1 sliders. Bone names, blendshape names, and texture slots live in catalog **apply maps**.
- **One applier.** `AppearanceApplier.apply(record, root)` remains the only apply entry for preview, player, companion, and NPC. Stages are internals, not a second API for UI.
- **Hot vs cold.** Slider drag must not load meshes or recreate render targets. Part swaps are cold. See the contract.
- **Catalog approval.** New appearance rows follow [`12-CONTENT-CATALOG.md`](../12-CONTENT-CATALOG.md): pending → agent `ready_for_review` (mesh required) → **you** approve. Runtime samples `approved` only.
- Schema **v1 still loads**. Confirm after CX-2 writes **v2**. Illegal ids rejected before apply and before Confirm.
- Image `style` is **`"anime"`**. Prepend prompt-lock; `options.negative_prompt` from the lock. Never Kenney / `game/art/town/` as style.
- Headless tests: `tests/run_tests.gd`, gate on `TEST_RESULT: PASS`.
- Canonical commands: `.\scripts\test.ps1` → Summer play/diagnostics when scene work lands → `.\scripts\build.ps1` / `.\scripts\play.ps1` when the slice should be playable.

---

## Summer workflow

Same cycle as pack 02. Creator scene stays the dedicated atelier (`res://game/creator/character_creator.tscn` or successor). Main flow still roots at `res://game/main.tscn`.

After any assembler or catalog change: play Title → New → drag a hot slider → swap a cold part → Confirm → hub stub spawn; `summer_get_diagnostics`. Screenshot lighting is still not truth unless `target: "game"`.

---

## CX-1 — Catalog spine and assembly pipeline

### Outcome

Appearance is **data-driven** and **staged**. The preview no longer “scale the whole kit and tint albedo” as the architecture. Semantic fields map to bones, blendshapes, sockets, and materials through catalog rows. Hot slider updates stay hitch-free.

### Maps to

| ID | Feature |
| --- | --- |
| 2.20 | Appearance assembler |
| 2.21 | Appearance catalog as data |
| 2.18 | Appearance authority (spine for volume) |

### In scope

- `content/catalog/appearance/` layout + loader (approved only)
- Apply maps: height, weight, v1 proportions, muscle_fat, v1 face morphs (fine keys may stub to the same channel until CX-3/CX-4)
- Staged `AppearanceApplier`: kit → bones (with child locks) → blendshapes → slots → occlusion stub → cached material instances → jiggle
- Hot path: morph/bone/color only; cold path: kit and slot swaps
- Shared Male/Female **socket layout** documented (head, ears, horns, tail, hair, outfit bind)
- Tests: illegal catalog id rejected; hot apply does not call `load()`; v1 record still applies; spawn uses the same function

### Out of scope

- Schema v2 fields (CX-2)
- Fine body/face keys (CX-3, CX-4)
- Decal RT compositor (CX-6)
- Outfit piece occlusion content (CX-8) — **rule schema** may land here empty
- GPU mesh combine / rebake-as-architecture (rejected; profiler-only later)
- Multiplayer replication budgets (not this game)

### Dependencies

- Pack 02 applier, `appearance_catalog.gd`, atelier preview
- [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) destination engine

### Work

- Replace hardcoded `PackedStringArray` catalogs with JSON/Resource rows (keep a shim so existing ids resolve)
- Bone constraint graph on the underwear kits (stop uniform Node3D scale as the height implementation)
- Cache `ShaderMaterial` / `StandardMaterial3D` instances on the preview root
- Headless tests for stage order, reject, hot-path guard
- **Summer:** apply a v1 record; drag height; swap hair; diagnostics; screenshot silhouette vs slice

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Socket / bone layout sheet | `game/art/characters/_ref_socket_layout.png` | Start of CX-1 | Male and Female underwear kits, same camera; markers for hair/ears/horns/tail; no UI |
| *(meshes)* | — | — | No new hero meshes required — reuse CC-10 bases. Call out “no new art — reuse body kits” if none generated |

### Acceptance

- [ ] Catalog loader ignores non-`approved` rows
- [ ] Height uses skeleton scales + child locks, not only root Node3D scale
- [ ] Hot slider path does not load meshes
- [ ] Preview and hub stub spawn still share `AppearanceApplier.apply`
- [ ] v1 records apply without rewrite
- [ ] Summer play + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CX-2 — Schema v2, migration, validation

### Outcome

Saves and in-progress drafts speak **schema v2**. Old v1 files migrate. Generators and Confirm cannot emit illegal ids. Fine keys exist in the record even before every slider is wired.

### Maps to

| ID | Feature |
| --- | --- |
| 2.22 | Schema v2 + migration |

### In scope

- `schema_version: 2` write path
- Migrate v1 → v2 (proportion fan-out, face group → fine keys, scars/markings → `decals[]` aliases, makeup none, outfit colors defaults, `skin_undertone` 0.5)
- Validate against appearance catalog (unknown id = error)
- Round-trip: migrate → apply → serialize stable
- Tooling: debug apply of any valid v1 or v2 record to preview

### Out of scope

- Wiring every new slider in UI (CX-3+)
- Rewriting Living Town JSON
- Load-from-title polish ([`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md) — pack 01/persistence; not this pack)

### Dependencies

- CX-1 catalog loader
- Pack 02 `character_record.gd` / `character_store.gd`

### Work

- Versioned record module; migration tests for each v1 field
- Confirm writes v2; Back still does not write a character (draft is CX-9)
- **Summer:** Confirm a slice character, quit, load record, apply in creator

### Asset generation

| Asset | Dest | Generate when | Notes |
| --- | --- | --- | --- |
| *(none)* | — | — | No new art — schema only |

### Acceptance

- [ ] v1 fixture migrates; all v2 required keys present
- [ ] Unknown hair/outfit/feature id fails validation
- [ ] Confirm persists `schema_version == 2`
- [ ] Apply(migrated) matches apply(hand-authored v2) for slice-equivalent looks
- [ ] `TEST_RESULT: PASS`

---

## CX-3 — Body regions (Code Vein-class)

### Outcome

Body category exposes the **full named proportion set** (head through feet, including bust as a proportion). Silhouette updates live. Weight / height / muscle↔fat stay distinct.

**Ropes in:** [`DEF-014`](../backlog/deferred/DEF-014-body-proportion-deepen.md).

### Maps to

| ID | Feature |
| --- | --- |
| 2.6 | Proportions (destination) |
| 2.23 | Body region complete |

### In scope

- All 14 proportion ids from the contract, wired to bone maps
- Optional group sliders (`torso`, `arms`, `legs`) that write the group; independent overrides stick
- `bust` is a morph/bone proportion — **not** a jiggle toggle
- Capsule / camera pivot still sane at extremes (clamped)
- Pad-reachable sliders; Reset/Randomize category includes new keys
- Race presets set destination defaults (not locks)

### Out of scope

- Parkour animation retarget at extremes — Deferred: [`DEF-009`](../backlog/deferred/DEF-009-extreme-morph-anim-retarget.md)
- Soft-body driver changes (CC-4 already owns muscle↔fat jiggle)
- Extra body kits beyond Male / Female

### Dependencies

- CX-1 bone maps; CX-2 record keys
- CC-10 underwear kits (improve topology/weights if maps cannot bind)

### Work

- Body panel layout (group + fine); live preview
- Tests: each key changes a measurable bone or blendshape; weight still not in jiggle metric
- **Summer:** drag each region to ends; screenshot sheet vs `body_silhouette_sheet.png`

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Region silhouette sheet | `game/art/characters/body_region_sheet.png` | Start of CX-3 | Same character, grid of region extremes (shoulders, waist, hips, thighs, …); anime; no UI |
| Region gizmo icons | `game/art/ui/creator_region_*.png` | With panel | Minimal mystical glyphs; HUD scale |

Prefer retargeting CC-10 kits over new bodies.

### Acceptance

- [ ] All 14 keys adjustable, serialized, unlocked
- [ ] Group slider then override works
- [ ] Height / weight / muscle↔fat still distinct in UI copy and apply
- [ ] Summer diagnostics clean after region smoke
- [ ] `TEST_RESULT: PASS`

---

## CX-4 — Face morph complete

### Outcome

Face category is a **named** anime face workshop: shape preset plus every fine morph in the contract (brows through human ears). Close-up framing is usable while dragging.

**Ropes in:** morph half of [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md).

### Maps to

| ID | Feature |
| --- | --- |
| 2.9 | Face (destination morphs) |
| 2.24 | Face morph complete |

### In scope

- All fine face keys wired to blendshapes (catalog maps)
- ≥3 `face.shape_id` bases (not one topology pretending to be a catalog)
- v1 group keys migrate; UI shows fine keys (group aliases optional)
- Head-only camera helper (CX-9 owns the full pose list; a face frame may land here)
- Race presets may bias defaults

### Out of scope

- Makeup and hair volume (CX-5)
- Decal compositor (CX-6)
- Gameplay dialogue visemes / cinematic faces — Deferred: [`DEF-019`](../backlog/deferred/DEF-019-gameplay-face-anim.md)

### Dependencies

- CX-1 morph bus; CX-2 keys; CC-5 starter morphs

### Work

- Face panel; morph bus writes every key
- Tests: each key serializes; unknown extra key ignored by applier
- **Summer:** generate face sheet → play extremes; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Fine-morph face sheet | `game/art/characters/face_fine_sheet.png` | Start of CX-4 | Same head, labeled extremes (brow_inner, eye_spacing, nose_tip, …); anime; creator quality |
| Extra face shape concepts | `game/art/characters/face_shape_*.png` | With morphs | Distinct face bases; identical lighting; no UI |

### Acceptance

- [ ] Every listed fine key is adjustable and stored
- [ ] ≥3 face shape ids in catalog, unlocked
- [ ] Live preview; pad-usable
- [ ] Summer play + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CX-5 — Hair, eyes, makeup

### Outcome

Hair and eyes are a **real kit**, not three icons. Makeup is first-class (eyeshadow, liner, lipstick, blush), all unlocked, none-able.

**Ropes in:** catalog + makeup half of [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md).

### Maps to

| ID | Feature |
| --- | --- |
| 2.9 | Hair / eyes (volume) |
| 2.25 | Makeup |
| 2.26 | Hair highlight + heterochromia |

### In scope

- Catalog minimums: ≥12 hair, ≥8 eyes (contract table)
- Hair color + optional highlight
- Eye color + optional `eye_color_r` (heterochromia)
- Makeup four channels + colors + none
- Hair category tab (or Face sub-rail) pad-reachable
- Reset/Randomize include hair/makeup

### Out of scope

- Hair strand physics / wind — Deferred: [`DEF-020`](../backlog/deferred/DEF-020-hair-cloth-secondary-motion.md)
- Nail art, full body paint farms
- Gating any option behind play

### Dependencies

- CX-1 slots/materials; CX-2 makeup fields; CC-5 starter hair/eyes

### Work

- Data-driven grids; material params for highlight / heterochromia
- Tests: none makeup clears; illegal makeup id rejected; highlight null vs set
- **Summer:** generate sheets → import → play grids; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Hair concepts (per style) | `game/art/characters/hair_{id}.png` | Start of CX-5 | Isolated hair, dark jewel void, clear silhouette; same camera height across the set |
| Hair meshes | `game/art/characters/hair_{id}.glb` | After `Read` | image-to-3d; `assetIntent: "character"`; clean scalp pivot |
| Eye style sheet | `game/art/characters/eyes_kit_sheet.png` | With hair | ≥8 iris styles; consistent lighting |
| Makeup stamp sheet | `game/art/characters/makeup_sheet.png` | With hair | Eyeshadow / liner / lip / blush variants; anime; not photoreal |

### Acceptance

- [ ] Hair/eyes/makeup minimums met; all unlocked
- [ ] Highlight and heterochromia optional
- [ ] None makeup is valid Confirm
- [ ] Assets under `game/art/characters/` + approved catalog rows
- [ ] Summer play + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CX-6 — Skin materials and decal compositor

### Outcome

Skin reads as a **material** (color + undertone), not a flat albedo hack. Scars, markings, and tattoos are **layers** the player can place on body regions with coarse UV controls — still pad-usable, not a photo editor.

### Maps to

| ID | Feature |
| --- | --- |
| 2.15 | Skin (undertone) |
| 2.16 | Scars / markings (destination) |
| 2.27 | Decal compositor / tattoos |

### In scope

- Skin master material + undertone
- Decal composite pass (dirty-flagged; hot sliders do not rebake)
- Regions enum from the contract
- Catalog minimums: ≥8 scars, ≥8 markings/tattoos
- Slice `scar_id` / `marking_id` still apply via migrated layers
- Blend modes: alpha, multiply, additive
- Marks category in the rail

### Out of scope

- Freehand painting / layers-as-photoshop
- Sharing look codes online
- Cape / cloth (gear / [`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md))

### Dependencies

- CX-1 material cache + dirty flags; CX-2 `decals[]`

### Work

- Offscreen composite size from catalog (1K default)
- UI: stamp grid, region, coarse offset/scale/rotation, tint
- Tests: height drag does not mark decals dirty; adding a layer does; order respected
- **Summer:** stamp a torso tattoo, orbit, lighting cycle; diagnostics (watch RT spam)

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Skin undertone strip | `game/art/characters/skin_undertone.png` | Start of CX-6 | Same face, cool→warm; anime; no pores |
| Scar / tattoo stamps | `game/art/characters/decal_{id}.png` | With compositor | Transparent stamps; readable at body UV; not horror gore; dark-jewel compatible |

### Acceptance

- [ ] Undertone visible; skin on body and head match
- [ ] Decal layers persist in v2; compositor updates only when dirty
- [ ] Pad can place and nudge a stamp
- [ ] Summer play + diagnostics clean (no error spam)
- [ ] `TEST_RESULT: PASS`

---

## CX-7 — Demi-human catalog complete

### Outcome

Ears, horns, and tails are a **kit** (including several lizard/dragon options). Combinations stay optional. Sockets scale with the head/hips. Conflicts are data, not surprise clipping.

**Ropes in:** [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md).

### Maps to

| ID | Feature |
| --- | --- |
| 2.10 | Demi-human features (destination) |
| 2.28 | Demi catalog complete |

### In scope

- Minimums: ≥6 ears, ≥6 horns, ≥8 tails (mammal + lizard/dragon both represented)
- Occlusion: demi ears hide human ear morph / ear submesh
- Conflict rules in catalog (e.g. some horns hide hair slots)
- Demi race preset still clearable
- All unlocked; any combo or none

### Out of scope

- Wings, full-body scales, extra kits — Deferred: [`DEF-018`](../backlog/deferred/DEF-018-demi-wings-scales.md)
- Gameplay bonuses tied to parts
- A separate dragon race

### Dependencies

- CX-1 sockets/occlusion; CC-6 starter features

### Work

- Feature grids; socket bind tests on both sexes
- Tests: none/clear; lizard + horns; illegal id reject
- **Summer:** generate → 3D → socket; mix combos; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Feature concepts | `game/art/characters/feature_{ears,horns,tails}_*.png` | Start of CX-7 | Isolated on void or neutral kit; include multiple lizard/dragon tails and horns |
| Feature meshes | `game/art/characters/feature_*.glb` | After `Read` | image-to-3d; pivots match socket layout sheet |

### Acceptance

- [ ] Catalog minimums met; optional none
- [ ] Dragon-leaning combo still reads without a dragon race
- [ ] Conflict/occlusion rules documented and tested
- [ ] Summer combination smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CX-8 — Outfit (moved to pack 08)

### Outcome

**Moved.** Outfit fit, occlusion, wardrobe, and dress-up UI live in [`08-outfit-engine.md`](08-outfit-engine.md), not the character creator. Tickets: [`DEF-021`](../backlog/deferred/DEF-021-creator-no-outfit.md), [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md). Assembler **stages** for slots/occlusion may still land in CX-1 so pack 08 can apply clothes; do not re-add an Outfit tab to the atelier.

### Maps to

| ID | Feature |
| --- | --- |
| *(moved)* | Former 2.29 → pack 08 / feature-list 5.5 |

### Acceptance

- [x] Documented move to pack 08
- [x] Creator category rail excludes Outfit

---

## CX-9 — Atelier studio UX

### Outcome

The creator is a **studio**: framing, poses, compare, a short undo stack, and an explicit **draft save**. Still fully usable on a gamepad.

**Ropes in:** [`DEF-007`](../backlog/deferred/DEF-007-creator-draft-save.md).

### Maps to

| ID | Feature |
| --- | --- |
| 2.1 | Creator screen (studio) |
| 2.13 | Creator on controller (new chrome) |
| 2.17 | Reset / randomize (still present; undo is extra) |
| 2.30 | Framing, pose, compare, undo |
| 2.31 | Creator draft save |

### In scope

- Category rail: Race, Body, Face, Hair, Makeup, Marks, Features (**no Outfit** — pack 08)
- Cameras: full / bust / face; pad cycle
- Pose list: idle, turntable, ≥3 face expressions (preview-only)
- Compare: snapshot vs live (hold or toggle)
- Undo/redo ~20 edits (does not replace Reset)
- Draft save: named, cannot silently overwrite a confirmed character; Back without draft still discards
- Focus graph includes new chrome; lighting / reset / randomize remain reachable

### Out of scope

- Full Controls rebind — Deferred: [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md)
- Sanctum / world time of day
- Second save slot browser polish — [`DEF-004`](../backlog/deferred/DEF-004-load-browser-polish.md) / [`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md)

### Dependencies

- Categories from CX-3–CX-7; pack 02 shell and CC-9 pad scheme (Outfit is pack 08)

### Work

- InputMap for framing / pose / compare / undo
- Tests: draft vs confirm paths; undo restores last morph; Back without draft writes nothing
- **Summer:** pad-only studio smoke; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| New category tab chrome | `game/art/ui/creator_tab_*.png` | With rail | Hair / Makeup / Marks tabs matching existing creator_tab language |
| Pose / compare / undo glyphs | `game/art/ui/glyph_{pose,compare,undo}.png` | With pad pass | Match OS-6 mystical anime glyphs; no console trademarks |
| Expression pose refs (optional) | `game/art/characters/_ref_face_poses.png` | If needed for tuning | Neutral / smile / stern; not style-drift art |

### Acceptance

- [ ] Pad-only: change framing, pose, makeup, a decal, undo, save draft, back, resume draft, Confirm
- [ ] Draft does not overwrite a finished character
- [ ] Compare and undo work without mouse
- [ ] Summer pad smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CX-10 — Authority at volume

### Outcome

Anyone the game can show is still **creator-legal**, including when the catalog is large. Generators sample v2. Apply stays fast enough to use in hub and worlds. Tooling can load any valid record into the atelier.

### Maps to

| ID | Feature |
| --- | --- |
| 2.18 | Appearance authority |
| 2.32 | Generator sampling + apply performance |

### In scope

- Catalog sampler for NPC/companion/recruit records (legal ids only)
- Validation hooked where simulation commits appearance ([`04-SIMULATION.md`](../04-SIMULATION.md) direction)
- Hot/cold budgets from the contract proven with the grown catalog
- Round-trip tooling check: record → apply → serialize ≈ record
- Same applier on hub stub / future Sanctum / player
- Document remaining extreme-morph anim limits; do not silently invent a second body

### Out of scope

- World compiler shipping unique faces ([`02-WORLD-COMPILER.md`](../02-WORLD-COMPILER.md) already forbids this)
- Race-tag **story reactions** — Deferred: [`DEF-008`](../backlog/deferred/DEF-008-race-tag-story-reactions.md)
- Companion dress UI in Sanctum (companions pack; they still **use** this applier)

### Dependencies

- CX-1–CX-8 catalogs; pack 02 spawn path

### Work

- Sampler + tests (never emits unknown ids; respects none-able features)
- Perf tests or instrumentation: hot apply does not load; cold swap measured
- **Summer:** apply three generated records in creator; spawn one; diagnostics

### Asset generation

| Asset | Dest | Generate when | Notes |
| --- | --- | --- | --- |
| *(none required)* | — | — | No new hero art — reuse catalog. Optional: one NPC lineup still for QA (`game/art/characters/_ref_npc_lineup.png`) |

### Acceptance

- [ ] Sampler output always validates as v2
- [ ] Illegal record cannot be applied or spawned
- [ ] Hot slider still interactive with destination catalog loaded
- [ ] Tooling apply-to-preview works for v1 and v2
- [ ] Summer play + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## Pack-level definition of done

This pack is **Playable** (creator complete) when:

1. Assembler stages + approved appearance catalog are the only apply path (CX-1).
2. Confirm writes schema v2; v1 migrates (CX-2).
3. Destination morphs, makeup, decals, and demi kit meet the [minimums](../13-CHARACTER-APPEARANCE.md#destination-catalog-minimums-pack-07-dod) (outfit minimums are pack 08).
4. Studio UX (framing, pose, compare, undo, draft) works on pad (CX-9).
5. Generators can only sample creator-legal v2 records (CX-10); `outfit.id` may be `none`.
6. Outfit ≠ loadout still tested (`none` vs empty loadout; pack 08 writes real outfits).
7. Art under `game/art/characters/` and `game/art/ui/`; defs under `content/catalog/appearance/` with human approval.
8. `.\scripts\test.ps1` prints `TEST_RESULT: PASS`.
9. Implementation followed [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) destination engine (not an outside C# DTO).

**Not required for this pack:** Sanctum content (pack 03), parkour retarget ([`DEF-009`](../backlog/deferred/DEF-009-extreme-morph-anim-retarget.md)), combat gear, wings/scales ([`DEF-018`](../backlog/deferred/DEF-018-demi-wings-scales.md)), companion roster UI, **outfit wardrobe** ([`08-outfit-engine.md`](08-outfit-engine.md)).

---

## Implementation notes for agents

- Read [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) **destination** sections before writing assembler code. Do not paste C# interfaces into GDScript.
- Do not flatten the record into `boneScales` / `morphWeights` in the save.
- Do not add a third body sex to “match” an outside spec.
- Do not run `--import` while Summer is open.
- Before starting a CX epic: list Open `DEF-*` and rope matches (DEF-011–014 and DEF-007 are already assigned above).
- New deferrals file `DEF-NNN` under [`../backlog/deferred/`](../backlog/deferred/) with a Source link here.
