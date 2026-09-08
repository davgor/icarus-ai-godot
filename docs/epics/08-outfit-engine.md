# Epic pack 08 — Outfit engine

**Status:** Planned  
**Feature-list:** [`feature-list.md`](../feature-list.md) §5 Outfit layer (5.5+) and creator cosmetics moved out of §2  
**Design:** [`game-design.md`](../game-design.md) Gear and appearance (outfit ≠ loadout)  
**Tech contract:** [`../13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) — outfit slots, occlusion, pieces, colors (schema fields stay on `CharacterRecord.outfit`)  
**Art:** [`art-style.md`](../art-style.md), [`art/prompt-lock.md`](../art/prompt-lock.md)  
**Import roots:** `game/art/characters/` (outfit meshes), `game/art/ui/` (dress-up chrome), `content/catalog/appearance/outfits/`  
**Operating loop:** [`agent-operating-loop.md`](../agent-operating-loop.md)  
**Depends on:** Pack 02 Playable (body kits + shared applier). Prefer hub (pack 03) before Sanctum dress-up UI; assembler stages from pack 07 help fit/occlusion but are not a hard gate for a thin first outfit pass.

The **character creator does not own clothes.** Pack 02 Confirm writes `outfit.id = "none"` (underwear base only). This pack is the separate **outfit engine**: wardrobe, fit, occlusion, colors, and a dress-up UI (hub first; worlds later).

Roped-in tickets: [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md) (was CX-8), [`DEF-021`](../backlog/deferred/DEF-021-creator-no-outfit.md) (strip from creator — done when this pack is the only writer of non-`none` outfits). Cape cloth remains [`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md).

---

## Shared locks

- **Outfit ≠ loadout.** Cosmetics never fill weapon/armor/accessory combat slots.
- **Underwear until dressed.** Creator and fresh Confirm leave `outfit.id = "none"`. Applier shows the Male/Female underwear kit with no outfit mesh.
- **Same applier.** Outfit pieces still go through `AppearanceApplier.apply` stages (slots → occlusion → materials). Do not invent a second appearance JSON.
- All cosmetic outfits stay **unlocked** unless a later economy pack explicitly changes that (default: unlocked).
- Image `style` is **`"anime"`**. Prepend prompt-lock.

---

## Suggested ship order

1. **OE-1** — Outfit record + catalog (`none` + wardrobe ids); applier applies pieces when not `none`
2. **OE-2** — Hub (or stub) dress-up UI: pick look / pieces / colors; pad-first
3. **OE-3** — Fit + occlusion on closed garments (ropes [`DEF-013`](../backlog/deferred/DEF-013-outfit-wardrobe-deepen.md))
4. **OE-4** — Companion dress uses the same engine
5. **OE-5** — Persist outfit with character save; travel rule with loadout (feature-list 5.7–5.9)

Detail tickets land before implementation on each OE id (same shape as CC/CX epics).

---

## Pack-level definition of done

1. Creator still has **no** Outfit category; Confirm still defaults to `none`.
2. Player can change outfit in the outfit engine UI without touching loadout.
3. Wardrobe minimums and occlusion meet the appearance contract destination table (or a documented thin first ship).
4. Outfit≠loadout tested.
5. `.\scripts\test.ps1` prints `TEST_RESULT: PASS`.

**Not required here:** combat gear UI, cape cloth final ([`DEF-010`](../backlog/deferred/DEF-010-cape-cloth-physics.md)), creator makeup/decals (pack 07).

---

## Implementation notes

- Do not re-add Outfit to the character atelier category rail.
- Keep semantic `outfit` on `CharacterRecord`; catalog owns mesh/occlusion maps.
- Starter outfit GLBs under `game/art/characters/outfit_*` may be reused when OE-1 lands — they are not wired in the creator.
