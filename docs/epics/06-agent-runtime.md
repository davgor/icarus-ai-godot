# Epic pack 06 — Agent runtime

**Status:** Planned  
**Feature-list:** [`feature-list.md`](../feature-list.md) Agent runtime (infra) + dependency for §4.4 / §8.2  
**Design:** [`game-design.md`](../game-design.md) — engine owns state; prompted worlds and NPC cognition are untrusted until committed  
**Contract:** [`../14-AGENT-RUNTIME.md`](../14-AGENT-RUNTIME.md) — Statemachine + Orchestrator  
**Related:** [`../04-SIMULATION.md`](../04-SIMULATION.md), [`../06-AGENT-ARCHITECTURE.md`](../06-AGENT-ARCHITECTURE.md), [`../08-PERSISTENCE.md`](../08-PERSISTENCE.md)  
**Art:** [`art-style.md`](../art-style.md), [`art/prompt-lock.md`](../art/prompt-lock.md) — reuse OS-3 settings chrome; no new world art  
**Import root:** `game/art/ui/` (settings glyphs only)  
**Operating loop:** [`agent-operating-loop.md`](../agent-operating-loop.md)

**Do not skip first playable for this pack.** Opening, creator, Sanctum, parkour, and a thin portal round-trip stay packs 01–05. This pack is the cognition **island**: testable without a portal compiler, required before prompted worlds and NPC thought.

Suggested ship order: **AR-1 → AR-2 → AR-3 → AR-4 / AR-5 (parallel after AR-3) → AR-6**.

---

## Shared locks (all AR epics)

- **Statemachine owns truth.** If it is not committed there, it did not happen. LLM output is untrusted input.
- **AI off is a complete game.** Zero healthy workers must not block boot, title, Sanctum, combat, or saves.
- Jobs never `HTTPRequest` a model. They enqueue a `WorkItem` on the **Orchestrator**.
- Workers only `complete(messages, tools) → CompletionResult`. They never mutate saves.
- Routing is a **score** (requirements × urgency × offer), not `SteamDeck => chat_only`. Weak devices may still take heavy jobs when that is the least-bad wait.
- Blessed local worker: **Ollama** at `http://127.0.0.1:11434/v1`. Player2 at `http://127.0.0.1:4315/v1` is optional. Custom OpenAI-compat URL is the escape hatch.
- Do **not** vendor `Player2AINPC`, Player2 cloud `Data`, or a managed llama.cpp runtime in Godot.
- Do **not** add Summer SDK or editor-only APIs to shipped game code.
- Headless tests: `tests/run_tests.gd` (`extends SceneTree`), gate on `TEST_RESULT: PASS`. Mock workers; no live HTTP in CI.
- Canonical commands: `.\scripts\test.ps1` after logic; Summer play/diagnostics when Settings UI lands; `.\scripts\build.ps1` / `.\scripts\play.ps1` when the slice should be playable.
- Controller is first-class for AR-5 Settings. Keyboard/mouse in parallel.

---

## AR-1 — Statemachine

### Outcome

A single in-engine owner saves the game, serves grounded snapshots, and is the only path that commits tool-shaped mutations. Gameplay runs with no LLM.

### Maps to

| ID | Feature |
| --- | --- |
| AR.1 | Statemachine |
| 0 | Engine owns state; LLM is untrusted input |

### In scope

- Grow a Statemachine API out of (or beside) `game/sim/game_state.gd` without treating Millbrook as the Sanctum
- Save / load versioned state ([`08-PERSISTENCE.md`](../08-PERSISTENCE.md) direction; destination schema can stay thin)
- `serve_snapshot(scope)` for Orchestrator prep — not the raw save file
- `commit(tool_name, args)` with schema reject (unknown tool, bad types, illegal catalog ids)
- Tests: round-trip save; reject invalid commit; snapshot omits out-of-scope secrets

### Out of scope

- Portal compiler / prompted worlds (pack 05 / §8)
- Multiplayer host migration — Deferred: [`DEF-016`](../backlog/deferred/DEF-016-multiplayer-worker-routing.md)
- Millbrook → Sanctum save conversion — [`DEF-005`](../backlog/deferred/DEF-005-millbrook-save-migration.md)

### Dependencies

