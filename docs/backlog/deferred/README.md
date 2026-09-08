# Deferred backlog

When an epic (or implementation PR) **defers** work — out of scope, call-forward, “later,” stubs OK, deepen later — **file a ticket here**. Do not leave the deferment only in the epic body; those notes get forgotten.

Status: **Open** → **Roped in** (linked from an active PR/epic) → **Done** (or **Dropped** with reason).

---

## Agent rules

### On every deferment call

1. Create `docs/backlog/deferred/DEF-NNN-short-slug.md` (next free `NNN`).
2. Fill the [ticket template](#ticket-template): **Source** must link to the epic heading or PR that deferred it.
3. In that epic/PR, replace bare “later” wording with a link: `Deferred: [DEF-NNN](../backlog/deferred/DEF-NNN-….md)`.
4. Do **not** file a deferred ticket for work that is already the **next named epic pack** in [`../../epics/README.md`](../../epics/README.md) (e.g. “hub is pack 03”). Point at that pack instead.
5. Do **not** file tickets for pack-internal sequencing (“CC-3 owns morphs” inside pack 02). Only deferrals that leave the current deliverable cold.

### When starting any ticket / epic / implementation slice

1. List `docs/backlog/deferred/` (Open tickets).
2. Pull in any item whose **Suggested rope-in** matches the work you are about to do — same scene, same systems, same art pass.
3. If you rope it in: mark the ticket **Roped in**, link the PR/epic, and complete or re-defer with a new note before merge.
4. If nothing applies, say so briefly in the PR (“Deferred review: none roped in”).

---

## Index (keep sorted by ID)

| ID | Title | Status | Source |
| --- | --- | --- | --- |
| [DEF-001](DEF-001-boot-title-audio.md) | Boot / title final audio mix | Open | [OS-1](../../epics/01-opening-screen.md#os-1--boot-and-loading-screen) |
| [DEF-002](DEF-002-settings-persistence.md) | Settings persistence | Open | [OS-2](../../epics/01-opening-screen.md#os-2--title-menu-shell) / [OS-3](../../epics/01-opening-screen.md#os-3--settings-shell) |
| [DEF-003](DEF-003-controls-rebind.md) | Full controls rebind UI | Open | [OS-3](../../epics/01-opening-screen.md#os-3--settings-shell) / [OS-6](../../epics/01-opening-screen.md#os-6--controller-from-boot) / [CC-9](../../epics/02-character-creation.md#cc-9--creator-on-controller) |
| [DEF-004](DEF-004-load-browser-polish.md) | Load shell multi-slot browser + previews | Open | [OS-4](../../epics/01-opening-screen.md#os-4--load-shell) |
| [DEF-005](DEF-005-millbrook-save-migration.md) | Millbrook town save → hub/character save migration | Open | [OS-4](../../epics/01-opening-screen.md#os-4--load-shell) |
| [DEF-006](DEF-006-creator-stub-art-retirement.md) | Retire OS-5 creator stub backdrop when atelier ships | Done | [OS-5](../../epics/01-opening-screen.md#os-5--new--creator-handoff) / [CC-1](../../epics/02-character-creation.md#cc-1--creator-atelier-shell) |
| [DEF-007](DEF-007-creator-draft-save.md) | Optional creator draft save before confirm | Roped in | [CC pack](../../epics/02-character-creation.md#summer-play-acceptance-pack-level) → [CX-9](../../epics/07-character-creator-complete.md#cx-9--atelier-studio-ux) |
| [DEF-008](DEF-008-race-tag-story-reactions.md) | Story / dialogue reactions consume race tag | Open | [CC-2](../../epics/02-character-creation.md#cc-2--race-select-preset-and-tag) |
| [DEF-009](DEF-009-extreme-morph-anim-retarget.md) | Animation retarget for extreme body morphs | Open | [CC-3](../../epics/02-character-creation.md#cc-3--body-core-height-weight-proportions-muscle--fat) |
| [DEF-010](DEF-010-cape-cloth-physics.md) | Cape / outfit cloth physics final | Open | [CC-4](../../epics/02-character-creation.md#cc-4--soft-body--jiggle-from-muscle--fat) / [CC-7](../../epics/02-character-creation.md#cc-7--starting-outfit-cosmetics) |
| [DEF-011](DEF-011-face-catalog-deepen.md) | Face / hair / eyes catalog + makeup deepen | Roped in | [CC-5](../../epics/02-character-creation.md#cc-5--face--hair--eyes--scars-kit) → [CX-4](../../epics/07-character-creator-complete.md#cx-4--face-morph-complete) / [CX-5](../../epics/07-character-creator-complete.md#cx-5--hair-eyes-makeup) |
| [DEF-012](DEF-012-demi-feature-catalog-deepen.md) | Demi-human feature catalog deepen | Roped in | [CC-6](../../epics/02-character-creation.md#cc-6--demi-human-features) → [CX-7](../../epics/07-character-creator-complete.md#cx-7--demi-human-catalog-complete) |
| [DEF-013](DEF-013-outfit-wardrobe-deepen.md) | Outfit wardrobe / transmog deepen | Open | [CC-7](../../epics/02-character-creation.md#cc-7--starting-outfit-cosmetics-deferred) → [`08-outfit-engine.md`](../../epics/08-outfit-engine.md) (was CX-8) |
| [DEF-014](DEF-014-body-proportion-deepen.md) | Body proportion region deepen beyond vertical slice | Roped in | [CC-3](../../epics/02-character-creation.md#cc-3--body-core-height-weight-proportions-muscle--fat) → [CX-3](../../epics/07-character-creator-complete.md#cx-3--body-regions-code-vein-class) |
| [DEF-015](DEF-015-load-continue-after-creator.md) | Title Load / Continue of creator-written saves | Open | [CC-8](../../epics/02-character-creation.md#cc-8--confirm--write-character--hub-spawn-handoff) |
| [DEF-016](DEF-016-multiplayer-worker-routing.md) | Multiplayer worker advertisement + remote `complete()` | Open | [AR-2](../../epics/06-agent-runtime.md#ar-2--orchestrator) |
| [DEF-017](DEF-017-player2-voice.md) | Player2 TTS / STT voice adapter | Open | [AR-4](../../epics/06-agent-runtime.md#ar-4--player2-worker) |
| [DEF-018](DEF-018-demi-wings-scales.md) | Demi-human wings and full-body scales | Open | [CX-7](../../epics/07-character-creator-complete.md#cx-7--demi-human-catalog-complete) |
| [DEF-019](DEF-019-gameplay-face-anim.md) | Gameplay face animation (visemes / cinematic) | Open | [CX-4](../../epics/07-character-creator-complete.md#cx-4--face-morph-complete) |
| [DEF-020](DEF-020-hair-cloth-secondary-motion.md) | Hair / cloth secondary motion | Open | [CX-5](../../epics/07-character-creator-complete.md#cx-5--hair-eyes-makeup) |
| [DEF-021](DEF-021-creator-no-outfit.md) | Character creator has no outfit category | Open | [CC-7](../../epics/02-character-creation.md#cc-7--starting-outfit-cosmetics-deferred) → [`08-outfit-engine.md`](../../epics/08-outfit-engine.md) |

---

## Ticket template

```markdown
# DEF-NNN — Short title

**Status:** Open
**Source:** [Epic heading](../../epics/….md#anchor)
**Deferred from:** Pack / epic ID — section (Out of scope | Call-forward | notes)
**Suggested rope-in:** When …

## Want

Player- or agent-facing outcome when this is done.

## Not this ticket

Anything that belongs to a named later epic pack (link it).

## Done when

- [ ] …
```
