# 13 — Character appearance (morph tech + record)

Technical contract so pack 02 can one-shot creator → spawn without inventing morph math mid-flight. Player fantasy stays in [`game-design.md`](game-design.md). Epic work: [`epics/02-character-creation.md`](epics/02-character-creation.md).

---

## Appearance authority (locked)

The **character creator catalog + schema v1** are the only legal appearance vocabulary for the game.

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
| Scars / markings | **Decal or overlay mesh / texture set** | Thin starter ids; deepen later |

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
| `proportions` | Slice minimum: head, torso, arms, legs. More keys later ([`DEF-014`](backlog/deferred/DEF-014-body-proportion-deepen.md)). |
| `face.morphs` | Must include the **named starter set** keys. |
| `face.scar_id` / `marking_id` | Catalog id or `null`. Thin starter: ≥1 scar, ≥1 marking, plus none. |
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
- Full makeup suite (lipstick/eyeshadow farms) in the slice — scars/markings starter only; deepen in [`DEF-011`](backlog/deferred/DEF-011-face-catalog-deepen.md)
- One-off NPC meshes or prompt-only faces that cannot be rebuilt in the creator
- Letting world directors invent appearance outside the creator catalog

---

## Tooling exposure (dev)

| Capability | Intent |
| --- | --- |
| Open creator scene via Summer | `scenePath` to the atelier; inspect preview + lights |
| Apply `CharacterRecord` to preview | Same applier as runtime; for agent/debug verification |
| Round-trip check | Record → apply → serialize ≈ record (catalog-legal) |
| Generate NPC appearance | Sample creator catalog + schema; never freehand art |

Shipped game code still must not call Summer SDK. Tooling is editor/MCP/debug only ([`tooling.md`](tooling.md)).
