# Epic pack 02 — Character creation

**Status:** Planned  
**Feature-list:** [`feature-list.md`](../feature-list.md) §2 Character creation  
**Design:** [`game-design.md`](../game-design.md) Character creation + Gear and appearance (outfit ≠ loadout)  
**Art:** [`art-style.md`](../art-style.md), [`art/prompt-lock.md`](../art/prompt-lock.md) — Character / creator / portrait suffix  
**Import roots:** `game/art/characters/` (bodies, race kits, outfit cosmetics), `game/art/ui/` (creator chrome), `game/art/vfx/` (atelier light / transition only)  
**Operating loop:** [`agent-operating-loop.md`](../agent-operating-loop.md) + [`.summer/AGENTS.md`](../../.summer/AGENTS.md)

Code Vein-class depth is the **target**. This pack ships a **vertical slice** first (playable New → customize → confirm → hub handoff), then deepens morphs and catalogs inside the same epic IDs. Replace the OS-5 creator **stub body**; keep the Title → New route from pack 01.

Suggested ship order: **CC-1 → CC-2 → CC-3 → CC-5 / CC-6 (parallel after race) → CC-7 → CC-4 → CC-8 → CC-9**.  
**Vertical-slice cut** (minimum playable): CC-1, CC-2, thin CC-3, thin CC-5, thin CC-7, CC-8, CC-9. CC-4 and full demi-human catalog can land immediately after the cut without waiting for pack 03.

---

## Shared locks (all CC epics)

- New always enters **full** creator before hub spawn. No intended-path skip. Debug skip may exist; it is not a title or creator button.
- All cosmetic options stay **unlocked**. Do not gate parts behind play, quests, or currency.
- Race is a **preset + story tag**, never a lock on morphs or outfit.
- **Outfit ≠ loadout.** Creator starting clothes are cosmetics only. Do not invent combat armor/weapons as the creator’s appearance layer.
- Controller is first-class (CC-9 completes the pad path). Keyboard/mouse stays supported in parallel. No mouse-cursor-emulation gamepad path.
- Visuals: lock v1, dark jewel atelier, bright sparse rims. Image `style` is **`"anime"`**. Prepend the prompt-lock prefix; pass `options.negative_prompt` from the lock. Prefer `game/art/_style/` refs when present. Never use Kenney / `game/art/town/` as style.
- Character concepts and meshes live under `game/art/characters/`. Creator chrome under `game/art/ui/`. Do not park finals in `_style/`.
- Authoritative appearance state lives in the **engine** (character record). LLM / generators only produce assets or untrusted suggestions — never own the live morph dict.
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
3. Move height / weight / muscle–fat; preview updates live.
4. Change face/hair/eyes (and at least one demi-human feature when CC-6 is in).
5. Change starting outfit; confirm loadout slots are **not** required.
6. Orbit / frame the preview on pad (CC-9) or mouse.
7. Confirm → character written → hub handoff scene (empty hub when pack 03 exists; **hub stub** allowed until then).
8. Back / cancel from creator returns to title without writing a character (optional draft save later — Deferred: [`DEF-007`](../backlog/deferred/DEF-007-creator-draft-save.md)).

After each smoke: `summer_get_diagnostics`. Fix before declaring the epic playable.

---

## CC-1 — Creator atelier shell

### Outcome

New opens a dedicated **character atelier**: lit preview stage, orbit camera, category chrome, and a live mannequin/preview rig. It is obviously creator, not title and not town.

### Maps to

| ID | Feature |
| --- | --- |
| 2.1 | Creator screen |

### In scope

- Dedicated creator scene (or owned flow state) replacing the OS-5 stub body
- Preview stage: ground/plinth, three-point or atelier lighting, dark jewel backdrop
- Orbit / zoom framing around the preview character
- Category rail or tabs (Race, Body, Face, Features, Outfit) — empty panels OK until later CC epics fill them
- Name field (reuse / replace Millbrook name entry; name is not the whole creator)
- Back to title without spawning
- Summer-built control tree and lighting; GDScript owns state hooks

### Out of scope

- Full morph math (CC-3+)
- Confirm → hub write (CC-8)
- Final combat loadout UI

### Dependencies

- Pack 01 OS-5 New → creator route (or land route + shell together)
- Style lock v1

### Work

