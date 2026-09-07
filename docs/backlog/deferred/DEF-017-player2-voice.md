# DEF-017 — Player2 voice (TTS / STT)

**Status:** Open  
**Source:** [AR-4 — Player2 worker](../../epics/06-agent-runtime.md#ar-4--player2-worker)  
**Deferred from:** Pack 06 — AR-4 Out of scope  
**Suggested rope-in:** When shipping voiced NPC / companion lines, or a talk-to-NPC input mode

## Want

Player2 TTS/STT as a **voice** adapter, off the cognition path. Dialogue still commits through the Statemachine. Missing Player2 must not block play or text dialogue.

## Not this ticket

Player2 as an LLM worker ([AR-4](../../epics/06-agent-runtime.md#ar-4--player2-worker)). Official Player2 Godot NPC plugin. Cloud user-data storage.

## Done when

- [ ] Optional TTS for committed `say` / narration
- [ ] Optional STT into dialogue input
- [ ] Voice adapter failure falls back to text
- [ ] No Statemachine writes from audio code
