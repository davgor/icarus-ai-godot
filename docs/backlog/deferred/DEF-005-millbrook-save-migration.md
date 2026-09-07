# DEF-005 — Millbrook town save → hub/character save migration

**Status:** Open  
**Source:** [OS-4 — Load shell](../../epics/01-opening-screen.md#os-4--load-shell)  
**Deferred from:** Pack 01 / OS-4 — Out of scope  
**Suggested rope-in:** When hub/character schema replaces `user://living_town_v1.json` as the intended continue path

## Want

Either a one-shot migrator from the Living Town prototype save into the destination character/hub schema, or an explicit “unsupported / start New” path so old files never silently corrupt new saves.

## Not this ticket

Keeping Millbrook as the player hub (it is not).

## Done when

- [ ] Policy documented and implemented (migrate **or** clear refuse)
- [ ] Tests cover the chosen policy