- None from later AR epics. Persistence lessons from OS-4 / CC-8 if those already write a character record.

### Work

- `game/ai/state_machine.gd` (or equivalent name under `game/simulation/` if that layout has started)
- Thin tool registry used only for validation in this epic (full catalogs in AR-6)
- Headless tests in `tests/run_tests.gd`

### Asset generation

No new art. Statemachine has no player-facing chrome. Reuse existing save paths; do not invent a debug HUD as destination UI.

| Asset | Path | Generate when | Notes |
| --- | --- | --- | --- |
| *(none)* | — | — | No new art — reuse nothing visible |

### Acceptance

- [ ] Invalid tool commits are rejected; state unchanged
- [ ] Snapshot serve does not hand the worker a full save blob
- [ ] Save/load round-trip in headless tests
- [ ] `TEST_RESULT: PASS`
- [ ] AI-off: existing play path still works (no Orchestrator required)

---

## AR-2 — Orchestrator

### Outcome

Jobs enter a queue. The Orchestrator inventories **host** workers (mocks first), scores WorkItems by requirements and urgency, and assigns a worker. A busy fast mock can lose a *blocking* job to a slow idle mock.

### Maps to

| ID | Feature |
| --- | --- |
| AR.2 | Orchestrator |

### In scope

- `WorkItem` shape per [`14-AGENT-RUNTIME.md`](../14-AGENT-RUNTIME.md)
- Queue + per-worker serial + cross-worker parallel
- Score: requirements × urgency (`blocking` / `interactive` / `background`) × offer (latency, load, health)
- Sticky affinity for multi-step jobs; typed fail + re-queue if the worker dies
- Stale snapshot: re-prep from Statemachine or drop
- Mock workers only (no HTTP)

### Out of scope

- Peer advertisement over Steam / Godot net — Deferred: [`DEF-016`](../backlog/deferred/DEF-016-multiplayer-worker-routing.md)
- Real Ollama/Player2 (AR-3 / AR-4)
- Preempting in-flight completions (explicitly never)

### Dependencies

- AR-1 (prep/re-ground)

### Work

- `game/ai/orchestrator.gd`, `work_item.gd`, `worker.gd`, `mock_worker.gd`
- Tests:
  - blocking worldgen lands on a slow Deck-shaped mock when the 5080-shaped mock is busy
  - background job waits rather than hitching the Deck mock when a better worker will free
  - Player2-shaped mock can win when it scores best
  - zero workers → enqueue no-ops / expire; Statemachine still runs
  - sticky affinity; worker death does not commit a partial tool batch

### Asset generation

No destination art. Optional **debug-only** text overlay is allowed in a debug build; it is not the Settings UI (AR-5).

| Asset | Path | Generate when | Notes |
| --- | --- | --- | --- |
| *(none)* | — | — | No new art — debug text OK; do not ship a graybox operator HUD as UI |

### Acceptance

- [ ] Score tests above are headless and deterministic
- [ ] Weak-device mock **can** receive heavy work; it is not a hard ban
- [ ] `TEST_RESULT: PASS`

---

## AR-3 — Decoder + local workers (Ollama / custom URL)

### Outcome

A worker adapter speaks OpenAI-compat chat completions, decodes tool calls through the three-layer stack, and plugs into the Orchestrator as a host worker. CI still uses mocks.

### Maps to

| ID | Feature |
| --- | --- |
| AR.3 | Local workers (Ollama + custom OpenAI-compat) |

### In scope

- `LlmClient` / HTTP worker: `POST {base}/v1/chat/completions`
- Probe: `GET {base}/v1/models` (Ollama default `http://127.0.0.1:11434`)
- Decoder: native `tool_calls` → constrained JSON → prompted JSON + repair; truncation (`finish_reason == length`) is a typed fail, not a stump commit
- Serial per worker
- Custom base URL + model id
- Fixture tests for each decode layer (recorded JSON, no network)

### Out of scope

- Managed llama.cpp download/lifecycle (do not build)
- Player2 quirks (AR-4)
- Live Ollama as a CI gate (optional local smoke only)

### Dependencies

- AR-2 worker interface

### Work

- `game/ai/llm_client.gd` (or split decode vs HTTP)
- Decode fixtures under `tests/`
- Document reference model in Settings copy later (AR-5): Qwen2.5-Instruct 7B/14B Q4 as a *recommendation*, not a hard dependency

