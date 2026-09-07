# 14 — Agent runtime

Two lightweight roles run the game’s cognition path. Clients, scenes, Ollama, and Player2 hang off them. Single-player: both live on this machine. Multiplayer later: same objects; peers only advertise workers.

This is **in-game** runtime. Cursor and Summer stay development agents ([`10-AI-DEVELOPMENT-WORKFLOW.md`](10-AI-DEVELOPMENT-WORKFLOW.md)). Director *kinds* (World / Regional / Settlement / NPC) still live in [`06-AGENT-ARCHITECTURE.md`](06-AGENT-ARCHITECTURE.md). They submit work; they do not HTTP a model.

Epics: [`epics/06-agent-runtime.md`](epics/06-agent-runtime.md). Player-facing locks stay in [`game-design.md`](game-design.md). Simulation vs cognition: [`04-SIMULATION.md`](04-SIMULATION.md).

```text
Play clients
      │
      ▼
STATEMACHINE     save · serve snapshots · commit tools
      │ grounded snapshot
      ▼
ORCHESTRATOR     inventory · queue · score (requirements × urgency × offer)
      │ WorkItem
      ▼
WORKERS          complete(messages, tools) → CompletionResult
                 (host Ollama / Player2 / custom URL / later a peer)
      │
      ▼
ORCHESTRATOR     host tool loop (step caps)
      │ validated tool calls
      ▼
STATEMACHINE     apply or reject · persist
```

Gameplay **must** run with zero healthy workers (AI off).

---

## Statemachine

Full owner of world state. If it is not in the Statemachine, it did not happen.

- **Save** — persistence is a Statemachine job, not a side effect of an LLM reply ([`08-PERSISTENCE.md`](08-PERSISTENCE.md)).
- **Serve** — grounded snapshots for prep (who is here, portal prompt, trust, inventory). Workers never receive the raw save to “think with.”
- **Commit** — schema-validated tool results. Reject invalid args, unknown catalog ids, out-of-range morphs ([`13-CHARACTER-APPEARANCE.md`](13-CHARACTER-APPEARANCE.md)).
- **Simulate** — deterministic ticks. Grow out of `game/sim/game_state.gd`; do not grow Millbrook as if it were the Sanctum.

Clients (including a Steam Deck) play against the Statemachine. They are not a second sim.

In-engine first (Godot class / autoload). Extractable later if a dedicated host process exists. Not a cloud service we run.

---

## Orchestrator

Looks at resources it can use: **this host** (Ollama, Player2, CPU/GPU headroom) **and**, later, workers advertised on the multiplayer connection. Then it routes.

Jobs submit `WorkItem`s. They do not pick a GPU.

Routing is a **score**, not a permission list:

- **Requirements** — tools vs speech, estimated tokens, quality bar, whether the job can wait, whether remote is allowed.
- **Urgency** — `blocking` (portal UI), `interactive` (dialogue), `background` (idle companion thought).
- **Offer** — advertised throughput, load, estimated latency for this class, health, VRAM/thermal, RTT if remote.

Pick the worker that minimizes player pain for that urgency, not the fattest GPU in the abstract. A busy 5080 that starts in 40s can lose to an idle Steam Deck that finishes in 90s if the player is blocked *now* — or win if a background thought can wait. Player2 is another scored worker, not a hardcoded overflow flag.

Hard filters only for impossibilities: worker down, protocol mismatch, job forbids remote and the worker is a peer. **Do not** encode `SteamDeck => chat_only`. A weak device is a worse worker, not an illegal one.

Do not preempt an in-flight completion. Re-score the wait list when a worker frees or a higher-urgency item arrives.

**Sticky affinity:** later `complete()` steps of the same job stay on the worker that started it. If that worker dies, fail typed, re-ground from the Statemachine, Orchestrator picks again.

`WorkItem` (prep output, not a chat log):

```text
id, purpose
urgency: blocking | interactive | background
requires: { tools, est_tokens, min_quality, allow_remote, allow_player2 }
catalog: WorldDirector | Dialogue | Companion | StoryBeat
payload: Statemachine snapshot + messages seed
timeout, retry_budget
```

Prep asks the Statemachine. If the item sits until the snapshot is stale, prep again or drop.

Worker advertisement:

```text
worker_id, owner_peer
endpoint_kind: ollama | player2 | openai_compat | mock
est_latency_by_class, est_quality_by_class
healthy, load, vram_headroom
```

Serial **per worker**. Cross-worker parallel is allowed (Player2 chatting while Ollama worldgens).

---

## Workers and tool decode

Blessed local path: **Ollama** (`http://127.0.0.1:11434/v1`). Player2 (`http://127.0.0.1:4315/v1`) is optional. Custom OpenAI-compat URL is the escape hatch (LM Studio, llama.cpp server). Do not ship a managed llama.cpp runtime inside Godot.

Workers only implement `complete(messages, tools) -> CompletionResult`. They do not mutate the world.

```text
CompletionResult
  text: String          # flavor; never authoritative
  tool_calls: Array     # name + JSON args + id
  finish_reason
```

Decode in order: native `tool_calls` → constrained JSON → prompted JSON + repair. Reject, retry once, then the job no-ops. Treat Player2 native-tools support as unknown until the AR-4 spike.

Host loop: cap steps and tools; wall-clock timeout. Observations come from Statemachine commit, not from the model restating the world.

Job-scoped catalogs (~4–12 tools). Prose is a side channel: if the model only talks, the world does not change.

---

## VRAM

A 7B on GPU fights Forward Plus. Cognition is async / batched — portal gen, hub return, talk — not combat ticks. The Orchestrator may send work off the machine that is rendering. Sending heavy work *to* a Deck is allowed when the score says so; urgency is how we price hitch and heat.

---

## Do not

- Vendor the Player2 Godot NPC plugin (`Player2AINPC`, cloud `Data` storage). Thin HTTP adapter only.
- Let jobs HTTP a provider.
- Let workers commit tools.
- Default Player2 or require it to play.
- Run a frontier model every tick or on every NPC.
- Host a developer LLM / dispatcher.
- Store world authority in chat history. Re-ground from the Statemachine.
