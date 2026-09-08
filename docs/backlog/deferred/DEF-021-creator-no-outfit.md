# DEF-021 — Character creator has no outfit category

**Status:** Open  
**Source:** [CC-7](../../epics/02-character-creation.md#cc-7--starting-outfit-cosmetics-deferred) / design lock change (outfit engine)  
**Deferred from:** Pack 02 — starting outfit cosmetics removed from the atelier; clothes are a separate engine  
**Suggested rope-in:** [`epics/08-outfit-engine.md`](../../epics/08-outfit-engine.md)

## Want

Initial character creation customizes **identity only** (race, sex/body, face, demi features). Confirm writes `outfit.id = "none"` so the player spawns on the underwear base. A later **outfit engine** (pack 08) owns wardrobe, fit, occlusion, and dress-up UI.

## Not this ticket

Combat loadout. Cape cloth ([DEF-010](DEF-010-cape-cloth-physics.md)). Wardrobe depth ([DEF-013](DEF-013-outfit-wardrobe-deepen.md) → pack 08).

## Done when

- [x] Creator category rail has no Outfit tab
- [x] Confirm persists `outfit.id = "none"`; loadout stays empty
- [x] Applier skips outfit mesh when id is `none`
- [ ] Pack 08 is the only intended path that writes non-`none` outfit ids for the player
