# DEF-022 — Arrange undo / redo

**Status:** Open  
**Source:** [SH-5 — Arrange mode: flip to top-down](../../epics/03-sanctum-hub.md#sh-5--arrange-mode-flip-to-top-down)  
**Deferred from:** Pack 03 SH-5 — Out of scope  
**Suggested rope-in:** When placement mistakes become painful (many pieces), or with interior editing ([DEF-018](DEF-018-sanctum-interior-rooms.md))

## Want

Undo / redo stack for Arrange: place, move, rotate, remove, and paint strokes. Controller-reachable. Does not rewrite Inhabit. Caps at a sane depth; survives the current session at minimum (persist across quit is optional).

## Not this ticket

Move / remove of the current selection ([SH-6](../../epics/03-sanctum-hub.md#sh-6--shared-placement-ghost-rotate-move-remove)). Title Load of the whole layout ([SH-11](../../epics/03-sanctum-hub.md#sh-11--layout-persistence-and-starter-kit)).

## Done when

- [ ] At least place and remove can undo / redo in one Arrange session
- [ ] Pad + KBM
- [ ] Stack does not corrupt the hub save schema
