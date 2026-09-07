# 11 — UE5 migration

Do **not** prematurely optimize the Godot game for Unreal. Build the Godot game properly.

If the project ever outgrows Godot, the **engine layer** should be disposable, not the game:

```text
             GAME SIMULATION
                    │
             ┌──────┴──────┐
             │             │
          GODOT          UE5
        (this repo)    (only if needed)
```

The Godot implementation is not a throwaway. The goal is a portable sim, not a disposable prototype.

---

## Highly portable

World schema, seeds, constitution, NPC state, relationships, romance/trust/jealousy flags, factions, economy, quests, event journal, cognition contracts, persistence, game rules (combat tags, parkour kit, companion slots, loadout vs outfit).

## Engine-specific

Rendering, animation, physics integration, navigation implementation, terrain, shaders, VFX, world streaming, UI implementation, Godot scenes, Summer editor workflow.

Keep those boundaries in [`09-GODOT-ARCHITECTURE.md`](09-GODOT-ARCHITECTURE.md). Do not leak `Node3D` paths into save files or NPC cognition.
