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
2. Run `.\scripts\build.ps1` when the change should be playable
3. Launch with `.\scripts\play.ps1` when appropriate
4. Inspect runtime errors
5. Fix failures
6. Report exactly what changed

## Bootstrap vs game

Until the bootstrap loop is proven, do not implement Living Town systems (NPCs, saves, quests, combat, dungeons). Keep the playable scene minimal.