- Scene: e.g. `res://game/ui/character_creator.tscn` (name may vary; keep under `game/`, not Millbrook HUD)
- Flow owner: Title New → Creator; Back → Title
- Preview rig placeholder (capsule → real mesh as CC-2/CC-3 art lands)
- Input actions for camera orbit (mouse + placeholders for pad)
- Tests: New reaches creator scene; Back returns to title; no SCRIPT ERROR
- **Summer:** open creator `scenePath`, build Preview / Lights / UI with MCP mutations, `summer_play`, screenshot game view, diagnostics

### Asset generation

Generate **atelier + chrome before** locking final panel sizes.

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Atelier environment concept | `game/art/characters/creator_atelier_concept.png` | Start of CC-1 | Character atelier / mirror room; dark jewel; soft shafts; empty stage for a hero; **no** baked-in UI panels or readable sliders in the image |
| Atelier backdrop / HDRI-style still | `game/art/characters/creator_atelier_bg.png` | With concept | Full-bleed backdrop for the 3D stage; mystical anime; no logo text |
| Category tab chrome | `game/art/ui/creator_tab.png` (+ `_active`) | With shell | Dark panel, sparse bright rim; readable at HUD scale |
| Slider track / fill / thumb | `game/art/ui/creator_slider_*.png` | With shell | Compact mystical anime slider kit; not Material flat |
| Confirm / Back buttons | Reuse pack 01 primary chrome or `game/art/ui/creator_btn.png` | With shell | Match title language; creator-scale padding |
| Optional mote / dust sheet | `game/art/vfx/creator_motes.png` | Polish | Sparse gold/cyan motes; atelier atmosphere only |

**3D (Summer):** if the stage needs a prop (plinth, mirror frame), `summer_generate_3d` from a locked concept; `assetIntent: "object"`. Preview **body** waits for CC-2 concepts unless a neutral mannequin is generated here as temporary.

### Acceptance

- [ ] New → atelier creator (not Millbrook create-as-title, not hub)
- [ ] Back → title without character write
- [ ] Preview stage lit; camera orbits
- [ ] Category chrome visible (panels may be stubs)
- [ ] Art under `game/art/characters/` and `game/art/ui/`
- [ ] Summer: scene mutated via explicit `scenePath`; play + diagnostics clean
- [ ] `TEST_RESULT: PASS`

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
- Full demi-human part catalog deepen — Deferred: [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md); CC-6 owns the vertical-slice minimum; demi-human race may enable the Features tab early

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

- [ ] All six races selectable
- [ ] Preset visibly updates preview
- [ ] Tag stored on character-in-progress
- [ ] Player can override preset fields
- [ ] Race art/meshes under `game/art/characters/`
- [ ] Summer play flip through races + diagnostics clean
- [ ] `TEST_RESULT: PASS`

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

### In scope

- First-class height and weight sliders
- Muscle ↔ fat as one bar (not separate unrelated toggles)
- Proportion regions for the slice: at least head, torso, arms, legs (deepen later — Deferred: [`DEF-014`](../backlog/deferred/DEF-014-body-proportion-deepen.md))
- Live preview updates (scale / blend shapes / bone scales — engine choice, keep one approach)
- Capsule / collision preview scale hooks for later parkour (document; full move kit is pack 04)

### Out of scope

- Soft-body motion (CC-4)
- Face part catalog (CC-5)
- Final animation retarget for every extreme morph (best-effort clip; document known limits) — Deferred: [`DEF-009`](../backlog/deferred/DEF-009-extreme-morph-anim-retarget.md)

### Dependencies

- CC-1; CC-2 presets should feed default body values

### Work

- Morph state dict on character-in-progress
- Slider UI wired to morph bus → preview
- Clamp ranges; race preset sets defaults inside clamps
- Tests: slider extremes change serialized morphs; muscle–fat midpoint vs ends differ
- **Summer:** build slider rows in the Body panel via scene mutations; play and drag extremes; `summer_screenshot` game view for silhouette checks

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Body silhouette reference sheet | `game/art/characters/body_silhouette_sheet.png` | Start of CC-3 | Same character at short/tall and muscle/fat extremes; creator-quality; grid sheet; no UI |
| Region gizmo icons (optional) | `game/art/ui/creator_region_*.png` | If UI needs icons | Minimal anime UI glyphs for head/torso/limbs |

