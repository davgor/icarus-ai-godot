# Development loop

Desired personal workflow:

> Think of something → tell Cursor → let it implement it → build → play it.

```text
                 IDEA
                  │
                  ▼
             AI CODING AGENT
                  │
                  ▼
            CODE / SCENE CHANGE
                  │
                  ▼
                TEST
                  │
            ┌─────┴─────┐
            │           │
          FAIL         PASS
            │           │
            ▼           ▼
       AI FIXES       BUILD
            │           │
            └─────┬─────┘
                  │
                  ▼
             PLAYABLE GAME
                  │
                  ▼
                 PLAY
```

## Agent definition of done

A feature is not done because it compiles. After implementation:

1. Run `.\scripts\test.ps1`
2. If Summer MCP is connected: `summer_play`, wait, `summer_get_diagnostics`, fix
3. Run `.\scripts\build.ps1` when the change should be playable
4. Launch with `.\scripts\play.ps1` when appropriate
5. Report exactly what changed

## Proven status

The bootstrap loop is proven (Cursor edit → `.\scripts\test.ps1` → `.\scripts\build.ps1` → `.\scripts\play.ps1`, and Summer MCP inspect → modify → play → diagnostics → fix).

The operating contract for agents is [`agent-operating-loop.md`](agent-operating-loop.md). Do not revert to GUT, guessed scene paths, or “it compiles so it is done.”
