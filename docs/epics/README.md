# Icarus AI — Execution-order epics

Breaks [`feature-list.md`](../feature-list.md) into implementable epics. Player-facing locks stay in [`game-design.md`](../game-design.md). Art follows [`art-style.md`](../art-style.md) + [`art/prompt-lock.md`](../art/prompt-lock.md).

**Rule:** every epic includes an **Asset generation** section. Systems-only epics still call out chrome, transitions, glyphs, or “no new art — reuse X.” Do not ship a graybox UI as the destination look without naming the replace assets.

Status: **Planned** → **In progress** → **Playable** → **Done**. Detail docs land before implementation on that slice.

---

## Order (first playable)

| # | Epic pack | Feature-list | Detail | Status |
| --- | --- | --- | --- | --- |
| 1 | **Opening screen** (boot → title) | §1 | [`01-opening-screen.md`](01-opening-screen.md) | Planned |
| 2 | Character creation (vertical slice) | §2 | *TBD* | — |
| 3 | Empty hub village + portal | §3 | *TBD* | — |
| 4 | Light parkour (climb + wall run) | MV.* | *TBD* | — |
| 5 | Portal modes + one world round-trip | §4–5 thin | *TBD* | — |

Later packs (after first playable): combat / Fable XP (§6), companions + living hub (§7), worlds / compiler depth (§8). Do not skip the hub for a compiler demo.

---

## Epic template (required sections)

Use this shape when writing a detail doc:

1. **Outcome** — what the player can do when the epic is playable  
2. **Maps to** — feature-list IDs  
3. **In / out of scope**  
4. **Dependencies**  
5. **Work** — scenes, scripts, input, tests  
6. **Asset generation** — what to generate, path, lock, prompt intent, import gate  
7. **Acceptance** — controller + KBM where required; `TEST_RESULT: PASS`; Summer diagnostics after play when MCP is available  

### Asset generation callout (minimum)

```text
| Asset | Path | Generate when | Notes |
| Title key art | game/art/ui/... | Before wiring final chrome | style "anime"; prepend prompt lock |
```

Import only into `game/art/{characters,hub,worlds,ui,vfx,gear}/`. Keep `_style/` for lock refs. Never use `game/art/town/` as style.
