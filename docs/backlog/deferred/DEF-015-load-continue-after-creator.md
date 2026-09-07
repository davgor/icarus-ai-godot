# DEF-015 — Title Load / Continue of creator-written saves

**Status:** Open  
**Source:** [CC-8 — Confirm → write character → hub spawn handoff](../../epics/02-character-creation.md#cc-8--confirm--write-character--hub-spawn-handoff)  
**Deferred from:** Pack 02 / CC-8 — Out of scope (OS-4 empty state may remain until persistence)  
**Suggested rope-in:** With character/hub save schema + [DEF-004](DEF-004-load-browser-polish.md); after CC-8 writes a real record

## Want

After Confirm writes a character, Title **Load** can resume that save (appearance, race tag, outfit) into the hub path. Empty state only when no saves exist.

## Not this ticket

World Continue through the portal (later packs). Millbrook migration ([DEF-005](DEF-005-millbrook-save-migration.md)).

## Done when

- [ ] At least one creator-written save round-trips via Load
- [ ] Pad path works
- [ ] Tests cover missing vs present saves
