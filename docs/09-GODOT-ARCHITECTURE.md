# 09 — Godot architecture

Godot is the **prototype and likely shipping runtime**. Simulation must not become a pile of node-path assumptions that only Godot understands.

Summer is a **development accelerator**, not a runtime dependency. Cursor + Summer may edit the project aggressively. The shipped game remains a normal Godot 4 project (`res://game/main.tscn`, GDScript, `.\scripts\test.ps1`).

---

## Target layout (migrate when the pain is real)

Do not rewrite the tree in one pass. Current graybox (`game/player.gd`, `game/sim/game_state.gd`, …) stays until a slice needs a new home.

```text
/game
    /simulation        # little/no Godot: world, npc, factions, economy,
                       # relationships, events, cognition contracts
    /gameplay          # combat, inventory, quests, interaction, parkour rules
    /persistence       # save, schema, migrations
    /engine/godot      # rendering, navigation, animation, physics, audio, input
```

Simulation knows as little about Godot as practical. Gameplay may call engine services through narrow interfaces. Art lives under `game/art/` per [`art-style.md`](art-style.md).

Portable vs engine-specific split: [`11-UE5-MIGRATION.md`](11-UE5-MIGRATION.md).

---

## Do not

- `extends SummerGame` or Summer SDK in shipped code
- A second main scene at `res://main.tscn`
- Parallel test runners
- Making the Living Town pre-seeded square the hub