Most “art” here is the live mesh responding to morphs — prefer improving the CC-2 body kit over spawning unrelated bodies.

### Acceptance

- [ ] Height, weight, muscle↔fat, and ≥4 proportion regions work
- [ ] Preview updates without restarting the scene
- [ ] Values serialize on the in-progress character
- [ ] Summer diagnostics clean after slider smoke
- [ ] `TEST_RESULT: PASS`

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
- Visible in creator preview when the player moves the camera or a light “turntable” nudge plays
- Stable at extreme muscle (near-zero jiggle) and extreme fat (readable, not broken)
- Document how outfit layers inherit or damp the motion

### Out of scope

- Adult-only toggle sprawl / separate breast/hip checkbox farms
- Final cloth cape physics (loadout/outfit cape ships with gear persistence; outfit cloth may stub here) — Deferred: [`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md)

### Dependencies

- CC-3 muscle↔fat bar live on the preview mesh

### Work

- Soft-body or shader/bone-spring solution chosen for Godot 4 feasibility
- Map bar → amplitude; zero/near-zero at full muscle
- Creator turntable or idle breath so motion is testable without gameplay
- Tests: fat end produces higher amplitude metric than muscle end (hook or proxy)
- **Summer:** play with bar at ends; record short observation via screenshot/play; diagnostics for physics spam

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Motion validation stills (optional) | `game/art/characters/_ref_jiggle_pose.png` | Only if needed for tuning | Neutral creator pose; not a style-drift concept |

**Default:** no new hero art — reuse CC-2/CC-3 body. Call out “no new art — reuse body kit” in the PR if nothing generated.

### Acceptance

- [ ] Single muscle↔fat driver controls soft motion
- [ ] Muscle end calm; fat end visibly softer
- [ ] No per-part toggle maze in UI
- [ ] Summer play + diagnostics clean (no error spam from soft-body)
- [ ] `TEST_RESULT: PASS`

---

## CC-5 — Face / hair / eyes kit

### Outcome

Face category offers an anime **starter kit**: face morphs, eyes, hair (styles + color). Catalog grows over time under this epic ID; vertical slice ships a small but real set.

### Maps to

| ID | Feature |
| --- | --- |
| 2.9 | Face / hair / eyes |

### In scope

- Face shape morphs (slice: enough to differ from race preset)
- Eye style + iris color
- Hair style set + color
- All starter options unlocked
- Preview updates live (including head-only camera framing helper)

### Out of scope

- Closed “final” catalog — expand in follow-up PRs — Deferred: [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md)
- Makeup / scar / marking fullness — same ticket [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md)

### Dependencies

- CC-1; race presets from CC-2 should set defaults

### Work

- Data-driven part lists (ids → meshes/materials)
- UI grid with focusables; color pickers or swatches
- Tests: selecting parts mutates character record; defaults from race apply
- **Summer:** generate part sheets → import → attach to preview via scene tree; play through each style; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Face morph reference sheet | `game/art/characters/face_sheet.png` | Start of CC-5 | Same head, multiple face shapes; anime; creator quality |
| Eye style sheet | `game/art/characters/eyes_sheet.png` | With face | Readable iris styles; consistent lighting |
| Hair style concepts (per style) | `game/art/characters/hair_{id}.png` | With face | Isolated hair on dark jewel void or on neutral head; clear silhouette |
| Hair / eye meshes & materials | `game/art/characters/...` | After concepts pass `Read` | image-to-3d or textured planes as appropriate; keep anime materials |

Vertical-slice minimum: **≥3 hair styles, ≥3 eye styles, ≥3 face morph extremes** (plus colors).

### Acceptance

- [ ] Player can change face, eyes, hair in creator
- [ ] Options unlocked; live preview
- [ ] Assets under `game/art/characters/`
- [ ] Summer play through the starter grid + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CC-6 — Demi-human features

### Outcome

Ears, tails, horns, and similar features are available and **unlocked**. Demi-human race may highlight them; other races can still equip them (race is not a lock).

### Maps to

| ID | Feature |
| --- | --- |
| 2.10 | Demi-human features |

### In scope

- Features category: ears, tails, horns (minimum set); slots expandable
- Attach points on the preview rig
- All listed features unlocked from the start
- Race preset may enable defaults for demi-human without restricting others

### Out of scope

- Gameplay bonuses tied to features
- Gating behind story flags

### Dependencies

- CC-1 preview rig attach points; CC-2 demi-human preset optional defaults

### Work

- Feature ids → meshes on sockets
- UI list/grid; multiple features combinable where sane (document conflicts)
- Tests: equip/unequip updates record; demi preset applies at least one feature
- **Summer:** generate feature concepts → 3D → socket on Preview; play combinations; diagnostics

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Ears / horns / tails concepts | `game/art/characters/feature_{ears,horns,tails}_*.png` | Start of CC-6 | Isolated or on neutral head/hips; anime; readable silhouette; dark jewel void |
| Feature meshes | `game/art/characters/feature_*.glb` | After concepts | image-to-3d; `assetIntent: "character"` or object for isolated props; clean pivots for sockets |

Vertical-slice minimum: **one ears, one horns, one tail** option (more encouraged).

### Acceptance

- [ ] Features equippable regardless of race lock attempts
- [ ] Demi-human preset can auto-apply defaults
- [ ] Meshes socket correctly on preview
- [ ] Summer combination smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CC-7 — Starting outfit cosmetics

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

- Full transmog wardrobe endgame — Deferred: [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md)
- Cape cloth physics final (may stub; gear epic owns cape slot physics) — Deferred: [`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md)
- Accessories as combat gear (necklace/rings/earrings are loadout later — optional cosmetic-only dupes only if they stay outfit-scoped and documented)

