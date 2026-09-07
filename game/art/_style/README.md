# Style references (`res://game/art/_style/`)

Approved **look targets** for generators. Not gameplay assets.

Canonical rules: [`docs/art-style.md`](../../../docs/art-style.md)  
Paste-ready prompts: [`docs/art/prompt-lock.md`](../../../docs/art/prompt-lock.md)

**Lock version currently in docs:** 1

## What belongs here

- Still frames that define lighting, palette, face language, material quality
- Palette strips or lighting ramps, if we bake them
- A short note in this README when a file is added (name, what it is allowed to steer)

## What does not belong here

- Final characters, hub meshes, weapons, UI (those go under `characters/`, `hub/`, `gear/`, `ui/`, `worlds/`, `vfx/`)
- Kenney / graybox / old `game/art/town/` prototypes
- Copyrighted screenshots dumped as “style” (describe the look in docs; do not import another game’s frames)

## How agents use these files

1. List this folder. If stills exist, pick the closest (character vs environment vs material).
2. Pass that image as img2img / image-to-3d reference (`referenceImageUrl` / `imageUrl`).
3. Still prepend the prompt lock. A reference does not replace the lock text.
4. After a lock-version bump, prefer refs tagged with the new version.

## Inventory

| File | Steers | Added |
| --- | --- | --- |
| `hub_dusk_v1.png` | Hub village dusk: lantern gold, cyan portal, ink-navy depth | 2026-09-07 |
