# 12 — Content catalog (generate → approve → place → collect)

Worlds should feel stocked: **many** buildings, items, and props — not a handful of hand-placed Kenney stands. Volume comes from generation. Quality comes from an **approval loop**. Play comes from worlds **placing** approved catalog entries so players can **learn and collect** them (especially Sanctum home designs).

Player fantasy: [`game-design.md`](game-design.md). Style: [`art-style.md`](art-style.md). Compiler: [`02-WORLD-COMPILER.md`](02-WORLD-COMPILER.md). This note owns the **catalog pipeline and data shape**.

---

## Three layers (do not collapse)

| Layer | What it is | Authority |
| --- | --- | --- |
| **Catalog** | Shipped library of approved content defs + art | Git / repo (after approval) |
| **World instances** | A placed cottage in *this* settlement pointing at a catalog id | World seed + mutations |
| **Player collection** | Designs / items the player has **learned** | Hub / character save |

The LLM and image generators produce **candidates**. They do **not** own live inventories, Sanctum builds, or world instance state. Only **approved** catalog rows may be referenced by the compiler or by player unlocks.

---

## Approval loop (dev / content pump)

**Locked:** agent **pre-screens** first; **you** give **final approval**. Agents never promote straight to `approved`.

```text
BRIEF / SEED TAGS
     │
     ▼
GENERATE  (image → optional 3D; style lock required)
     │
     ▼
CANDIDATE  (status: pending)  ──►  art under inbox + draft JSON
     │
     ▼
AGENT REVIEW  (vs art bible + schema + readability)
     │
     ├── reject / regenerate  (status: rejected or back to generate)
     │
     ▼
READY FOR YOU  (status: ready_for_review)
     │
     ▼
YOUR FINAL APPROVAL
     │
     ├── reject / request regen
     │
     ▼
APPROVED  (status: approved)  ──►  move into catalog paths, commit / merge
     │
     ▼
COMPILER may place it in worlds
     │
     ▼
PLAYER encounters → learns → collectible unlock (if flagged)
```

Rules:

1. **Pending is not playable.** Worlds never sample `pending`, `ready_for_review`, or `rejected` rows — only `approved`.
2. **Agent first.** Agents generate (concept → **mesh**), `Read` previews, check style lock / schema, and either reject/regenerate or mark `ready_for_review` with short notes (why it passes, known risks).
3. **Mesh before your queue.** `ready_for_review` requires a game-ready **mesh** (not concept-only). Concept stills are fine as steps; they are not enough to hand off.
4. **You approve last.** Final `approved` (and merge into the playable catalog) is a **human** gate. Do not auto-merge agent-passed content.
5. **Git is the ship gate.** Approval means the def + art land on a branch and you merge (or explicitly ask an agent to merge after you say yes).
6. **Style lock always.** Generate with [`art/prompt-lock.md`](art/prompt-lock.md); `style: "anime"`; `Read` previews before import ([`agent-operating-loop.md`](agent-operating-loop.md)).
7. **Pump volume, gate quality.** Prefer many candidates and a strict approve rate over shipping every generation.
8. **Provenance stays on the record** — lock version, prompt/ref ids, agent review notes, your approve time — so a bad batch can be found and retired.

Kenney / `game/art/town/` remains scaffolding only. Catalog finals live under catalog paths below.

---

## On-disk layout (target)

```text
content/catalog/
  buildings/
    <id>.json
  items/
    <id>.json
  props/          # optional non-item world clutter
    <id>.json
  appearance/     # character creator parts (pack 07). Runtime samples approved only.
    bodies/
    maps/
    hair/
    eyes/
    makeup/
    decals/
    features/
    outfits/
  _inbox/         # drafts + pending JSON (not sampled by runtime)
    ...

game/art/catalog/
  buildings/<id>/
  items/<id>/
  props/<id>/
  _inbox/<id>/    # pending previews / meshes until approved

game/art/characters/   # appearance art (bodies, hair, outfits, features) — not Kenney town
```

Exact folder names may tighten in implementation; the split **inbox vs approved** and **def JSON vs art** is locked.

---

## Flexible content record

Buildings (and other kinds) use a **stable core** plus an open **`properties` bag**. Add new fields later inside `properties` (or bump `schema_version` when the core changes) without rewriting every consumer.