### Dependencies

- CC-1; body proportions from CC-3 should not explode outfit meshes (LOD/fit best-effort)

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

- [ ] Outfit changes appearance only
- [ ] Loadout remains empty / non-driving for creator completion
- [ ] Assets under `game/art/characters/`
- [ ] Summer dress-up smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CC-8 — Confirm → write character → hub spawn handoff

### Outcome

Confirm commits the character (body, race tag, morphs, outfit, name) and leaves creator into the **hub spawn** path. Until pack 03, a **hub stub** (empty space + return marker / portal placeholder) is enough — do not dump the player into Millbrook as the real home.

### Maps to

| ID | Feature |
| --- | --- |
| 2.12 | Confirm → spawn |

### In scope

- Validate required fields (name non-empty after strip; race present; morph defaults filled)
- Write engine-owned character record (save stub OK; schema versioned)
- Transition: creator → hub scene/state
- Hub stub if pack 03 not landed: empty level, player spawns as created appearance
- Journal/event hook optional (`character_created` already exists in Living Town — prefer a clean character/hub save, do not grow Millbrook as home)

### Out of scope

- Full Sanctum hub art and portal modes (packs 03 / 05 — not deferred tickets)
- Loadout persistence across worlds (pack 05) — only ensure outfit/body survive this handoff
- Continue / Load of that save from title (may smoke if trivial; OS-4 empty state can remain until persistence) — Deferred: [`DEF-015`](../backlog/deferred/DEF-015-load-continue-after-creator.md)

### Dependencies

- Vertical slice of CC-1–CC-3, CC-5, CC-7 minimum; race tag from CC-2
- Pack 01 title route

### Work

- Confirm button → serialize character → change flow state
- Cancel/Back does not write (or discards draft)
- Tests: confirm produces record with race + morphs + outfit; back does not; spawn state ≠ creator
- **Summer:** full flow play Title → New → customize → Confirm → hub stub; diagnostics; screenshot spawned appearance

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Confirm flourish / wipe | `game/art/vfx/creator_confirm_wipe.png` | Polish | Short mystical bloom/wipe; sparse; no text |
| Hub stub skybox / ground (if needed) | `game/art/hub/hub_stub_*.png` | Only if pack 03 absent | Empty cozy dusk plaza; portal hint OK; not Millbrook graybox style |

**Call-forward:** pack 03 replaces hub stub with the real empty Sanctum + portal (epic pack — not a `DEF` ticket).

### Acceptance

- [ ] Confirm writes character and leaves creator
- [ ] Spawn shows created appearance
- [ ] Not Millbrook-as-home for the intended path
- [ ] Summer full-flow smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## CC-9 — Creator on controller

### Outcome

