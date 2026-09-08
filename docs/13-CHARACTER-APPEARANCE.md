# 13 — Character appearance (morph tech + record)

Technical contract for creator → spawn and every in-game face. Player fantasy stays in [`game-design.md`](game-design.md).

| Layer | Owns | Epic |
| --- | --- | --- |
| **Slice (now)** | Schema v1, hybrid morphs, named starter face, lighting, apply→capsule | [`epics/02-character-creation.md`](epics/02-character-creation.md) |
| **Destination** | Assembler pipeline, catalog-as-data, schema v2, Code Vein-class regions / face / makeup / decals / occlusion | [`epics/07-character-creator-complete.md`](epics/07-character-creator-complete.md) |

Do not implement destination mid-slice. Do not treat an outside “character customization engine” draft as this contract — see [Outside engine drafts](#outside-engine-drafts).

---

## Appearance authority (locked)

The **character creator catalog + versioned CharacterRecord** are the only legal appearance vocabulary for the game. Pack 02 ships **schema v1**. Pack 07 ships **schema v2** (superset; v1 loads via migration).

```text
Creator catalog (parts, morphs, colors, outfits)
        │
        ├── Player Confirm → CharacterRecord
        ├── NPC / companion / recruit generation → CharacterRecord
        └── Tooling preview / debug → load record into creator
```

Rules:

1. **Makeable ⇒ creatable.** If a character appears in play, a player could recreate that look in the creator (same part ids and morph ranges).
2. **Generators emit records, not art paths.** World compiler / directors / cognition output `race`, `body`, `face`, `features`, `outfit` using **existing catalog ids**. They do not emit ad-hoc `res://` meshes.
3. **Validation rejects illegal ids** (unknown hair, out-of-range morph, missing skin_color, etc.) before commit ([`04-SIMULATION.md`](04-SIMULATION.md)).
4. **New looks enter through the creator pipeline** — add part to `game/art/characters/` + catalog data, expose in creator UI, then allow generation to sample it.
5. **Tooling must expose the creator:** Summer can open the creator scene; debug/dev can apply any valid `CharacterRecord` to the preview; agents use that path to verify generated faces.

Companions and NPCs use the same `AppearanceApplier` as the player.

---

## Morph technology (locked)

**Hybrid.** Do not pick “only blendshapes” or “only bones.”

| Concern | Tech | Why |
| --- | --- | --- |
| Height, limb/torso proportions, overall scale | **Skeleton bone scales** (+ root height) | Plays nicer with AnimationPlayer / retarget; maps cleanly to capsule |
| Weight (frame mass) | **Bone scales** (uniform/lateral bulk on torso/limbs) | Thickens the frame without meaning “fat” |
| Face shape | **Blend shapes** (morph targets) | Facial detail without wrecking the body skeleton |
| Muscle ↔ fat composition | **Blend shapes** on body (primary) + light bone assist if needed | Soft vs lean surface; drives jiggle amplitude |
| Soft jiggle | **Bone-spring / secondary bones** amplitude from muscle↔fat | Stable with outfits; prefer over full `SoftBody3D` for v1 |
| Ears / horns / tails | **Socketed skinned meshes** (attach points) | Optional parts; lizard tail is just another tail mesh id |
| Skin color | **Material / shader tint** on body (and matching head) | First-class; not a mesh swap |
| Scars / markings | **Decal or overlay mesh / texture set** | Slice: thin starter ids. Destination: compositor + layers ([CX-6](epics/07-character-creator-complete.md#cx-6--skin-materials-and-decal-compositor)) |

### Height vs weight vs muscle↔fat

| Field | Player meaning | Apply |
| --- | --- | --- |
| `body.height` | Tall ↔ short | Root / spine scale → capsule height |
| `body.weight` | Light frame ↔ heavy frame | Lateral/bulk bone scales — **not** soft jiggle |
| `body.muscle_fat` | Muscular/lean ↔ soft | Body blendshapes + **jiggle amplitude** |

Do not wire `weight` into jiggle. Do not treat `muscle_fat` as overall size.

Rules:

1. **One morph bus** in code applies the character record → preview and in-world body. Creator and gameplay share the same apply function.
2. Do not maintain two incompatible morph systems (e.g. creator-only scales that gameplay ignores).
3. Ranges are normalized **0.0–1.0** in the save (0.5 = race/default midpoint unless a preset says otherwise).
4. Extremes are best-effort for anims ([`DEF-009`](backlog/deferred/DEF-009-extreme-morph-anim-retarget.md)); capsule must still be sane.

### Capsule / gameplay adapt

From `body.height` + `body.weight` + proportion scales, derive:

- `CharacterBody3D` capsule height / radius (clamped to min/max playable)
- Camera pivot height
- No different move list by size ([`game-design.md`](game-design.md) Movement)

Apply on spawn (CC-8) and whenever the live player appearance is rebuilt (hub / world).

### Jiggle (CC-4)

- Driver: `body.muscle_fat` only (plus optional internal region masks for stability — not player-facing toggles).
- `muscle_fat → 1.0` (fat end): higher spring amplitude.
- `muscle_fat → 0.0` (muscle end): near-zero amplitude.
- Runs in **creator preview and in-world**. Same parameters.
- Outfits damp or inherit; document per outfit if needed. Cape cloth is separate ([`DEF-010`](backlog/deferred/DEF-010-cape-cloth-physics.md)).

---

## Named face morphs (starter set — locked)

Vertical slice ships these blendshape channels (0–1 each). Names are stable ids in `face.morphs`:

| Id | Intent |
| --- | --- |
| `brow` | Brow height / angle |
| `eye_shape` | Eye openness / shape bias (separate from eye **style** mesh) |
| `nose` | Nose size / bridge |
| `cheek` | Cheek fullness |
| `jaw` | Jaw width / strength |
| `mouth` | Mouth width / lip bias |
| `chin` | Chin length / point |

Race presets may set defaults. Deepen adds more keys later ([`DEF-011`](backlog/deferred/DEF-011-face-catalog-deepen.md)); unknown keys ignored by older appliers if you extend carefully.

---

## Character record schema (v1)

Engine-owned. Versioned. Living Town JSON is not this schema.

```json
{
  "schema_version": 1,
  "id": "char_…",
  "display_name": "Player",
  "race": "human",
  "body": {
    "sex": "male",
    "height": 0.5,
    "weight": 0.5,
    "muscle_fat": 0.5,
    "skin_color": "#c8a07a",
    "proportions": {
      "head": 0.5,
      "torso": 0.5,
      "arms": 0.5,
      "legs": 0.5
    }
  },
  "face": {
    "shape_id": "face_default",
    "morphs": {
      "brow": 0.5,
      "eye_shape": 0.5,
      "nose": 0.5,
      "cheek": 0.5,
      "jaw": 0.5,
      "mouth": 0.5,
      "chin": 0.5
    },
    "eyes_id": "eyes_default",
    "eye_color": "#4a6fa5",
    "hair_id": "hair_default",
    "hair_color": "#2a1a12",
    "scar_id": null,
    "marking_id": null
  },
  "features": {
    "ears_id": null,
    "horns_id": null,
    "tails_id": null
  },
  "outfit": {
    "id": "outfit_starter_01"
  },
  "loadout": {
    "hands": { "main": null, "off": null },
    "armor": {},
    "accessories": {}
  }
}
```

### Field notes

| Field | Rules |
| --- | --- |
| `race` | One of `human`, `elf`, `dwarf`, `gnome`, `halfling`, `demi_human`. Preset + story tag; never locks other fields. |
| `body.sex` | One of `male`, `female`. Swaps the underwear base kit. Does not lock morphs, race, hair, features, or outfit. |
| `body.height` / `weight` / `muscle_fat` | Floats 0–1. See table above. `muscle_fat`: 0 = full muscle, 1 = full fat. |
| `body.skin_color` | Hex or engine Color string. Required. Starter ships a **swatch row** (≥6 tones); free picker optional later. |
| `proportions` | Slice: head, torso, arms, legs. Destination 14 keys: pack 07 / [`DEF-014`](backlog/deferred/DEF-014-body-proportion-deepen.md). |
| `face.morphs` | Slice: named starter set keys. Destination fine keys in schema v2. |
| `face.scar_id` / `marking_id` | Slice convenience ids. Destination: `decals[]` (CX-6); v1 aliases migrate. |
| `features.*_id` | Catalog part id or `null`. Optional. |
| `outfit` | Cosmetic only. Never write combat gear into outfit. |
| `loadout` | Creator leaves empty. Do not require loadout to Confirm. |

### Apply pipeline

```text
CharacterRecord
     │
     ▼
AppearanceApplier.apply(record, skeleton_mesh_root)
     │  swap underwear base kit ← body.sex
     │  bone scales ← height / weight / proportions
     │  body blendshapes ← muscle_fat
     │  skin tint ← skin_color
     │  face blendshapes ← named face.morphs
     │  swap meshes ← hair, eyes, outfit, features, scar/marking overlays
     │  jiggle springs ← muscle_fat amplitude
     ▼
Preview (creator)  ==  Player body (hub / world)
     │
     ▼
CapsuleBuilder.from_body(record.body) → CharacterBody3D shape + camera pivot
```

Confirm (CC-8) writes the record, then spawns using the same applier.

---

## Creator UX tools (locked for slice)

| Tool | Behavior |
| --- | --- |
| **Reset all** | Re-apply current race preset (confirm if dirty). |
| **Reset category** | Re-apply preset values for the active category only (Body / Face / Features / Outfit). |
| **Randomize all** | Random legal values across unlocked options and 0–1 sliders. Crude is fine. |
| **Randomize category** | Same, scoped to active category. |

Gamepad-reachable. No undo stack required in v1.

---

## Creator preview lighting (locked)

Creator atelier exposes a **lighting preset** toggle so players can judge shading before Confirm:

| Preset | Intent |
| --- | --- |
| **Full** | Bright, even atelier key — read materials and colors clearly |
| **Dawn** | Warm low sun, long soft shadows |
| **Dusk** | Cool jewel dusk (Sanctum-adjacent mood), deeper shadows, sparse rims |

Rules:

- Preview-only. Does **not** set Sanctum or world time of day.
- Three named presets on `WorldEnvironment` + key/fill/rim lights (or equivalent). No freeform color picker required for v1.
- Must be usable on **gamepad** (cycle or three focusable options).
- Default: **Full** (safe read while building the character); player can switch anytime.

---

## Vertical-slice catalog minimums

| Kind | Minimum |
| --- | --- |
| Base body kits | **Male** and **Female** underwear bases |
| Skin swatches | ≥6 |
| Named face morphs | 7 listed above (all wired) |
| Hair styles | ≥3 + colors |
| Eye styles | ≥3 + colors |
| Scars | ≥1 + none |
| Markings | ≥1 + none |
| Ears / horns / tails | ≥1 each; tails include ≥1 lizard/dragon |
| Starter outfits | ≥3 |

---

## Non-goals

- SoftBody3D as the default jiggle solution
- Separate creator-only appearance that gameplay cannot load
- Per-breast / per-hip jiggle toggles
- Requiring blendshape-only body proportion (breaks anim/capsule story)
- Wiring `weight` into jiggle
- Full makeup suite in the **slice** — scars/markings starter only; destination makeup is pack 07 [CX-5](epics/07-character-creator-complete.md#cx-5--hair-eyes-makeup)
- One-off NPC meshes or prompt-only faces that cannot be rebuilt in the creator
- Letting world directors invent appearance outside the creator catalog
- Replacing this record with a raw `boneScales` / `morphWeights` blob (those are **apply maps**, not the save)
- A C# / engine-agnostic assembler in shipped game code
- Third body kit / `genderPreset` (androgynous as a base). Sex is **Male / Female** underwear kits.

---

## Tooling exposure (dev)

| Capability | Intent |
| --- | --- |
| Open creator scene via Summer | `scenePath` to the atelier; inspect preview + lights |
| Apply `CharacterRecord` to preview | Same applier as runtime; for agent/debug verification |
| Round-trip check | Record → apply → serialize ≈ record (catalog-legal) |
| Generate NPC appearance | Sample creator catalog + schema; never freehand art |

Shipped game code still must not call Summer SDK. Tooling is editor/MCP/debug only ([`tooling.md`](tooling.md)).

---

## Outside engine drafts

An outside “Character Customization Engine” spec (C# / TypeScript DTO, `genderPreset`, raw bone/morph dictionaries, UDP payload budgets) is **not** this game’s contract. Repo locks beat it.

| Take | Leave |
| --- | --- |
| UI writes a DTO; an assembler applies it; the renderer does not own identity | C# / `ICharacterAssembler` / Newtonsoft in Godot |
| Staged apply: bones → morphs → attachments + occlusion → materials → decals | Saving `boneScales` / `morphWeights` as the player record |
| Outfit/feature **occlusion rules** (hide body submeshes under clothes) | `genderPreset`: masculine / feminine / androgynous as identity |
| Decal layers: region + UV + rotation + blend + tint | 4 KB uncompressed JSON “for UDP multiplayer” — this game is single-player |
| Hot path (sliders) vs cold path (mesh swap / spawn) | Zero-GC / 0.2 ms C# frame budgets as architecture |
| Bone **child locks** (scale torso without exploding hands/sockets) | `RebakeMesh` on every slider tick |
| Shared apply for player, companion, NPC | Engine-agnostic mesh registry returning `object` |

The save stays a **semantic** `CharacterRecord`. Bones, blendshape names, texture slots, and sockets are **catalog apply maps**. If the skeleton is retargeted, maps change; saves do not.

---

## Destination engine (pack 07)

Slice `AppearanceApplier` may still whole-scale a kit and tint albedo. Destination replaces that with a staged assembler that still has **one** public entry: `AppearanceApplier.apply(record, skeleton_mesh_root)` (preview == hub == world == companion).

```text
UI / generator / debug
        │  mutates
        ▼
CharacterRecord (semantic, versioned, engine-owned)
        │
        ▼
AppearanceApplier.apply(record, root)
        │
        ├─ 0. Resolve catalog rows (reject illegal ids)
        ├─ 1. Base kit swap          ← body.sex
        ├─ 2. Bone scales            ← height / weight / proportions + child locks
        ├─ 3. Blendshapes            ← muscle_fat + face.morphs
        ├─ 4. Slot attachments       ← hair, eyes, features, outfit pieces
        ├─ 5. Occlusion              ← catalog MeshOcclusionRule
        ├─ 6. Materials              ← skin, hair, eyes, outfit tints (cached DMIs)
        ├─ 7. Decals (if dirty)      ← makeup + scars + markings + tattoo layers
        └─ 8. Jiggle springs         ← muscle_fat amplitude
                │
                ▼
        Preview  ==  Player  ==  Companion  ==  NPC
                │
                ▼
        CapsuleBuilder.from_body(record.body)
```

### Hot vs cold

| Path | When | Allowed | Forbidden |
| --- | --- | --- | --- |
| **Hot** | Slider / color / morph drag | Bone scales, blendshape weights, existing material scalars/colors, jiggle amplitude | Mesh load, shader compile, render-target recreate, catalog parse from disk |
| **Cold** | Sex/kit swap, part equip, outfit change, Confirm, spawn, load save | Everything, including occlusion rebuild and decal bake | Hitching without a wait affordance if cold work exceeds ~150 ms |

Decal composite is **dirty-flagged**. Dragging height does not rebake tattoos. Changing a decal layer or makeup id does.

### Semantic record vs apply maps

```text
CharacterRecord.body.proportions.waist = 0.72
        │
        ▼
content/catalog/appearance/maps/proportions.json
  waist → { bones: [{ name: "Spine_01", axis: "xz", min: 0.88, max: 1.18, inherit: true }],
            child_locks: ["LeftHand", "RightHand", "Head"] }
        │
        ▼
Skeleton3D bone rest scale (Stage 2)
```

Player-facing ids (`waist`, `brow_height`, `hair_wave`) are stable. Engine bone/blendshape names are not. Do not serialize Mixamo or Godot bone strings into the save.

### Bone constraints (Stage 2)

- Evaluate from pelvis / hips outward.
- `Scale_final = rest_scale * catalog_curve(record_value)`.
- **Inherit** unless a child lock is listed (hands, weapon sockets, eye bones).
- Height drives root / spine length and capsule; it is not a uniform XYZ scale of the whole Node3D.
- Weight drives lateral bulk; it does not drive jiggle.
- Capsule / camera pivot still come from `CapsuleBuilder` using the same record.

### Blendshapes (Stage 3)

- Clamp 0–1. Combine linearly when several keys are non-zero (no “last slider wins”).
- Face keys and `muscle_fat` body keys are separate channels.
- Unknown keys in an older applier: ignore. Missing required keys after migration: default 0.5.
- Bind only **active** (non-midpoint) deltas each frame; do not upload the entire morph bank if the mesh supports sparse weights.

### Slots, sockets, occlusion (Stages 4–5)

Catalog rows declare:

| Field | Intent |
| --- | --- |
| `slot` | `hair`, `eyes`, `ears`, `horns`, `tails`, `outfit_top`, `outfit_bottom`, `outfit_shoes`, `outfit_extra`, `outfit` (whole look) |
| `mesh` | `res://game/art/characters/…` |
| `socket` | Bone / Marker3D name on the base kit (shared Male / Female layout) |
| `hide_slots` | Other slots to hide while this row is equipped |
| `hide_submeshes` | Base-kit surface names to hide (torso under a closed coat) |
| `fit_bones` | Bones this mesh must follow (skinned) vs rigid socket |

Whole-look `outfit.id` expands to piece ids when the row has `pieces`. Layered pieces win over the whole-look mesh if both are set.

### Materials (Stage 6)

- One **master** material per family (skin, hair, eye, cloth). Runtime instances are cached on the preview root; hot path only sets parameters.
- Skin: `skin_color` + optional `skin_undertone` (0 cool ↔ 1 warm). Same instance on body and head.
- Hair: `hair_color` + optional `hair_highlight`.
- Eyes: `eye_color`; optional `eye_color_r` for heterochromia (null = both eyes match).
- Outfit: `outfit.colors.primary|secondary|accent` mapped to shader params named in the catalog row.

### Decals (Stage 7)

Isolated composite (offscreen, resolution in catalog; 1K is enough for anime, 2K if a pass actually needs it). Not a photoshop.

1. Draw base skin (or region mask) into the RT.
2. Sort `decals[]` by `order`.
3. Draw each layer with `blend` (`alpha` / `multiply` / `additive`), `uv_offset`, `uv_scale`, `rotation`, `color_tint`.
4. Bind the result to the skin DMI albedo (or a dedicated overlay map).

Makeup channels may be implemented as decals **or** as dedicated face material params — catalog chooses per id. Player UI does not care.

### Performance (Godot, not C#)

| Target | Meaning |
| --- | --- |
| Hot slider | Preview stays interactive at 60 fps; no mesh load, no RT allocate |
| Cold part swap | Prefer &lt; 150 ms; if over, show a short atelier wait, do not freeze input forever |
| Spawn / load | Same assembler; hitch OK at scene change |
| Save size | Versioned JSON, no 4 KB cap. Keep it human-debuggable. Do not duplicate meshes in the save |

---

## Appearance catalog (destination)

Slice catalog is `game/character/appearance_catalog.gd` id lists. Destination is **data** under `content/catalog/appearance/`, same approval loop as [`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md): agent pre-screen (mesh required) → you approve → runtime samples `approved` only.

```text
content/catalog/appearance/
  bodies/          # underwear base kits (male / female)
  maps/            # semantic field → bones / blendshapes / child locks
  hair/
  eyes/
  makeup/
  decals/          # scars, markings, tattoos
  features/        # ears, horns, tails
  outfits/         # whole looks + pieces + occlusion
  _inbox/          # pending / ready_for_review (not playable)
```

Art still imports to `game/art/characters/` (and UI chrome to `game/art/ui/`). Catalog JSON points at those paths. Generators emit **ids**, never raw `res://` in a `CharacterRecord`.

Illegal id → validation fail → do not apply, do not Confirm, do not spawn.

---

## Named destination morphs (schema v2)

All 0–1. v1 seven face keys and four proportion keys remain legal; migration fans them out to the fine keys below.

### Body proportions

| Id | Intent |
| --- | --- |
| `head` | Head size (v1 kept) |
| `neck` | Neck length / thickness |
| `shoulders` | Shoulder width |
| `chest` | Upper torso / ribcage |
| `bust` | Chest soft volume (morph + bones; **not** a jiggle toggle) |
| `waist` | Waist width |
| `abdomen` | Midsection depth |
| `hips` | Hip width |
| `upper_arms` | Upper arm bulk / length bias |
| `forearms` | Forearm bulk |
| `hands` | Hand size |
| `thighs` | Thigh bulk / length bias |
| `calves` | Calf bulk |
| `feet` | Foot size |

v1 `torso` / `arms` / `legs` on migrate: copy into the group (`chest+waist+abdomen`, `upper_arms+forearms+hands`, `thighs+calves+feet`). UI may offer group sliders that write the group, plus independent overrides.

`bust` is a proportion, not a player-facing “jiggle on/off.” Jiggle amplitude stays `muscle_fat` only.

### Face morphs

v1 keys stay as **group aliases** (migrate into the first fine key; others default 0.5):

| Group (v1) | Fine keys |
| --- | --- |
| `brow` | `brow_height`, `brow_angle`, `brow_inner`, `brow_outer` |
| `eye_shape` | `eye_shape`, `eye_size`, `eye_spacing`, `eye_angle`, `eye_depth` |
| `nose` | `nose_bridge`, `nose_width`, `nose_length`, `nose_tip` |
| `cheek` | `cheek_width`, `cheek_height` |
| `jaw` | `jaw_width`, `jaw_height` |
| `mouth` | `mouth_width`, `mouth_position`, `mouth_thickness` |
| `chin` | `chin_length`, `chin_width` |
| — | `ear_size`, `ear_angle` (human ears; demi ear meshes hide/replace these) |

`face.shape_id` remains a catalog face-base / topology preset. Morphs layer on it.

### Makeup (unlocked)

| Slot | Record |
| --- | --- |
| Eyeshadow | `makeup.eyeshadow_id` + `eyeshadow_color` |
| Liner | `makeup.liner_id` + `liner_color` |
| Lipstick | `makeup.lipstick_id` + `lipstick_color` |
| Blush | `makeup.blush_id` + `blush_color` |

`null` id = none. Colors ignored when id is null.

### Decal layers

```json
{
  "layer_id": "d1",
  "decal_id": "tattoo_vine_01",
  "region": "torso_front",
  "blend": "multiply",
  "uv_offset": [0.0, 0.0],
  "uv_scale": [1.0, 1.0],
  "rotation": 0.0,
  "color_tint": [1, 1, 1, 1],
  "order": 0
}
```

`region` enum: `face`, `torso_front`, `torso_back`, `arm_left`, `arm_right`, `leg_left`, `leg_right`.

Slice `face.scar_id` / `marking_id` migrate to one decal layer each (or stay as convenience aliases that the applier still honors). Destination UI can keep a simple “scar / marking picker” that writes a layer.

Pad path: pick a catalog stamp, pick a region, nudge offset/scale/rotation in coarse steps. Not freeform painting.

### Outfit (destination)

```json
"outfit": {
  "id": "outfit_starter_01",
  "pieces": { "top": null, "bottom": null, "shoes": null, "extra": null },
  "colors": { "primary": "#6a7a88", "secondary": "#2a3038", "accent": "#c4a46a" }
}
```

- `id` is a whole-look preset (still valid alone).
- `pieces` override when non-null.
- Colors tint; they are not loadout.
- Loadout stays empty in creator Confirm.

---

## Character record schema (v2)

Engine-owned. Versioned. v1 files load through a one-way migrate (fill fine keys, wrap scars as decals, default makeup none). New writes after pack 07 Confirm are v2.

```json
{
  "schema_version": 2,
  "id": "char_…",
  "display_name": "Player",
  "race": "human",
  "body": {
    "sex": "female",
    "height": 0.5,
    "weight": 0.5,
    "muscle_fat": 0.5,
    "skin_color": "#c8a07a",
    "skin_undertone": 0.5,
    "proportions": {
      "head": 0.5,
      "neck": 0.5,
      "shoulders": 0.5,
      "chest": 0.5,
      "bust": 0.5,
      "waist": 0.5,
      "abdomen": 0.5,
      "hips": 0.5,
      "upper_arms": 0.5,
      "forearms": 0.5,
      "hands": 0.5,
      "thighs": 0.5,
      "calves": 0.5,
      "feet": 0.5
    }
  },
  "face": {
    "shape_id": "face_default",
    "morphs": {
      "brow_height": 0.5,
      "brow_angle": 0.5,
      "brow_inner": 0.5,
      "brow_outer": 0.5,
      "eye_shape": 0.5,
      "eye_size": 0.5,
      "eye_spacing": 0.5,
      "eye_angle": 0.5,
      "eye_depth": 0.5,
      "nose_bridge": 0.5,
      "nose_width": 0.5,
      "nose_length": 0.5,
      "nose_tip": 0.5,
      "cheek_width": 0.5,
      "cheek_height": 0.5,
      "jaw_width": 0.5,
      "jaw_height": 0.5,
      "mouth_width": 0.5,
      "mouth_position": 0.5,
      "mouth_thickness": 0.5,
      "chin_length": 0.5,
      "chin_width": 0.5,
      "ear_size": 0.5,
      "ear_angle": 0.5
    },
    "eyes_id": "eyes_default",
    "eye_color": "#4a6fa5",
    "eye_color_r": null,
    "hair_id": "hair_default",
    "hair_color": "#2a1a12",
    "hair_highlight": null
  },
  "makeup": {
    "eyeshadow_id": null,
    "eyeshadow_color": "#00000000",
    "liner_id": null,
    "liner_color": "#00000000",
    "lipstick_id": null,
    "lipstick_color": "#00000000",
    "blush_id": null,
    "blush_color": "#00000000"
  },
  "decals": [],
  "features": {
    "ears_id": null,
    "horns_id": null,
    "tails_id": null
  },
  "outfit": {
    "id": "outfit_starter_01",
    "pieces": { "top": null, "bottom": null, "shoes": null, "extra": null },
    "colors": { "primary": "#6a7a88", "secondary": "#2a3038", "accent": "#c4a46a" }
  },
  "loadout": {
    "hands": { "main": null, "off": null },
    "armor": {},
    "accessories": {}
  }
}
```

v1 `face.scar_id` / `marking_id` remain readable on migrate. Appliers after CX-2 prefer `decals[]`.

---

## Destination catalog minimums (pack 07 DOD)

Slice minimums in the table above still hold. Pack 07 does not ship until at least:

| Kind | Minimum |
| --- | --- |
| Body proportion keys | All 14 listed, wired |
| Face morph keys | All fine keys listed, wired |
| Hair styles | ≥12 + color + optional highlight |
| Eye styles | ≥8 + color + optional heterochromia |
| Makeup | ≥4 ids each channel + none |
| Decals | ≥8 scars, ≥8 markings/tattoos across regions + none |
| Ears / horns / tails | ≥6 / ≥6 / ≥8 (mammal + lizard/dragon each represented) |
| Outfits | ≥8 whole looks **or** equivalent piece combinations; occlusion on closed garments |
| Apply maps | Height, weight, every proportion, every face key, muscle_fat |

All unlocked. Race still does not lock the catalog.

---

## Destination UX (atelier)

Slice tools stay: Reset all/category, Randomize all/category, Full/Dawn/Dusk, pad-first.

Pack 07 adds:

| Tool | Intent |
| --- | --- |
| **Category rail** | Race, Body, Face, Hair, Makeup, Marks, Features, Outfit |
| **Framing** | Full body / bust / face cameras; pad cycle |
| **Pose** | Small list (idle, turntable, three face expressions) so morphs can be judged |
| **Compare** | Hold or toggle previous snapshot vs live draft |
| **Undo / redo** | Short stack (last ~20 edits). Not a full history browser |
| **Draft save** | Explicit; does not overwrite a confirmed character — [`DEF-007`](backlog/deferred/DEF-007-creator-draft-save.md) |

Undo does not replace Reset. Compare is not a second character slot.
