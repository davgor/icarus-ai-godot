# 10 — AI development workflow

The development environment is agentic. The human remains **architect and product owner**.

Desired loop:

```text
USER IDEA
   ↓
CURSOR
   ↓
CODE / SCENE / ASSET CHANGES
   ↓
GIT
   ↓
CI
   ↓
.\scripts\test.ps1
   ↓
.\scripts\build.ps1   (when playable)
   ↓
PLAY
   ↓
USER FEEDBACK
   ↓
CURSOR
```

**Do not invent a second path.** The proven contract is [`agent-operating-loop.md`](agent-operating-loop.md). Personal sketch: [`development-loop.md`](development-loop.md). Git: [`git-workflow.md`](git-workflow.md). Tooling: [`tooling.md`](tooling.md).

Agents may implement systems, edit scenes (Summer MCP), generate art (style lock), run tests, diagnose, iterate. **Do not commit unless asked.** Do not skip hooks. Do not force-push `main`.

Bulk world content (buildings, items, props) uses the **approval loop** in [`12-CONTENT-CATALOG.md`](12-CONTENT-CATALOG.md): generate → **agent pre-screen** → **your final approval** → catalog → compiler places by id. Agents may mark `ready_for_review`; they do not auto-ship to `approved`.

Definition of done is not “it compiles.” Test, diagnostics after play, report exactly what changed.

World directors ([`06-AGENT-ARCHITECTURE.md`](06-AGENT-ARCHITECTURE.md)) are not this workflow. Do not confuse in-game cognition with the coding agent.