Full creator is usable on a **gamepad**: race grid, sliders, part grids, camera orbit, confirm/back, without a mouse. Focus visible. Stick/D-pad navigate; Accept confirms; Cancel backs; a dedicated orbit modifier or left/right stick split is documented and taught with glyphs.

### Maps to

| ID | Feature |
| --- | --- |
| 2.13 | Creator on controller |

### In scope

- Focus neighbors across category rail, lists, sliders, confirm/back
- Slider adjust via stick or shoulder buttons (pick one scheme; document)
- Camera orbit on pad
- Glyph prompts (reuse OS-6 set where possible)
- Keyboard/mouse still work

### Out of scope

- Full Controls rebind screen (title Settings placeholder remains) — Deferred: [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md)
- Mouse-cursor stick emulation as the solution

### Dependencies

- CC-1 UI focusables; completes against CC-2–CC-8 as they land
- Pack 01 OS-6 glyph language preferred

### Work

- InputMap joypad bindings for creator-specific orbit/slider actions
- Focus ring on all adjustable controls
- Tests: actions present; focus graph has no traps on the main path
- Manual / **Summer play:** pad-only New → race → body sliders → face → outfit → confirm → hub stub → (Alt) back-out paths
- Diagnostics after pad smoke

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Creator-specific glyphs (if needed) | `game/art/ui/glyph_orbit.png`, `glyph_slider.png` | With pad pass | Match OS-6 mystical anime glyph set; generic shapes; no console trademarks |
| Reuse | `game/art/ui/glyph_*.png`, `focus_ring.png` from OS-6 | Prefer reuse | No new art required if OS-6 set covers Accept/Cancel/Navigate |

### Acceptance

- [ ] Pad-only complete creator → confirm
- [ ] Pad-only back to title without mouse
- [ ] Sliders and orbit usable on pad
- [ ] Focus always visible
- [ ] Summer pad smoke + diagnostics clean
- [ ] `TEST_RESULT: PASS`

---

## Pack-level definition of done

This pack is **Playable** (vertical slice) when:

1. Title **New** opens the atelier creator (OS-5 stub body gone).
2. Player can set race (preset + tag), body core, face/hair/eyes starter kit, starting outfit.
3. Confirm writes an engine-owned character and spawns into hub (or hub stub).
4. Outfit is distinct from loadout in data and UI.
5. Gamepad path works per CC-9.
6. Generated character/UI art lives under `game/art/characters/` and `game/art/ui/` (vfx/hub stub as listed), lock v1, `style: "anime"`.
7. Implementation used the **Summer workflow** above for scene build, generate/import checks, play, and diagnostics (when MCP available).
8. `.\scripts\test.ps1` prints `TEST_RESULT: PASS`.
9. Millbrook name-only create is not the intended New path.

**Deepen still inside this pack (track as deferred tickets, rope into CC follow-ups):** [`DEF-014`](../backlog/deferred/DEF-014-body-proportion-deepen.md), [`DEF-011`](../backlog/deferred/DEF-011-face-catalog-deepen.md), [`DEF-012`](../backlog/deferred/DEF-012-demi-feature-catalog-deepen.md), [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md); jiggle polish stays under CC-4.

**Not required for this pack:** real Sanctum content (pack 03), parkour (pack 04), portal worlds, combat gear, companion creator.

---

## Implementation notes for agents

- **Summer is the scene and art cockpit for this pack.** Build the atelier and preview hierarchy with Summer mutations; generate concepts/meshes with Summer; prove the flow with Summer play + `summer_get_diagnostics`. Cursor owns GDScript and tests.
- Prefer a data-driven morph/part catalog early so CC-5/CC-6/CC-7 deepen without rewrite.
- Keep character schema versioned; Living Town `user://living_town_v1.json` is not the destination character save.
- Do not collapse outfit into armor slots. Do not add Summer SDK to runtime.
- When pack 03 starts, replace the hub stub only — keep the character record and creator scene.
- Generate art in the same change series as the systems that show it; do not merge “forever gray mannequin” without the asset tables above tracked as in-branch follow-ups.
- **Deferments:** file new ones under [`../backlog/deferred/`](../backlog/deferred/). Before implementing any CC epic, review Open `DEF-*` tickets and rope in matches (especially [`DEF-006`](../backlog/deferred/DEF-006-creator-stub-art-retirement.md) with CC-1).