```json
{
  "id": "building.lantern_cottage_01",
  "kind": "building",
  "schema_version": 1,
  "status": "ready_for_review",
  "display_name": "Lantern Cottage",
  "tags": ["cottage", "residential", "cozy"],
  "rarity": "common",
  "collectible": {
    "learnable": true,
    "sanctum_buildable": true,
    "learn_verb": "study"
  },
  "art": {
    "thumb": "res://game/art/catalog/buildings/lantern_cottage_01/thumb.png",
    "concept": "res://game/art/catalog/buildings/lantern_cottage_01/concept.png",
    "mesh": "res://game/art/catalog/buildings/lantern_cottage_01/mesh.glb"
  },
  "provenance": {
    "lock_version": 2,
    "generated_at": "2026-09-07T00:00:00Z",
    "agent_reviewed_at": "2026-09-07T00:00:00Z",
    "agent_notes": "Passes style lock; silhouette readable; footprint guess only.",
    "approved_at": null,
    "source": "summer_generate"
  },
  "properties": {
    "footprint_m": { "x": 8, "z": 6 },
    "climbable": true,
    "material_cost": { "wood": 40, "metal": 5, "fiber": 10 },
    "slots": {}
  }
}
```

### Core (keep stable)

| Field | Role |
| --- | --- |
| `id` | Stable catalog id (`kind.name_slug`). Never recycle. |
| `kind` | `building` \| `item` \| `prop` (extend carefully) |
| `schema_version` | Core shape version |
| `status` | `pending` \| `ready_for_review` \| `approved` \| `rejected` \| `retired` |
| `display_name` | Player-facing name |
| `tags` | Soft filters for compiler + UI |
| `rarity` | Placement / drop / collectible weighting |
| `collectible` | Whether/how the player can learn it |
| `art` | Resource paths |
| `provenance` | Generation + approval metadata |
| `properties` | **Open bag** — gameplay knobs added over time |

### `properties` contract

- Unknown keys are **ignored**, not fatal (forward compatible).
- Readers use defaults when a key is missing.
- Do not put identity (`id`, `kind`, `status`) inside `properties`.
- When a property graduates to “everyone must understand it,” either document it as a known key in this note or promote it into core with a `schema_version` bump + migration.

Items use the same envelope (`kind: "item"`) with item-specific `properties` (stack size, hand slots, path affinity hints, etc.) added as we need them — same flexible bag.

---

## World compiler integration

Macro generation does **not** invent mesh paths as free text. It **selects catalog ids** (by tags, rarity, constitution tone) and places **instances**:

```text
catalog id  →  instance { catalog_id, transform, world_entity_id, mutations… }
```

- Prefer deterministic picks from seed + tags ([`03-SEED-ARCHITECTURE.md`](03-SEED-ARCHITECTURE.md)).
- Settlements can be dense: many approved buildings/props sampled into districts.
- Lazy materialization loads art when the player approaches ([`07-LAZY-GENERATION.md`](07-LAZY-GENERATION.md)); the **choice** of catalog id can exist earlier as a compact reference.
- Retiring a catalog row must not delete player unlocks; instances keep the id and fall back to a placeholder mesh if art is gone.

---

## Player learn → collect

If `collectible.learnable` is true:

1. Player encounters an instance in a world.
2. Default learn beat: **Study** — interact with the building (or item, when applicable) to unlock it. Stories may add extra gates; Study is the baseline.
3. Engine writes the catalog `id` into the player’s collection (hub save).
4. If `sanctum_buildable`, the id appears in the Sanctum home-design catalog and uses **this same catalog mesh** when placed ([`game-design.md`](game-design.md)).

Players do **not** receive the entire approved library on New Game. The library is large; **collection** is earned. Starter camp remains the early exception for building. **One active Sanctum instance per design** (lean).

Sanctum build costs use **wood / metal / fiber** only (v0). Put amounts in `properties.material_cost`.

---

## First pump and volume gates

| Lock | Value |
| --- | --- |
| First set | **Log cabin** kit — cozy timber dwellings and related cabin variations |
| Dense placement gate | At least **20 approved buildings** before shipping dense settlement sampling |
| Sanctum buildable art | Same approved mesh as the world instance |
| Handoff fidelity | Mesh required for `ready_for_review` |

---

## Volume targets (intent, not quotas)

- Bias toward a **deep** approved library of buildings and items over unique one-off grayboxes.
- Worlds should feel like they drew from a culture’s architecture kit, not three prefab houses.
- Approval rate can be low; generation rate should stay high.
- After the log-cabin twenty, expand sets (shops, halls, ruins, etc.) the same way.
- **Appearance** (hair, outfits, demi parts, decals) uses the same approve loop and `status` field. Player-facing creator ids live in [`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md); epics: [`epics/07-character-creator-complete.md`](epics/07-character-creator-complete.md). Do not put character parts in `buildings/`.

---

## Explicit non-goals

- Auto-shipping every generation into `approved` without review.
- Letting agents set `status: approved` or merge catalog content without your final say-so.
- Letting in-game directors invent new catalog ids with art at runtime (directors may request tags; content still comes from the catalog).
- Rigid fixed columns for every future building stat (that is what `properties` avoids).
- Using `game/art/town/` Kenney assets as catalog finals.
