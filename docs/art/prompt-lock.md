# Prompt lock

Paste-ready fragments for generators. Stylization rules live in [`../art-style.md`](../art-style.md). **Keep this file in lockstep** when the bible changes.

**Lock version:** 2

Summer image generation: `style` **must** be `"anime"`. Default `"realistic"` is wrong for this project.

```text
❌ style: "realistic"
✅ style: "anime"
```

---

## Lock prefix

Put this **first** in every visual prompt (image, 3D, video, concept, texture). Then describe the specific asset.

```text
Icarus AI style lock v2: high-end 3D anime game cinematic in the presentation of Wuthering Waves. Stylized anime faces and eyes, physically detailed clothing and materials, not photoreal skin. Dark high-depth color: ink-navy and void-black shadows, jewel midtones (indigo, teal, wine), bright rim and emissive lights (moon-white, gold, cyan). Strong contrast, volumetric atmosphere, mystical not neon-cyberpunk. Cohesive game-ready asset, clean silhouette.
```

---

## Negative prompt

Pass as `options.negative_prompt` (and equivalent on other providers):

```text
photoreal, western realistic face, skin pores, unreal engine default human, chibi, cute pastel isekai, flat cel-shaded 2D, low-poly, kenney, voxel, graybox, overbright, washed out, muddy brown generic medieval, disney 3d, ghibli watercolor, comic ink, horror gore, watermark, text, logo, UI chrome, copied copyrighted character
```

---

## Summer image call shape

```text
summer_generate_image
  style: "anime"
  model: "nano-banana-2"   (unless the user named another allowlisted model)
  prompt: "<LOCK PREFIX> <subject, camera, usage>"
  options:
    negative_prompt: "<NEGATIVE PROMPT>"
```

If `game/art/_style/` has an approved still that matches the job, use img2img: `referenceImageUrl` = that still (or its hosted URL), and keep the lock prefix in the prompt.

After generation, `Read` the returned `localPath` and compare against the bible before import.

---

## Summer 3D call shape

Prefer **image-to-3d** from a style-locked concept image. Text-to-3d still gets the lock prefix.

```text
summer_generate_3d
  kind: "image-to-3d"     (preferred) or "text-to-3d"
  prompt: "<LOCK PREFIX> <object or character, game-ready, PBR, isolated>"
  assetIntent: "character" or "object"
```

Add, as appropriate: `game-ready 3D model, clean topology, PBR materials, no studio base, no ground plane`.

Do not ask 3D models for “low poly Kenney” unless the user explicitly wants a placeholder.

---

## Subject suffixes (append, do not replace the lock)

**Character / creator / portrait**

```text
Full-body or bust as requested, anime facial proportions, detailed hair, costume with material breakup, cloth cape when worn, readable jewelry (necklace, earrings, rings) as accessories not fused into the skin, rim light, dark jewel backdrop, Icarus character creator quality.
```

**Demi-human feature (ears / horns / tails)**

```text
Isolated or socketed anime demi-human feature for character creator: ears, horns, or tails (include lizard/dragon tail variants when requested), clean silhouette, game-ready, dark jewel void backdrop, not a full character unless asked.
```

**Hub — Sanctum**

```text
Cozy floating stone sanctum rock in an infinite dusk-void sky, ethereal purple and blue nebula depth, sparse stars, floaty embers and stardust around the islet, lantern gold warm on stone against cool void, optional small farm plots and simple placed anime fantasy homes, furniture, lanterns, and stone paths when arranged, empty except a bright mystical freestanding portal arch at the cliff overlook when new, lived-in but sparse, high depth fog, mystical 3D anime environment.
```

**Sanctum home design / building**

```text
Placeable cozy home or structure for a floating sanctum, same mesh used in worlds when sanctum_buildable, game-ready exterior, readable silhouette, dark jewel materials with lantern gold accents, climbable roofs where natural, not a graybox blockhouse, mystical 3D anime dwelling.
```

**Sanctum furniture**

```text
Placeable outdoor or courtyard furniture for a floating sanctum (bench, table, crate stack, planter), game-ready prop, readable from top-down and third-person, dark jewel wood/stone with lantern gold accents, not Kenney, not graybox, not a full building.
```

**Sanctum light fixture**

```text
Placeable lantern, standing lamp, or stone light for a floating dusk-void sanctum, game-ready, real emissive warm gold, readable glow at night, isolated prop, mystical 3D anime, not a flashlight, not neon cyberpunk.
```

**Sanctum ground / path paint**

```text
Top-down ground texture or splat for a floating stone sanctum: worn stone path, packed dirt, moss, or cobble, tileable, dusk lantern-gold warm on cool jewel stone, game-ready albedo, not a heightmap sculpt, not photoreal dirt photography.
```

**Sanctum Arrange (top-down still)**

```text
Top-down orthographic or steep bird's-eye view of a small floating sanctum islet in dusk-void, readable layout of rock bowl, paths, lanterns, and a few placed homes, ethereal purple-blue sky around the edges, mystical 3D anime, not a strategy-game minimap, not a city builder screenshot.
```

**World catalog building / item / prop**

```text
Single game-ready collectible content piece for the Icarus catalog, isolated, clean silhouette, dark jewel materials, mystical 3D anime, suitable for world placement and later player collection, not a graybox placeholder, not Kenney style.
```

**Log cabin set (first building pump)**

```text
Cozy log cabin or timber dwelling variation, mystical 3D anime game-ready building, warm wood against dusk jewel light, readable silhouette, climbable roof where natural, isolated for catalog, not Kenney, not graybox, not photoreal rustic photography.
```

**Portal world / combat space**

```text
Adventure space, heavier atmosphere, colder or harsher accent lights, readable combat staging, same 3D anime material language as the hub.
```

**Gear / weapons**

```text
Hero prop, readable silhouette, PBR metal/wood/cloth, subtle emissive filigree, dark fantasy anime game weapon, not a toy.
```

**Heal node**

```text
Mystical crystalline shard in the world, originium-like heal beacon, dark jewel stone with bright inner light (gold/cyan), readable as a gameplay device, not a generic crate.
```

**UI / title / loading**

```text
Atmospheric 3D-anime UI illustration or panel, readable, dark depth, sparse bright highlights, not generic sci-fi HUD, not photoreal.
```

**VFX**

```text
Stylized 3D anime VFX, high contrast emissive on dark, readable at gameplay scale, mystical (gold/cyan/teal), not noisy particle soup.
```

---

## Per-asset prompt template

```text
<LOCK PREFIX>
<one sentence: what it is>
<one sentence: camera / usage (orthographic turnaround, in-world prop, title key art, …)>
<one subject suffix from above>
```
