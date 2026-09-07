# 13 — Character appearance (morph tech + record)

Technical contract so pack 02 can one-shot creator → spawn without inventing morph math mid-flight. Player fantasy stays in [`game-design.md`](game-design.md). Epic work: [`epics/02-character-creation.md`](epics/02-character-creation.md).

---

## Morph technology (locked)

**Hybrid.** Do not pick “only blendshapes” or “only bones.”

| Concern | Tech | Why |
| --- | --- | --- |
| Height, limb/torso proportions, overall scale | **Skeleton bone scales** (+ root height) | Plays nicer with AnimationPlayer / retarget; maps cleanly to capsule |
| Face shape / expression-ready face kit | **Blend shapes** (morph targets) | Facial detail without wrecking the body skeleton |
| Muscle ↔ fat silhouette | **Blend shapes** on body (primary) + light bone scale assist if needed | Surface volume reads; one slider drives the set |
| Soft jiggle | **Bone-spring / secondary bones** amplitude from muscle↔fat | Stable with outfits; prefer over full `SoftBody3D` for v1 |
| Ears / horns / tails | **Socketed skinned meshes** (attach points) | Optional parts; lizard tail is just another tail mesh id |

Rules:

1. **One morph bus** in code applies the character record → preview and in-world body. Creator and gameplay share the same apply function.
2. Do not maintain two incompatible morph systems (e.g. creator-only scales that gameplay ignores).
3. Ranges are normalized **0.0–1.0** in the save (0.5 = race/default midpoint unless a preset says otherwise).
4. Extremes are best-effort for anims ([`DEF-009`](backlog/deferred/DEF-009-extreme-morph-anim-retarget.md)); capsule must still be sane.

### Capsule / gameplay adapt

From `body.height` + proportion scales, derive:

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

## Character record schema (v1)

Engine-owned. Versioned. Living Town JSON is not this schema.

```json
{
  "schema_version": 1,
  "id": "char_…",
  "display_name": "Player",
  "race": "human",
  "body": {
    "height": 0.5,
    "weight": 0.5,
    "muscle_fat": 0.5,
    "proportions": {
      "head": 0.5,
      "torso": 0.5,
      "arms": 0.5,
      "legs": 0.5
    }
  },
  "face": {
    "shape_id": "face_default",
    "morphs": {},
    "eyes_id": "eyes_default",
    "eye_color": "#4a6fa5",
    "hair_id": "hair_default",
    "hair_color": "#2a1a12"
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
| `body.*` | Floats 0–1. `muscle_fat`: 0 = full muscle, 1 = full fat. |
| `proportions` | Slice minimum: head, torso, arms, legs. More keys later ([`DEF-014`](backlog/deferred/DEF-014-body-proportion-deepen.md)); unknown keys ignored on old builds if you add them carefully. |
| `face.morphs` | Sparse blendshape name → 0–1. Empty object OK for slice. |
| `features.*_id` | Catalog part id or `null`. Optional; demi dragon = horns + lizard tail ids, etc. |
| `outfit` | Cosmetic only. Never write combat gear into outfit. |
| `loadout` | Creator leaves empty/null equipment. Persistence pack fills later. Do not require loadout to Confirm. |

### Apply pipeline

```text
CharacterRecord
     │
     ▼
AppearanceApplier.apply(record, skeleton_mesh_root)
     │  bone scales ← body.height / weight / proportions
     │  body blendshapes ← muscle_fat (+ any body morphs)
     │  face blendshapes ← face.morphs / shape
     │  swap meshes ← hair, eyes, outfit, features sockets
     │  jiggle springs ← muscle_fat amplitude
     ▼
Preview (creator)  ==  Player body (hub / world)
     │
     ▼
CapsuleBuilder.from_body(record.body) → CharacterBody3D shape + camera pivot
```

Confirm (CC-8) writes the record, then spawns using the same applier.

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

## Non-goals

- SoftBody3D as the default jiggle solution
- Separate creator-only appearance that gameplay cannot load
- Per-breast / per-hip jiggle toggles
- Requiring blendshape-only body proportion (breaks anim/capsule story)
