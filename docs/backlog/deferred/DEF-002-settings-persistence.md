# DEF-002 — Settings persistence

**Status:** Open  
**Source:** [OS-2](../../epics/01-opening-screen.md#os-2--title-menu-shell) / [OS-3 — Settings shell](../../epics/01-opening-screen.md#os-3--settings-shell)  
**Deferred from:** Pack 01 — OS-2/OS-3 Out of scope (placeholders OK)  
**Suggested rope-in:** When Settings leaves placeholder mode, or when first shipping a playable build players relaunch

## Want

Audio / graphics / controls choices survive quit and relaunch. Engine-owned config; no LLM.

## Not this ticket

Cloud sync. Full rebind UX ([DEF-003](DEF-003-controls-rebind.md)).

## Done when

- [ ] Settings write/read a versioned user config
- [ ] Relaunch restores last applied values
- [ ] Headless tests cover round-trip without hanging