### Asset generation

No new art.

| Asset | Path | Generate when | Notes |
| --- | --- | --- | --- |
| *(none)* | — | — | No new art — reuse OS-3 settings chrome in AR-5 |

### Acceptance

- [ ] Fixture: native tool_calls, fenced JSON, doubled JSON, truncation
- [ ] Unreachable localhost is a typed error, not a Statemachine mutation
- [ ] `TEST_RESULT: PASS` without a running Ollama

---

## AR-4 — Player2 worker (optional)

### Outcome

If the Player2 app is up, it is a scored host worker. If it is down, play continues. Native `tools` on `:4315/v1/chat/completions` is spiked and recorded; fallback is decoder layers 2–3.

### Maps to

| ID | Feature |
| --- | --- |
| AR.4 | Player2 worker |

### In scope

- Adapter on the shared OpenAI-compat client
- Probe `GET http://127.0.0.1:4315/v1/models`
- Typed unreachable vs HTTP error; error bodies may be **plain text** (TTRPG research)
- Game key / `player2-game-key` header if required by current Player2 local API — document in-epic when spiked
- Spike: one `tools` array request; write the result into this epic or `docs/research/` (native vs JSON-only)
- Settings copy may link `https://player2.game` — must not block play

### Out of scope

- Official Godot `Player2AINPC` node / cloud user-data storage (do not vendor)
- TTS / STT — Deferred: [`DEF-017`](../backlog/deferred/DEF-017-player2-voice.md)
- Using Player2 as the Statemachine (saves stay ours)

### Dependencies

- AR-3 client/decoder

### Work

- `create_player2_worker` (or equivalent) + fixtures for plain-text errors
- Spike notes committed with the implementation PR (not a blocker for planning this pack)

### Asset generation

No new art. Optional small “Player2 connected” glyph in AR-5.

| Asset | Path | Generate when | Notes |
| --- | --- | --- | --- |
| Optional status glyph | `game/art/ui/worker_player2.png` | With AR-5 if needed | Tiny dark-jewel status mark; **no** Player2 logo recreation if that fights the lock; prefer generic “cloud-app up” shard |

### Acceptance

- [ ] Player2 down → worker unhealthy; Orchestrator uses others or AI-off
- [ ] Spike result recorded (native tools or JSON fallback)
- [ ] `TEST_RESULT: PASS` without Player2 running

---

## AR-5 — Settings: worker inventory

### Outcome

Settings can enable/disable host workers (Ollama, Player2, custom URL), test a connection, and turn AI off. Usable on a gamepad. Default is AI off until the player enables a worker.

### Maps to

| ID | Feature |
| --- | --- |
| AR.5 | AI settings (workers, test connection, off) |
| 1.4 | Settings shell (extends the fourth title button; does not replace audio/graphics/controls) |

### In scope

- Worker list on the Settings surface (new page or section under OS-3)
- Per worker: enable, base URL (advanced), model id, test connection
- Orchestrator reads this inventory; no global “one provider” enum
- Persist worker config in engine-owned user config (separate from save slots)
- Controller: focus, enable, test, back — no mouse-cursor overlay as the pad path

### Out of scope

- Audio / graphics / controls persistence — [`DEF-002`](../backlog/deferred/DEF-002-settings-persistence.md) (rope in if the same config file is the natural home)
- Full rebind UI — [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md)
- Advertising this machine’s workers to peers — Deferred: [`DEF-016`](../backlog/deferred/DEF-016-multiplayer-worker-routing.md)
- Accessibility extras beyond this page (still an open design question)

### Dependencies

- OS-3 Settings shell (or a stub page if pack 01 is not Playable yet — do not invent a second title)
- AR-2 / AR-3 for test-connection to mean a real probe

### Work

- Settings section + user config keys
- Test-connection uses AR-3/AR-4 probes
- Tests: parse config; AI-off with empty inventory; pad smoke when MCP available

### Asset generation

Reuse OS-3 settings chrome. Generate only if that chrome does not exist yet or this page needs a distinct icon.

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Settings “AI / workers” tab glyph | `game/art/ui/settings_ai_glyph.png` | With the page | Small mystical shard / constellation icon; dark jewel; readable at tab scale; **no** readable letters |
| Connection OK / fail marks | `game/art/ui/worker_status.png` (atlas) | With the page | Two tiny status pips (ok / fail); sparse emissive; not sci-fi HUD soup |

