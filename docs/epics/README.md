# Icarus AI — Execution-order epics

Breaks [`feature-list.md`](../feature-list.md) into implementable epics. Player-facing locks stay in [`game-design.md`](../game-design.md). Art follows [`art-style.md`](../art-style.md) + [`art/prompt-lock.md`](../art/prompt-lock.md).

**Rule:** every epic includes an **Asset generation** section. Systems-only epics still call out chrome, transitions, glyphs, or “no new art — reuse X.” Do not ship a graybox UI as the destination look without naming the replace assets.

**Deferments:** do not leave “later / out of scope / call-forward” only in the epic body. File a ticket under [`../backlog/deferred/`](../backlog/deferred/) with a **Source** link back here, and link that ticket from the epic. Sequenced **next epic packs** in the table below are not deferred tickets — point at the pack. Pack-internal sequencing (“CC-3 owns morphs”) is not a deferment.

**Before implementing any epic/ticket:** review Open items in `docs/backlog/deferred/` and rope in anything that fits the same change. Process: [`../backlog/deferred/README.md`](../backlog/deferred/README.md).

Status: **Planned** → **In progress** → **Playable** → **Done**. Detail docs land before implementation on that slice.

---

## Order (first playable)

| # | Epic pack | Feature-list | Detail | Status |
| --- | --- | --- | --- | --- |
| 1 | **Opening screen** (boot → title) | §1 | [`01-opening-screen.md`](01-opening-screen.md) | Playable |
| 2 | **Character creation** (vertical slice) | §2 | [`02-character-creation.md`](02-character-creation.md) + [`../13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md) | In progress |
| 3 | Empty **Sanctum** + portal | §3 | *TBD* | — |
| 4 | Light parkour (climb + wall run) | MV.* | *TBD* | — |
| 5 | Portal modes + one world round-trip | §4–5 thin | *TBD* | — |

Later packs (after first playable). Do not skip the hub for a compiler demo. Pack 06 is **infra**: ship the island before prompted worlds consume it; do not jump packs 01–05 to build it.

| # | Epic pack | Feature-list | Detail | Status |
| --- | --- | --- | --- | --- |
| 6 | **Agent runtime** (Statemachine + Orchestrator) | Agent runtime (infra); dependency for §4.4 / §8.2 | [`06-agent-runtime.md`](06-agent-runtime.md) + [`../14-AGENT-RUNTIME.md`](../14-AGENT-RUNTIME.md) | Planned |
| — | Combat / Fable XP | §6 | *TBD* | — |
| — | Companions + Sanctum cozy sim | §7 | *TBD* | — |
| — | Worlds / compiler depth + content catalog | §8 | *TBD* | — |

---

## Epic template (required sections)

Use this shape when writing a detail doc:

1. **Outcome** — what the player can do when the epic is playable  
2. **Maps to** — feature-list IDs  
3. **In / out of scope** — out-of-scope deferrals that leave this deliverable link a `DEF-NNN` ticket (or a named later pack)  
4. **Dependencies**  
5. **Work** — scenes, scripts, input, tests  
6. **Asset generation** — what to generate, path, lock, prompt intent, import gate  
7. **Acceptance** — controller + KBM where required; `TEST_RESULT: PASS`; Summer diagnostics after play when MCP is available  
8. **Deferred review** (implementation PRs) — which Open `DEF-*` tickets were checked; which were roped in or skipped  

### Asset generation callout (minimum)

```text
| Asset | Path | Generate when | Notes |
| Title key art | game/art/ui/... | Before wiring final chrome | style "anime"; prepend prompt lock |
```

Import only into `game/art/{characters,hub,worlds,ui,vfx,gear}/`. Keep `_style/` for lock refs. Never use `game/art/town/` as style.
