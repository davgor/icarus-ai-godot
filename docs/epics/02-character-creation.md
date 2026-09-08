# Epic pack 02 — Character creation

**Status:** Playable (vertical slice)  
**Feature-list:** [`feature-list.md`](../feature-list.md) §2 Character creation  
**Design:** [`game-design.md`](../game-design.md) Character creation + Gear and appearance (outfit ≠ loadout)  
**Art:** [`art-style.md`](../art-style.md), [`art/prompt-lock.md`](../art/prompt-lock.md) — Character / creator / portrait suffix  
**Tech contract (one-shot):** [`../13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) — hybrid morphs, schema v1, named face morphs, skin/scars, reset/randomize, lighting, apply→capsule  
**Import roots:** `game/art/characters/` (bodies, race kits, outfit cosmetics), `game/art/ui/` (creator chrome), `game/art/vfx/` (atelier light / transition only)  
**Operating loop:** [`agent-operating-loop.md`](../agent-operating-loop.md) + [`.summer/AGENTS.md`](../../.summer/AGENTS.md)

Code Vein-class depth is the **target**. This pack ships a **vertical slice** (playable New → customize → confirm → hub handoff). Destination assembler, schema v2, and catalog depth are **pack 07** — [`07-character-creator-complete.md`](07-character-creator-complete.md) — not more work hidden inside these CC ids.

Suggested ship order: **CC-1 → CC-2 → CC-10 → CC-3 → CC-5 / CC-6 (parallel after race) → CC-7 → CC-4 → CC-8 → CC-9**.  
**Vertical-slice cut** (minimum playable): CC-1 (lighting + reset/randomize chrome), CC-2, **CC-10 (Male / Female base kits — required)**, thin CC-3 (**incl. skin color**), thin CC-5 (**named morphs + scars/markings starter**), **CC-6 (required — not optional)**, thin CC-7, CC-8, CC-9. CC-4 can land immediately after the cut without waiting for pack 03.

**Do not invent morph tech mid-pack.** Follow [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md): bone scales for height/weight/proportions, blend shapes for face + muscle↔fat, bone-spring jiggle from muscle↔fat only, socketed demi parts, one `AppearanceApplier` for preview and gameplay.

---

## Shared locks (all CC epics)

- New always enters **full** creator before hub spawn. No intended-path skip. Debug skip may exist; it is not a title or creator button.
- All cosmetic options stay **unlocked**. Do not gate parts behind play, quests, or currency.
- Race is a **preset + story tag**, never a lock on morphs or outfit.
- **Outfit ≠ loadout.** Creator starting clothes are cosmetics only. Do not invent combat armor/weapons as the creator’s appearance layer.
- Controller is first-class (CC-9 completes the pad path). Keyboard/mouse stays supported in parallel. No mouse-cursor-emulation gamepad path.
- Visuals: lock v1, dark jewel atelier, bright sparse rims. Image `style` is **`"anime"`**. Prepend the prompt-lock prefix; pass `options.negative_prompt` from the lock. Prefer `game/art/_style/` refs when present. Never use Kenney / `game/art/town/` as style.
- Character concepts and meshes live under `game/art/characters/`. Creator chrome under `game/art/ui/`. Do not park finals in `_style/`.
- Authoritative appearance state lives in the **engine** (character record schema v1 in [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md)). LLM / generators only produce assets or untrusted suggestions — never own the live morph dict.
- Creator preview lighting: **Full / Dawn / Dusk** ([`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md)). Preview-only; default Full.
- **Reset** (all + category) and **Randomize** (all + category) are in the vertical slice.
- **CC-6 demi features are in the vertical-slice cut** — demi-human must not ship as tag-only.
- **CC-10 Male / Female is in the vertical-slice cut** — two underwear base kits; sex does not lock cosmetics.
- **Appearance authority:** every generated character is creator-legal; tooling exposes the creator for preview/apply of any valid record ([`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md)).
- Headless tests: `tests/run_tests.gd` (`extends SceneTree`), gate on `TEST_RESULT: PASS`.
- Canonical commands: `.\scripts\test.ps1` → Summer play/diagnostics when scene work lands → `.\scripts\build.ps1` / `.\scripts\play.ps1` when the slice should be playable.
- Do **not** add Summer SDK or editor-only APIs to shipped game code. Do **not** run `godot --import` while Summer is open on this repo.

---

## Summer workflow (required for this pack)

This pack is **Summer-first**. Scene layout, live preview lighting, asset generate/import checks, play smokes, and diagnostics all go through Summer MCP when it is connected. Edit GDScript in Cursor. Do not invent a parallel scene-edit or graybox-only path and call the epic done.

### Required cycle (after any scene or runtime-affecting change)

```text
summer_get_project_context
        ↓
summer_get_diagnostics          ← always before console/debugger
        ↓
summer_open_main_scene          ← if currentScene is null; then open creator scene
        ↓
summer_get_scene_tree(scenePath=<creator or flow scene>)
        ↓
mutate with that same scenePath (add_node / set_prop / …)
        ↓
edit GDScript in Cursor (morph logic, save write, input)
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

Main flow still roots at `res://game/main.tscn`. Creator should be a **dedicated scene** (or clearly owned subtree) opened from the New route — not a rename of Millbrook `HUD/Create`.

Mutation rules (copy from the operating loop):

```text
❌ position: { "x": 2, "y": 1, "z": 0 }
✅ position: "Vector3(2, 1, 0)"
❌ parent: "Creator/Preview"
✅ parent: "./" or path: "./Preview"
```

### Summer generate / import (characters + chrome)

| Job | Tool | Hard rules |
| --- | --- | --- |
| Concept stills, race cards, hair/eye sheets, outfit flats, UI chrome | `summer_generate_image` | `style: "anime"` only; prepend lock; negative from lock; `Read` `localPath` before import |
| Base body / race kit / outfit meshes | `summer_generate_3d` | Prefer **image-to-3d** from a style-locked concept; `assetIntent: "character"` for bodies; game-ready / PBR language in prompt |
| Live look checks | `summer_screenshot` | Prefer `target: "game"` while playing; `target: "scene"` is synthetic — not lighting truth |
| Hierarchy / props | `summer_get_scene_tree`, add/set tools | Always pass explicit `scenePath` |

**Pipeline per asset:** read art docs → prepend lock → generate → `Read` preview → compare to bible → import under the correct `game/art/...` folder → wire in the creator scene via Summer → play → diagnostics.

**Call-forward from OS-5:** discard or demote `creator_stub_bg` once the real atelier exists; do not keep the stub as the intended New destination — Deferred: [`DEF-006`](../backlog/deferred/DEF-006-creator-stub-art-retirement.md).

### Summer play acceptance (pack-level)

Pad- or KBM-driven smoke when the vertical slice lands:

1. Title → **New** → creator atelier (not Millbrook name overlay, not hub).
2. Pick each race once; confirm preset snap + free override.
3. Pick **Male** and **Female** once; preview swaps the underwear base; morphs/outfit stay overrideable.
4. Move height / weight / muscle–fat / skin; preview updates live (weight ≠ fatness).
5. Cycle preview lighting **Full / Dawn / Dusk**; shading visibly changes.
6. Change named face morphs, hair/eyes, scars/markings; optionally ears, horns, tails (**CC-6 in slice**).
7. Use **Reset** and **Randomize** at least once (all or category).
8. Change starting outfit; confirm loadout slots are **not** required.
9. Orbit / frame the preview on pad (CC-9) or mouse.
10. Confirm → character written (schema v1) → hub handoff scene (empty hub when pack 03 exists; **hub stub** allowed until then).
11. Back / cancel from creator returns to title without writing a character (optional draft save: pack 07 [CX-9](07-character-creator-complete.md#cx-9--atelier-studio-ux) — [`DEF-007`](../backlog/deferred/DEF-007-creator-draft-save.md)).

After each smoke: `summer_get_diagnostics`. Fix before declaring the epic playable.

---

## CC-1 — Creator atelier shell

### Outcome

New opens a dedicated **character atelier**: lit preview stage, **Full / Dawn / Dusk** lighting presets, orbit camera, category chrome, and a live mannequin/preview rig. It is obviously creator, not title and not town.

### Maps to

| ID | Feature |
| --- | --- |
| 2.1 | Creator screen |
| 2.14 | Preview lighting |
| 2.17 | Reset / randomize |

### In scope

- Dedicated creator scene (or owned flow state) replacing the OS-5 stub body
- Preview stage: generated 3D hall (from the atelier still), atelier lighting, orbit camera inside the set
- **Lighting presets:** Full / Dawn / Dusk (cycle or three options); preview-only; default **Full** — [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md)
- **Reset all / Reset category** and **Randomize all / Randomize category** chrome (wire to real behavior as categories land; must work by vertical-slice DOD)
- Orbit / zoom framing around the preview character
- Category rail or tabs (Race, Body, Face, Features, Outfit) — empty panels OK until later CC epics fill them
- Name field (reuse / replace Millbrook name entry; name is not the whole creator)
- Back to title without spawning
- Summer-built control tree and lighting; GDScript owns state hooks

### Out of scope

- Full morph math (CC-3+)
- Confirm → hub write (CC-8)
- Final combat loadout UI
- Changing Sanctum / world time of day
- Undo stack

### Dependencies

- Pack 01 OS-5 New → creator route (or land route + shell together)
- Style lock + appearance contract

### Work

- Scene: e.g. `res://game/ui/character_creator.tscn` (name may vary; keep under `game/`, not Millbrook HUD)
- Flow owner: Title New → Creator; Back → Title
- Three named light/env presets; UI control to switch; screenshots prove shading change
- Reset / Randomize buttons (or menu) with focusables; hook to race preset + random helpers as CC-2+ land
- Preview rig placeholder (capsule → real mesh as CC-2/CC-3 art lands)
- Input actions for camera orbit (mouse + placeholders for pad)
- Tests: New reaches creator scene; Back returns to title; lighting preset changes; reset/randomize actions exist; no SCRIPT ERROR
- **Summer:** open creator `scenePath`, build Preview / Lights / UI with MCP mutations, `summer_play`, screenshot **each** lighting preset, diagnostics

### Asset generation

Generate **atelier + chrome before** locking final panel sizes.

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Atelier environment concept | `game/art/characters/creator_atelier_concept.png` | Start of CC-1 | Character atelier / mirror room; dark jewel; soft shafts; empty stage for a hero; **no** baked-in UI panels or readable sliders in the image |
| Atelier backdrop / HDRI-style still | `game/art/characters/creator_atelier_bg.png` | With concept | Source still for the hall look; kept as art, not the live stage |
| Atelier 3D hall | `game/art/characters/creator_atelier_chamber.glb` | After concept | Open-front gothic chamber from the still; live creator stage |
| Lighting preset icons (×3) | `game/art/ui/creator_light_{full,dawn,dusk}.png` | With shell | Small mystical anime glyphs for Full / Dawn / Dusk; readable at HUD scale |
| Reset / Randomize icons | `game/art/ui/creator_{reset,random}.png` | With shell | Compact mystical anime UI glyphs; no text baked in |
| Category tab chrome | `game/art/ui/creator_tab.png` (+ `_active`) | With shell | Dark panel, sparse bright rim; readable at HUD scale |
| Slider track / fill / thumb | `game/art/ui/creator_slider_*.png` | With shell | Compact mystical anime slider kit; not Material flat |
| Confirm / Back buttons | Reuse pack 01 primary chrome or `game/art/ui/creator_btn.png` | With shell | Match title language; creator-scale padding |
| Optional mote / dust sheet | `game/art/vfx/creator_motes.png` | Polish | Sparse gold/cyan motes; atelier atmosphere only |

**3D (Summer):** `creator_atelier_chamber.glb` is the live stage — open-front gothic hall derived from the concept still (`assetIntent: "object"` / image-to-3d). Extra failed gens (`creator_atelier_room.glb`, `creator_atelier_set.glb`) are not wired. Preview **body** waits for CC-2 concepts unless a neutral mannequin is generated here as temporary.

### Acceptance

- [x] New → atelier creator (not Millbrook create-as-title, not hub)
- [x] Back → title without character write
- [x] Preview stage lit; camera orbits
- [x] Full / Dawn / Dusk presets change visible shading; default Full
- [x] Reset / Randomize controls present (behavior complete by pack DOD)
- [x] Category chrome visible (panels may be stubs)
- [x] Art under `game/art/characters/` and `game/art/ui/`
- [x] Summer: scene mutated via explicit `scenePath`; play + diagnostics clean
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. Roped in [`DEF-006`](../backlog/deferred/DEF-006-creator-stub-art-retirement.md) (stub body retired; atelier is the New destination). 3D hall polish: no matching Open DEF (skipped draft save [`DEF-007`](../backlog/deferred/DEF-007-creator-draft-save.md), rebind [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md)). Confirm → hub remains CC-8.

---

## CC-2 — Race select, preset, and tag

### Outcome

Player picks **Human / Elf / Dwarf / Gnome / Halfling / Demi-human**. Selection applies a visible preset and stores a **race tag**. Every morph remains overrideable afterward.

### Maps to

| ID | Feature |
| --- | --- |
| 2.2 | Race select |
| 2.3 | Race as preset |
| 2.4 | Race as tag |

### In scope

- Six race choices in the Race category
- Preset application: proportions, typical features, starting silhouette
- Tag written into the in-progress character record (`race` or equivalent)
- Re-selecting race re-applies preset (with a clear confirm if the player has dirty overrides — simple reapply OK for v0 if documented)
- Overrides after preset never blocked by race

### Out of scope

- Story dialogue reactions (later systems consume the tag) — Deferred: [`DEF-008`](../backlog/deferred/DEF-008-race-tag-story-reactions.md)
- Locking options per race
- Demi-human ear/horn/tail catalog deepen (wings/scales: [`DEF-018`](../backlog/deferred/DEF-018-demi-wings-scales.md)) — pack 07 [CX-7](07-character-creator-complete.md#cx-7--demi-human-catalog-complete); ticket [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md); CC-6 owns ears+horns+tails (incl. lizard) optional minimum; demi-human race may enable the Features tab early

### Dependencies

- CC-1 shell + preview rig

### Work

- Race enum / constants shared with save schema draft
- Preset data (Resource or dict) per race → applied to morph state
- UI: race cards or list with focusables
- Tests: each race sets tag; preset changes at least one measurable morph; override after preset sticks
- **Summer:** generate race concepts → optional image-to-3d kits → drop into Preview; play and flip races while watching diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Race card stills (×6) | `game/art/characters/race_{human,elf,dwarf,gnome,halfling,demi}.png` | Start of CC-2 | Bust or full-body portrait per race; Icarus creator quality; identical framing across the set; no UI chrome baked in |
| Neutral / race base body concepts | `game/art/characters/body_base_*.png` | With cards | Full-body turnaround-friendly; A/T pose or creator idle; anime proportions per race preset |
| Base body meshes | `game/art/characters/body_*.glb` (or Godot-friendly import) | After concepts pass `Read` | `summer_generate_3d` image-to-3d; `assetIntent: "character"`; clean topology, PBR, no studio base |

**Set discipline:** same camera height and lighting language across race cards so the UI grid reads as one kit.

### Acceptance

- [x] All six races selectable
- [x] Preset visibly updates preview
- [x] Tag stored on character-in-progress
- [x] Player can override preset fields
- [x] Race art/meshes under `game/art/characters/`
- [x] Summer play flip through races + diagnostics clean
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — story reactions stay [`DEF-008`](../backlog/deferred/DEF-008-race-tag-story-reactions.md); demi catalog deepen stays [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md). Re-selecting race reapplies the preset with no dirty-confirm (v0).

---

## CC-10 — Male / Female base kits

### Outcome

Player picks **Male** or **Female**. The preview swaps to that sex’s **underwear base** (not a clothed hero). Race, morphs, hair, features, and starting outfit stay overrideable on both kits. Sex is not a race and not a cosmetics lock.

### Maps to

| ID | Feature |
| --- | --- |
| 2.19 | Male / female body |

### In scope

- First-class Male / Female control (Body panel first row, or a Type toggle next to Race — pick one; pad-reachable)
- Schema v1 field `body.sex`: `male` | `female` ([`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md))
- Two underwear base meshes with the same socket layout (head / ears / horns / tail) so CC-5–CC-7 share one applier
- Switching sex swaps the base kit live; current morphs and outfit ids remain unless a part is illegal (then snap to a legal default)
- Race presets may bias defaults (e.g. height) but do **not** force sex
- Reset category / Reset all re-apply the **current** sex’s defaults, not a forced Male
- Underwear only on the base — CC-7 outfits layer on top; do not bake traveler armor into the body kit

### Out of scope

- Extra body types beyond Male / Female
- Locking hair, outfit, or features by sex
- Voice / TTS by sex (later systems)
- Full nude or adult-only body variants — simple underwear is the base

### Dependencies

- CC-1 preview rig + CC-2 race tag
- [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md)
- Land **before** CC-3 sliders and CC-7 outfits so both kits receive morphs and clothes

### Work

- Catalog ids → `body_base_male` / `body_base_female` (or equivalent) underwear GLBs
- `AppearanceApplier` swaps the kit from `body.sex`
- UI: two focusable choices; selected state visible
- Tests: both sexes set `body.sex`; preview mesh id changes; override morph after swap sticks; outfit id not cleared by sex change
- **Summer:** generate Male and Female underwear concepts (A/T pose, identical framing) → image-to-3d → drop on Preview; play both sexes; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Male underwear base concept | `game/art/characters/body_base_male.png` | Start of CC-10 | Full-body A/T pose; adult male; simple underwear only; no armor, no traveler kit, no weapons; dark jewel void; creator idle |
| Female underwear base concept | `game/art/characters/body_base_female.png` | With male | Same camera, lighting, and pose as the male still; adult female; simple underwear only; no armor |
| Male / Female base meshes | `game/art/characters/body_base_{male,female}.glb` | After concepts pass `Read` | `summer_generate_3d` image-to-3d; `assetIntent: "character"`; clean topology; shared socket language; PBR; no studio base |

**Set discipline:** same camera height and lighting across the two body stills. Replace any clothed CC-2 placeholder body as the live preview kit.

### Acceptance

- [x] Male and Female both selectable
- [x] Preview swaps to the matching underwear base
- [x] `body.sex` serializes on the in-progress character
- [x] Sex does not lock race, morphs, features, or outfit
- [x] Assets under `game/art/characters/`
- [x] Summer play both sexes + diagnostics clean
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — draft save stays [`DEF-007`](../backlog/deferred/DEF-007-creator-draft-save.md); story reactions stay [`DEF-008`](../backlog/deferred/DEF-008-race-tag-story-reactions.md); morph deepen stays [`DEF-014`](../backlog/deferred/DEF-014-body-proportion-deepen.md).

---

## CC-3 — Body core (height, weight, proportions, muscle ↔ fat)

### Outcome

Body category exposes **height**, **weight**, a **muscle ↔ fat** bar, and a first vertical slice of **region proportions**. Preview silhouette updates live.

### Maps to

| ID | Feature |
| --- | --- |
| 2.5 | Height and weight |
| 2.6 | Proportions (vertical slice; deepen over time) |
| 2.7 | Muscle ↔ fat bar |
| 2.15 | Skin color |

### In scope

- First-class height and weight sliders — **weight = frame mass**, not fatness ([`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md))
- Muscle ↔ fat as one bar (**composition** + jiggle driver only)
- **Skin color** swatches (≥6) applied live to body/head materials
- Proportion regions for the slice: at least head, torso, arms, legs (destination regions: pack 07 [CX-3](07-character-creator-complete.md#cx-3--body-regions-code-vein-class); ticket [`DEF-014`](../backlog/deferred/DEF-014-body-proportion-deepen.md))
- Live preview via **hybrid morphs** locked in the appearance contract: **bone scales** for height/weight/proportions; **blend shapes** for muscle↔fat surface (and face in CC-5)
- Capsule / collision scale hooks from body (same applier path gameplay will use; full move kit is pack 04)
- Character-in-progress uses **schema v1** body fields (incl. `skin_color`)

### Out of scope

- Soft-body motion (CC-4)
- Face part catalog (CC-5)
- Wiring weight into jiggle (forbidden)
- Inventing a second morph system (forbidden — use the contract)
- Final animation retarget for every extreme morph (best-effort clip; document known limits) — Deferred: [`DEF-009`](../backlog/deferred/DEF-009-extreme-morph-anim-retarget.md)

### Dependencies

- CC-1; CC-2 presets should feed default body values + default skin
- CC-10 Male / Female underwear bases live on the preview
- [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md)

### Work

- Implement shared `AppearanceApplier` (or equivalent) reading schema v1 `body`
- Slider UI wired to morph bus → preview; skin swatch row
- Clamp ranges; race preset sets defaults inside clamps
- Tests: slider extremes change serialized morphs; muscle–fat midpoint vs ends differ; weight change does not change jiggle metric; skin_color applies
- **Summer:** build slider rows + skin swatches in the Body panel; play and drag extremes; `summer_screenshot` silhouette + skin checks

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Body silhouette reference sheet | `game/art/characters/body_silhouette_sheet.png` | Start of CC-3 | Same character at short/tall and muscle/fat extremes; creator-quality; grid sheet; no UI |
| Skin tone swatch reference | `game/art/characters/skin_swatches.png` | With body | ≥6 anime-friendly skin tones; flat swatches or bust strip; consistent lighting |
| Region gizmo icons (optional) | `game/art/ui/creator_region_*.png` | If UI needs icons | Minimal anime UI glyphs for head/torso/limbs |

Most “art” here is the live mesh responding to morphs — prefer improving the CC-2 body kit over spawning unrelated bodies.

### Acceptance

- [x] Height, weight, muscle↔fat, skin (≥6 swatches), and ≥4 proportion regions work
- [x] Weight thickens frame; muscle↔fat changes composition/jiggle path — not confused in UI copy
- [x] Preview updates without restarting the scene
- [x] Values serialize on the in-progress character (`skin_color` present)
- [x] Summer diagnostics clean after slider smoke
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — proportion deepen stays [`DEF-014`](../backlog/deferred/DEF-014-body-proportion-deepen.md); extreme anim retarget stays [`DEF-009`](../backlog/deferred/DEF-009-extreme-morph-anim-retarget.md). Weight is not wired into jiggle.

---

## CC-4 — Soft-body / jiggle from muscle ↔ fat

### Outcome

Preview (and later in-world) soft motion is driven by the **muscle ↔ fat** bar: higher fat → more motion, higher muscle → less. Not a maze of unrelated jiggle toggles.

### Maps to

| ID | Feature |
| --- | --- |
| 2.8 | Jiggle / soft-body |

### In scope

- One driver: muscle–fat (plus any minimal per-region mask needed for stability)
- **Bone-spring / secondary bones** (not SoftBody3D as default) — [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md)
- Visible in creator preview when the player moves the camera or a light “turntable” nudge plays
- Same amplitude path **in-world** after spawn (not creator-only)
- Stable at extreme muscle (near-zero jiggle) and extreme fat (readable, not broken)
- Document how outfit layers inherit or damp the motion

### Out of scope

- Adult-only toggle sprawl / separate breast/hip checkbox farms
- SoftBody3D as the v1 solution
- Final cloth cape physics (loadout/outfit cape ships with gear persistence; outfit cloth may stub here) — Deferred: [`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md)

### Dependencies

- CC-3 muscle↔fat bar live on the preview mesh
- Appearance contract jiggle section

### Work

- Bone-spring secondary motion; map `muscle_fat` → amplitude; zero/near-zero at full muscle
- Creator turntable or idle breath so motion is testable without gameplay
- Ensure spawned player reuses the same jiggle apply
- Tests: fat end produces higher amplitude metric than muscle end (hook or proxy)
- **Summer:** play with bar at ends; record short observation via screenshot/play; diagnostics for physics spam

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Motion validation stills (optional) | `game/art/characters/_ref_jiggle_pose.png` | Only if needed for tuning | Neutral creator pose; not a style-drift concept |

**Default:** no new hero art — reuse CC-2/CC-3 body. Call out “no new art — reuse body kit” in the PR if nothing generated.

### Acceptance

- [x] Single muscle↔fat driver controls soft motion
- [x] Muscle end calm; fat end visibly softer
- [x] No per-part toggle maze in UI
- [x] Summer play + diagnostics clean (no error spam from soft-body)
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — cape cloth stays [`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md). Starter outfits inherit jiggle at 0.55 damp.

---

### Outcome

Face category offers an anime **starter kit**: **named** face morphs (contract list), eyes, hair (styles + color), plus a **thin scars/markings** starter. Catalog grows under this epic ID / `DEF-011`.

### Maps to

| ID | Feature |
| --- | --- |
| 2.9 | Face / hair / eyes |
| 2.16 | Scars / markings |

### In scope

- **Named face morphs** from [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md): `brow`, `eye_shape`, `nose`, `cheek`, `jaw`, `mouth`, `chin` — all wired
- Eye style + iris color
- Hair style set + color
- Scar + marking pickers: **none** + ≥1 option each
- All starter options unlocked
- Preview updates live (including head-only camera framing helper)

### Out of scope

- Closed “final” catalog / makeup farms — pack 07 [CX-4](07-character-creator-complete.md#cx-4--face-morph-complete) / [CX-5](07-character-creator-complete.md#cx-5--hair-eyes-makeup); ticket [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md)
- Extra scar/marking variants beyond the thin starter — pack 07 [CX-6](07-character-creator-complete.md#cx-6--skin-materials-and-decal-compositor)

### Dependencies

- CC-1; race presets from CC-2 should set defaults
- Appearance contract named morph list

### Work

- Data-driven part lists (ids → meshes/materials); morph bus writes all seven keys
- UI grid with focusables; color pickers or swatches; scar/marking slots
- Tests: selecting parts mutates character record; all named morph keys serialize; scar/marking null clears overlay
- **Summer:** generate part sheets → import → attach to preview; play through styles + scar/marking; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Face morph reference sheet | `game/art/characters/face_sheet.png` | Start of CC-5 | Same head showing brow/nose/jaw/etc. extremes; anime; creator quality |
| Eye style sheet | `game/art/characters/eyes_sheet.png` | With face | Readable iris styles; consistent lighting |
| Hair style concepts (per style) | `game/art/characters/hair_{id}.png` | With face | Isolated hair on dark jewel void or on neutral head; clear silhouette |
| Scar / marking concepts | `game/art/characters/scar_*.png`, `marking_*.png` | With face | Face/body overlays; anime; readable; not horror gore |
| Hair / eye / overlay meshes & materials | `game/art/characters/...` | After concepts pass `Read` | image-to-3d or textured planes; keep anime materials |

Vertical-slice minimum: **7 named morphs wired**, **≥3 hair**, **≥3 eyes**, **≥1 scar**, **≥1 marking** (plus colors / none).

### Acceptance

- [x] All seven named face morphs adjustable
- [x] Player can change eyes, hair, scar, marking
- [x] Options unlocked; live preview
- [x] Assets under `game/art/characters/`
- [x] Summer play through the starter grid + diagnostics clean
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — catalog deepen stays [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md).

---

## CC-6 — Demi-human features

### Outcome

**Ears**, **horns**, and **tails** (including **lizard / dragon** tails) are available and **unlocked**. They are **optional on creation** (any combination or none). Demi-human race may offer presets; the player can clear them. Dragon-leaning demis are supported via horns + lizard tail (+ ears as desired) — no separate dragon race.

**This epic is in the vertical-slice cut.** Pack 02 is not playable without CC-6 landed (demi must not be tag-only).

### Maps to

| ID | Feature |
| --- | --- |
| 2.10 | Demi-human features |

### In scope

- Features category: **ears**, **horns**, **tails** (include at least one lizard/dragon tail)
- Optional: default off unless demi-human preset applies; player can unequip any/all
- Attach points on the preview rig
- All listed options unlocked from the start
- Race preset may enable demi-human defaults without forcing them

### Out of scope

- Wings, full-body scales, or other kits beyond ears/horns/tails — pack 07 deepen is [CX-7](07-character-creator-complete.md#cx-7--demi-human-catalog-complete); wings/scales remain [`DEF-018`](../backlog/deferred/DEF-018-demi-wings-scales.md). Slice-volume deepen: [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md)
- Gameplay bonuses tied to features
- Gating behind story flags
- A separate “dragon” race row (demi-human + parts is enough)

### Dependencies

- CC-1 preview rig attach points; CC-2 demi-human preset optional defaults

### Work

- Feature ids → meshes on sockets (ears, horns, tails incl. lizard)
- UI list/grid; parts combinable; document any conflicts
- Tests: equip/unequip updates record; demi preset may apply defaults; player can clear to none; lizard tail + horns combo works
- **Summer:** generate feature concepts → 3D → socket on Preview; play none and mixed combos; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Ears / horns / tails concepts | `game/art/characters/feature_{ears,horns,tails}_*.png` | Start of CC-6 | Isolated or on neutral head/hips; anime; readable silhouette; dark jewel void; include a **lizard/dragon tail** variant |
| Feature meshes | `game/art/characters/feature_*.glb` | After concepts | image-to-3d; clean pivots for sockets |

Vertical-slice minimum: **one ears, one horns, one mammal-style tail, one lizard/dragon tail**.

### Acceptance

- [x] Ears, horns, and tails equippable; can create with none
- [x] At least one lizard/dragon tail option exists
- [x] Horns + lizard tail (+ optional ears) readable as dragon demi
- [x] Demi-human preset may auto-apply defaults; player can clear
- [x] Meshes socket correctly on preview
- [x] Summer combination smoke + diagnostics clean
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — feature catalog deepen stays [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md).

---

### Outcome

Player picks a **starting outfit** (clothes / appearance). It is stored as **outfit**, never as combat **loadout**. Armor/weapons are not required to finish creator.

### Maps to

| ID | Feature |
| --- | --- |
| 2.11 | Starting cosmetics |

### In scope

- Outfit layer on the preview (replace or hide mannequin base clothes)
- Small unlocked starter wardrobe (styles + colors)
- Character record fields: `outfit` distinct from `loadout` (loadout empty or starter-null until gear systems)
- Clear UI copy or structure so outfit ≠ gear

### Out of scope

- Full transmog wardrobe endgame — pack 07 [CX-8](07-character-creator-complete.md#cx-8--outfit-fit-occlusion-wardrobe); ticket [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md)
- Cape cloth physics final (may stub; gear epic owns cape slot physics) — Deferred: [`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md)
- Accessories as combat gear (necklace/rings/earrings are loadout later — optional cosmetic-only dupes only if they stay outfit-scoped and documented)

### Dependencies

- CC-1; body proportions from CC-3 should not explode outfit meshes (LOD/fit best-effort)
- CC-10 Male / Female underwear bases — outfits layer on both kits

### Work

- Outfit resource ids; apply to preview mesh/materials
- Ensure confirm path (CC-8) persists outfit separately from loadout
- Tests: outfit change does not fill weapon/armor loadout slots
- **Summer:** generate outfit flats → 3D/textures → dress preview; play; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Starter outfit concepts (×N) | `game/art/characters/outfit_{id}.png` | Start of CC-7 | Full-body costume; material breakup; anime; creator quality; **no** weapons as the outfit identity |
| Outfit meshes / textures | `game/art/characters/outfit_*.*` | After concepts | image-to-3d or texture sets; PBR cloth; fit to base body |

Vertical-slice minimum: **≥3 outfits**.

### Acceptance

- [x] Outfit changes appearance only
- [x] Loadout remains empty / non-driving for creator completion
- [x] Assets under `game/art/characters/`
- [x] Summer dress-up smoke + diagnostics clean
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — wardrobe deepen stays [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md); cape cloth stays [`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md).

---

### Outcome

Confirm commits the character (body, race tag, morphs, outfit, name) and leaves creator into the **hub spawn** path. Until pack 03, a **hub stub** (empty space + return marker / portal placeholder) is enough — do not dump the player into Millbrook as the real home.

### Maps to

| ID | Feature |
| --- | --- |
| 2.12 | Confirm → spawn |

### In scope

- Validate required fields (name non-empty after strip; race present; morph defaults filled)
- Write engine-owned character record using **schema v1** ([`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md))
- Spawn uses the **same `AppearanceApplier`** + capsule builder as the preview (no second appearance path)
- **Tooling hook:** apply any valid schema v1 record to creator preview (debug/autoload OK; used by Summer/agents to verify generated faces)
- Transition: creator → hub scene/state
- Hub stub if pack 03 not landed: empty level, player spawns as created appearance
- Journal/event hook optional (`character_created` already exists in Living Town — prefer a clean character/hub save, do not grow Millbrook as home)

### Out of scope

- Full Sanctum hub art and portal modes (packs 03 / 05 — not deferred tickets)
- Loadout persistence across worlds (pack 05) — only ensure outfit/body survive this handoff; loadout may be empty in the record
- Continue / Load of that save from title (may smoke if trivial; OS-4 empty state can remain until persistence) — Deferred: [`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md)

### Dependencies

- Vertical slice of CC-1–CC-3, CC-5, CC-7 minimum; race tag from CC-2
- Appearance contract schema + applier
- Pack 01 title route

### Work

- Confirm button → serialize schema v1 → change flow state
- Cancel/Back does not write (or discards draft)
- Tests: confirm produces record with race + body + outfit; `schema_version == 1`; back does not; spawn capsule scales with height; spawn state ≠ creator
- **Summer:** full flow play Title → New → customize → Confirm → hub stub; diagnostics; screenshot spawned appearance

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Confirm flourish / wipe | `game/art/vfx/creator_confirm_wipe.png` | Polish | Short mystical bloom/wipe; sparse; no text |
| Hub stub skybox / ground (if needed) | `game/art/hub/hub_stub_*.png` | Only if pack 03 absent | Empty cozy dusk plaza; portal hint OK; not Millbrook graybox style |

**Call-forward:** pack 03 replaces hub stub with the real empty Sanctum + portal (epic pack — not a `DEF` ticket).

### Acceptance

- [x] Confirm writes schema v1 character and leaves creator
- [x] Spawn shows created appearance via shared applier
- [x] Capsule / camera pivot reflect body height (clamped)
- [x] Not Millbrook-as-home for the intended path
- [x] Summer full-flow smoke + diagnostics clean
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — load/continue after creator stays [`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md); draft save stays [`DEF-007`](../backlog/deferred/DEF-007-creator-draft-save.md). Pack 03 replaces the hub stub.

---

### Outcome

Full creator is usable on a **gamepad**: race grid, sliders, part grids, **Full/Dawn/Dusk lighting**, camera orbit, confirm/back, without a mouse. Focus visible. Stick/D-pad navigate; Accept confirms; Cancel backs; a dedicated orbit modifier or left/right stick split is documented and taught with glyphs.

### Maps to

| ID | Feature |
| --- | --- |
| 2.13 | Creator on controller |
| 2.14 | Preview lighting (pad-reachable) |

### In scope

- Focus neighbors across category rail, lists, sliders, lighting, reset/randomize, confirm/back
- Slider adjust via stick or shoulder buttons (pick one scheme; document)
- Lighting presets cycle or three focusable options on pad
- Reset / Randomize reachable without a mouse
- Camera orbit on pad
- Glyph prompts (reuse OS-6 set where possible)
- Keyboard/mouse still work

### Out of scope

- Full Controls rebind screen (title Settings placeholder remains) — Deferred: [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md)
- Mouse-cursor stick emulation as the solution

### Dependencies

- CC-1 UI focusables (incl. lighting); completes against CC-2–CC-8 as they land
- Pack 01 OS-6 glyph language preferred

### Work

- InputMap joypad bindings for creator-specific orbit/slider actions
- Focus ring on all adjustable controls including lighting
- Tests: actions present; focus graph has no traps on the main path
- Manual / **Summer play:** pad-only New → race → **Male/Female** → body sliders → lighting cycle → face → outfit → confirm → hub stub → (Alt) back-out paths
- Diagnostics after pad smoke

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Creator-specific glyphs (if needed) | `game/art/ui/glyph_orbit.png`, `glyph_slider.png` | With pad pass | Match OS-6 mystical anime glyph set; generic shapes; no console trademarks |
| Reuse | `game/art/ui/glyph_*.png`, `focus_ring.png` from OS-6 | Prefer reuse | No new art required if OS-6 set covers Accept/Cancel/Navigate |

### Acceptance

- [x] Pad-only complete creator → confirm
- [x] Pad-only back to title without mouse
- [x] Sliders and orbit usable on pad
- [x] Focus always visible
- [x] Summer pad smoke + diagnostics clean
- [x] `TEST_RESULT: PASS`

**Deferred review:** Open tickets checked. None roped in — full rebind stays [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md). Pad scheme: D-pad/left stick navigate, LB/RB nudge sliders, right stick orbit.

---

This pack is **Playable** (vertical slice) when:

1. Title **New** opens the atelier creator (OS-5 stub body gone) with Full/Dawn/Dusk lighting and Reset/Randomize.
2. Player can set race (preset + tag), **Male / Female**, body core (height/weight/muscle↔fat/skin), named face morphs, scars/markings, demi features (CC-6), starting outfit.
3. Confirm writes schema v1 engine-owned character; spawn uses shared applier + capsule scale into hub (or hub stub).
4. Outfit is distinct from loadout in data and UI.
5. Gamepad path works per CC-9 (including lighting, reset/randomize).
6. **Appearance authority:** shared applier can load any valid schema v1 record into creator preview (tooling/debug); illegal catalog ids rejected.
7. Generated character/UI art lives under `game/art/characters/` and `game/art/ui/` (vfx/hub stub as listed), lock + `style: "anime"`.
8. Implementation followed [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) and the **Summer workflow** above.
9. `.\scripts\test.ps1` prints `TEST_RESULT: PASS`.
10. Millbrook name-only create is not the intended New path.

**Deepen is pack 07, not more CC-ids.** Destination work: [`07-character-creator-complete.md`](07-character-creator-complete.md). Promoted tickets: [`DEF-014`](../backlog/deferred/DEF-014-body-proportion-deepen.md) → CX-3, [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md) → CX-4/CX-5, [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md) → CX-7, [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md) → CX-8, [`DEF-007`](../backlog/deferred/DEF-007-creator-draft-save.md) → CX-9. Jiggle polish stays under CC-4. Extreme anim retarget stays [`DEF-009`](../backlog/deferred/DEF-009-extreme-morph-anim-retarget.md).

**Not required for this pack:** real Sanctum content (pack 03), parkour (pack 04), portal worlds, combat gear, companion creator.

---

## Implementation notes for agents

- **One-shot against** [`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md). Do not re-litigate blendshape-vs-bones: hybrid is locked. Do not invent a parallel character JSON.
- **Appearance authority:** any character generated for worlds/NPCs/companions must use creator catalog ids. Expose apply-record-to-preview for Summer/debug. Do not ship one-off NPC meshes.
- **Summer is the scene and art cockpit for this pack.** Build the atelier and preview hierarchy with Summer mutations; generate concepts/meshes with Summer; prove the flow with Summer play + `summer_get_diagnostics`. Cursor owns GDScript and tests.
- Prefer a data-driven morph/part catalog so pack 07 can deepen without a second appearance JSON. Slice may keep `appearance_catalog.gd` lists; destination is `content/catalog/appearance/`.
- Keep character schema versioned; Living Town `user://living_town_v1.json` is not the destination character save.
- Do not collapse outfit into armor slots. Do not add Summer SDK to runtime.
- When pack 03 starts, replace the hub stub only — keep the character record and creator scene.
- Generate art in the same change series as the systems that show it; do not merge “forever gray mannequin” without the asset tables above tracked as in-branch follow-ups.
- **Deferments:** file new ones under [`../backlog/deferred/`](../backlog/deferred/). Before implementing any CC epic, review Open `DEF-*` tickets and rope in matches (especially [`DEF-006`](../backlog/deferred/DEF-006-creator-stub-art-retirement.md) with CC-1).