**Pipeline:** prepend lock → `style: "anime"` → generate → import under `game/art/ui/`. If OS-3 already has matching glyphs, **reuse** — do not duplicate.

### Acceptance

- [ ] Pad can open Settings, toggle a worker, run test connection, back to title
- [ ] Default inventory empty / AI off does not block play
- [ ] Ollama and Player2 can both be enabled at once
- [ ] Art under `game/art/ui/` or explicitly reused from OS-3
- [ ] Tests + diagnostics when MCP available

---

## AR-6 — Job catalogs + host tool loop

### Outcome

The host runs the boring loop: complete → Statemachine commit/reject → observation → complete again, with caps. WorldDirector / Dialogue catalogs exist as schemas and mock-driven tests. Portal UI is **not** this epic.

### Maps to

| ID | Feature |
| --- | --- |
| AR.6 | Tool jobs (catalogs + host loop) |
| 4.4 / 8.2 | Dependency only — prompted / agentic story consume this later |

### In scope

- Host loop with step/tool/time caps
- Catalogs (names + JSON Schema + permissions), ~4–12 tools each:
  - WorldDirector: `propose_region`, `propose_faction`, `propose_npc_sheet`, `propose_story_beats`
  - Dialogue: `say`, `offer_topic`, `set_disposition_intent`, `remember_fact`
- Companion / StoryBeat catalogs may be **empty stubs** with reserved ids
- Appearance proposals must be creator-legal ([`13-CHARACTER-APPEARANCE.md`](../13-CHARACTER-APPEARANCE.md))
- Tests with mock workers: valid propose commits; illegal morph rejected; speech-only does not mutate world

### Out of scope

- Portal choice UI, compiler screen, world round-trip (pack 05)
- Live NPC cognition in the Sanctum (later companions / [`05-NPC-COGNITION.md`](../05-NPC-COGNITION.md))
- Content-catalog generate→approve ([`12-CONTENT-CATALOG.md`](../12-CONTENT-CATALOG.md))

### Dependencies

- AR-1 + AR-2; AR-3 optional (mocks sufficient)

### Work

- Catalog resources / GDScript registries
- Loop owner next to Orchestrator (Orchestrator assigns; loop talks to Statemachine)
- Tests as above

### Asset generation

No new art. First player-facing use will generate compiler/portal chrome in pack 05.

| Asset | Path | Generate when | Notes |
| --- | --- | --- | --- |
| *(none)* | — | — | No new art — pack 05 owns portal / compiler visuals |

### Acceptance

- [ ] Mock WorldDirector job commits only validated structs
- [ ] Speech-only CompletionResult leaves Statemachine unchanged
- [ ] Loop hits caps and stops
- [ ] `TEST_RESULT: PASS`
- [ ] No portal scene required

---

## Pack-level definition of done

This pack is **Playable** (as infra) when:

1. Statemachine saves, serves, commits/rejects without an LLM.
2. Orchestrator scores host workers; weak-device overflow is tested, not banned.
3. Ollama/custom decoder exists; CI stays mock/fixture-based.
4. Player2 is optional and never required to boot.
5. Settings can enable workers on a gamepad, or the inventory is test-configurable until OS-3 exists.
6. WorldDirector/Dialogue catalogs run through the host loop in headless tests.
7. `.\scripts\test.ps1` prints `TEST_RESULT: PASS`.

**Not required for this pack:** Sanctum destination art, portal compiler, companions, combat, multiplayer, voice, live Ollama in CI.

---

## Implementation notes for agents

- Prefer the island under `game/ai/` (or `game/simulation/` + `game/ai/` workers) over stuffing HTTP into `game/main.gd`.
- Do not call Summer MCP APIs from runtime cognition.
- Before implementing: review [`../backlog/deferred/`](../backlog/deferred/) Open tickets. Rope [`DEF-002`](../backlog/deferred/DEF-002-settings-persistence.md) if AR-5 shares the settings config file. Multiplayer and voice stay deferred.
- When pack 05 (portal) starts, it **consumes** AR-6; it does not invent a second LLM client.
