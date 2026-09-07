# Icarus AI — Art style lock

**Lock version:** 2  
**Date:** 2026-09-07  
**North star:** Wuthering Waves–class 3D anime presentation. Dark, high-depth color. Mystical, not pastel, not photoreal.

This file is the source of truth for how the game should look. Prompt text that agents paste into generators lives in [`art/prompt-lock.md`](art/prompt-lock.md). On-disk reference stills live in [`game/art/_style/`](../game/art/_style/).

Player-facing design (hub, combat, creator) stays in [`game-design.md`](game-design.md). This document only locks **stylization**.

---

## What agents must do

Before any image, texture, 3D, video, or VFX generation (Summer `summer_generate_image` / `summer_generate_3d` / `summer_generate_video`, or any other provider):

1. Read **this file** and [`art/prompt-lock.md`](art/prompt-lock.md).
2. Prepend the **lock prefix** to the prompt. Do not paraphrase it away.
3. Set image `style` to **`anime`**. Never leave Summer’s default `realistic`.
4. Put `negative_prompt` from the prompt lock into `options`.
5. If `game/art/_style/` has approved stills, use them as img2img / image-to-3d references.
6. Import into the path table below. Do not dump finals into `_style/`.
7. Show the result to the user before treating it as shipped art.

Kenney / graybox / old town prototypes are **scaffolding**, not style. Hub finals live in `game/art/hub/`. Do not generate more assets in the graybox look unless the user asked for a placeholder.

---

## Presentation

High-end **3D anime game cinematic**, in the same family as Wuthering Waves:

- Anime facial structure and eyes (clear irises, stylized nose/mouth).
- Bodies and clothing with real material presence (weave, metal, leather, hair cards) — not plastic dolls, not photoreal pores.
- Cinematic camera language: strong silhouettes, depth fog, rim light.
- World art matches characters. One game, one look.

This is an **inspiration lock** (lighting, materials, face language, color depth). It is **not** permission to copy WuWa characters, logos, Resonators, or locations.

---

## Color and light

| Layer | Use |
| --- | --- |
| Shadows | Ink navy, void black, deep violet. Shadows have hue, not generic gray. |
| Midtones | Jewel depth: indigo, teal, wine, muted gold. Saturated but dark. |
| Lights | Bright and sparse: moon-white, lantern gold, cyan/teal emissives. Rim + specular catches. |
| Atmosphere | Volumetric, high depth. Distance goes darker and cooler, not milky white. |
| Contrast | High. Deep darks, bright lights. If it looks washed or evenly lit, it failed. |

Hub (**Sanctum**) runs **warmer on the rock** (lantern gold in the dark) against a **cooler dusk-void sky** (ethereal purple / blue / nebula, floaty embers and stardust). Worlds can run **colder or harsher**. Both stay inside this palette. Do not invent a second art style for “cozy.”

---

## Do / don’t

**Do**

- Stylized 3D anime, game-ready, clean silhouette
- Dark jewel colors, emissive accents, rim light
- Mystical ruins, cloth, metal filigree, stone that reads expensive
- Characters that could sit in the creator: elves, demi-humans, humans, etc.

**Don’t**

- Photoreal / western realistic faces, skin pores, Unreal “default human”
- Chibi, cute pastel isekai, Ghibli watercolor, Disney 3D
- Flat 2D cel-shade as the 3D destination look
- Low-poly, Kenney, voxel, graybox as finals
- Overbright daytime anime, muddy brown generic medieval
- Neon cyberpunk as the default (emissives are accents, not the world)
- Copying a named WuWa (or other) IP character

---

## Asset paths

| Kind | Path |
| --- | --- |
| Style lock + approved refs | `game/art/_style/` |
| Characters / creator / portraits | `game/art/characters/` |
| Hub — Sanctum | `game/art/hub/` |
| Sanctum farm / crops | `game/art/hub/farm/` |
| Content catalog (approved) | `game/art/catalog/{buildings,items,props}/` |
| Content catalog inbox (pending / ready_for_review) | `game/art/catalog/_inbox/` |
| Portal worlds | `game/art/worlds/` |
| UI, title, loading | `game/art/ui/` |
| VFX, decals | `game/art/vfx/` |
| Gear / weapons | `game/art/gear/` |

Use `res://game/art/...` in Godot. Keep names lowercase_snake. One concept per file.

---

## How to update the lock

Stylization is allowed to evolve, but only **on purpose**:

1. Edit this file and [`art/prompt-lock.md`](art/prompt-lock.md) in the **same change**.
2. Bump **Lock version** and add a line to the changelog below.
3. If the look changed visually, add or replace stills in `game/art/_style/` and note them in that folder’s README.
4. Do not “nudge” prompts per-asset (a little more realistic, a little more chibi). Either the lock changes, or the asset follows the lock.

Old generated assets do not have to be mass-replaced the day the lock bumps. New work uses the new lock. Call out mismatches when touching old files.

---

## Changelog

| Ver | Date | Change |
| --- | --- | --- |
| 2 | 2026-09-07 | Sanctum hub lock: floating dusk-void rock, purple/blue sky, lantern gold on stone, embers/stardust. Catalog paths; Sanctum buildables share catalog meshes (no separate hub/homes path). |
| 1 | 2026-09-07 | Initial lock: WuWa-class 3D anime, dark high-depth color, prompt + path contract. |
