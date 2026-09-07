# DEF-016 — Multiplayer worker routing

**Status:** Open  
**Source:** [AR-2 — Orchestrator](../../epics/06-agent-runtime.md#ar-2--orchestrator)  
**Deferred from:** Pack 06 — AR-2 / AR-5 Out of scope (peer advertisement)  
**Suggested rope-in:** When a multiplayer session / Steam net slice exists, or when a dedicated host process is extracted from the Statemachine

## Want

The Orchestrator inventories workers advertised **over the multiplayer connection** as well as the host machine. Peers run `complete()` only. The Statemachine stays on the session authority. A Steam Deck player still plays; they are not a second sim. Disconnect fails in-flight work typed; the Orchestrator re-scores. Net payload is WorkItem + CompletionResult, not the full save.

## Not this ticket

Pack 06 host-only Orchestrator ([`06-agent-runtime.md`](../../epics/06-agent-runtime.md)). Player-facing co-op gameplay, interest management, or a developer-hosted relay.

## Done when

- [ ] Peer worker advertisement + health
- [ ] Host Orchestrator can assign a WorkItem to a remote `complete()`
- [ ] Statemachine commits only on the authority
- [ ] Peer leave does not apply a partial tool batch
