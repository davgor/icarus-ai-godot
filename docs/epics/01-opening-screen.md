# Epic pack 01 — Opening screen

**Status:** Planned  
**Feature-list:** [`feature-list.md`](../feature-list.md) §1 Boot and title  
**Design:** [`game-design.md`](../game-design.md) Session flow → Title menu  
**Art:** [`art-style.md`](../art-style.md), [`art/prompt-lock.md`](../art/prompt-lock.md) — UI / title / loading suffix  
**Import root:** `game/art/ui/`

The game must open as a game: boot splash → title with **New / Load / Settings / Quit**, fully usable on a **gamepad**. The Millbrook “create character” overlay in `game/main.tscn` is bootstrap UI — replace it with this flow; do not grow it into the title.

Suggested ship order inside this pack: **OS-1 → OS-2 → OS-3 / OS-4 (parallel) → OS-5 → OS-6**. OS-6 can start as soon as OS-2 has focusable controls.

---

## Shared locks (all OS epics)

- Four title actions only: New, Load, Settings, Quit. No extras on the title root.
- Controller is first-class: D-pad / stick navigate, confirm / cancel, no mouse-cursor overlay as the gamepad path.
- Keyboard/mouse stays supported in parallel.
- Visuals match lock v1 (dark jewel UI, sparse bright highlights). Image `style` is `"anime"`. Prepend the prompt-lock prefix; use `options.negative_prompt` from the lock.
- If `game/art/_style/` stills exist, attach the closest UI/atmosphere ref. Do not use Kenney / `game/art/town/`.
- Headless tests stay in `tests/run_tests.gd` (`extends SceneTree`). Gate on `TEST_RESULT: PASS`.
- Canonical commands: `.\scripts\test.ps1`, then play/diagnostics when scene work lands, then `.\scripts\build.ps1` / `.\scripts\play.ps1` when the slice should be playable.

---

## OS-1 — Boot and loading screen

### Outcome

Cold start shows a branded loading / splash sequence, then hands off to the title. No drop into the graybox town or the old create overlay.

### Maps to

| ID | Feature |
| --- | --- |
| 1.1 | Loading screen |

### In scope

- Project boot path that presents splash / load before title
- Progress or indeterminate load feedback that matches UI chrome language
- Clean handoff to OS-2 title root (title may be a stub scene until OS-2 lands)
- Hide or defer Millbrook world until after New/Load succeeds (world stay out of boot)

### Out of scope

- Full save I/O (OS-4 shell only needs “no saves” later)
- Creator or hub content (packs 02 / 03 — not deferred tickets)
- Final audio mix (stubs OK) — Deferred: [`DEF-001`](../backlog/deferred/DEF-001-boot-title-audio.md)

### Dependencies

- None from later packs. Style lock v1 is enough to generate.

### Work

- Boot / autoload or main-flow scene that owns: Splash → Title (not Town)
- Loading UI control (progress or pulse) wired to real init work when present; fake-minimum duration only if init is instant (keep short)
- Headless path: skip or fast-forward splash so tests still quit cleanly
- Tests: boot reaches title state without SCRIPT ERROR

### Asset generation

Generate **before** locking layout sizes so chrome fits the art, not the reverse.

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Splash / boot key still | `game/art/ui/boot_splash.png` (or `.webp`) | Start of epic | Full-bleed mystical title atmosphere; empty hub portal silhouette or distant village lights; no readable UI chrome in the image; no logo text baked in if wordmark is separate |
| Wordmark / logo treatment | `game/art/ui/logo_icarus.png` | With splash | “Icarus AI” logotype or emblem-only mark for dark UI; high contrast sparse gold/cyan rim; transparent-friendly; **do not** put paragraph text in the image |
| Loading indicator frames or strip | `game/art/ui/loading_spinner.png` (or atlas) | With splash | Small mystical anime UI spinner / shard pulse; readable at HUD scale; dark jewel + emissive accent |
| Optional boot vignette / letterbox | `game/art/ui/boot_frame.png` | If layout needs it | Soft dark frame, not a card, not sci-fi HUD |

**Pipeline:** read art docs → prepend lock → `style: "anime"` → generate → `Read` preview → import under `game/art/ui/` → wire in scene.  
**Negative:** lock negative (especially `text, logo, UI chrome` when generating pure atmosphere; for logo asset, relax only as needed and say so in the prompt).  
**Audio stubs (callout, not blockers):** boot sting / soft whoosh — placeholder paths OK; final SFX later — [`DEF-001`](../backlog/deferred/DEF-001-boot-title-audio.md).

### Acceptance

- [ ] Launch shows splash/load, then title root (not Millbrook create HUD)
- [ ] Assets live under `game/art/ui/`, not `_style/` or `town/`
- [ ] Headless tests still pass (`TEST_RESULT: PASS`)
- [ ] After play (when MCP available): diagnostics clean for boot → title

---

## OS-2 — Title menu shell

### Outcome

Title presents **New**, **Load**, **Settings**, **Quit** only. Quit exits. New / Load / Settings leave clear hooks for OS-3–OS-5 (stubs that do not soft-lock).

### Maps to

| ID | Feature |
| --- | --- |
| 1.2 | Title menu |
| 1.3 | Quit |

### In scope

- Title scene / state with four actions
- Brand-forward layout: logo + menu as one composition (not a settings dashboard)
- Quit leaves the process cleanly (desktop export + editor play)
- Focus order and default focus on first open
- Temporary stubs: New → placeholder “creator TBD”; Load → empty or OS-4; Settings → OS-3

### Out of scope

- Real creator (pack 02)
- Real save list (OS-4 empty state is enough) — deepen: [`DEF-004`](../backlog/deferred/DEF-004-load-browser-polish.md)
- Settings persistence (OS-3 placeholders) — Deferred: [`DEF-002`](../backlog/deferred/DEF-002-settings-persistence.md)

### Dependencies

- OS-1 handoff target (or land splash + title together if tighter)

### Work

- Replace / isolate Millbrook `HUD/Create` as the boot UI
- Title control tree: logo, four buttons, focus neighbor setup
- Quit → `get_tree().quit()` (and any platform note for web later = N/A)
- Input actions for UI accept/cancel/navigate (shared with OS-6)
- Tests: menu presents four labels; quit path callable in headless without hanging

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Title background key art | `game/art/ui/title_bg.png` | Before final layout | Edge-to-edge mystical 3D-anime atmosphere; portal / empty Sanctum dusk-void; deep jewel darks; **no** overlaid buttons, badges, or fake UI in the image |
| Title logo (reuse OS-1 or refined) | `game/art/ui/logo_icarus.png` | If OS-1 logo needs title-scale pass | Same mark; larger safe margins for menu |
| Primary button / focus chrome | `game/art/ui/btn_primary.png` (+ `_focus` / `_hover` if nine-patch) | With background | Readable dark panel with sparse bright rim; anime game menu language; not Material flat, not sci-fi glass |
| Optional ambient particle / mote sheet | `game/art/vfx/title_motes.png` | Polish pass | Soft gold/cyan motes; sparse; gameplay-scale readable |

**Layout rule:** hero/atmosphere is full-bleed behind the menu. Do not inset the key art in a card.  
**Do not** generate Kenney-like panels “for now” as finals — procedural ColorRect stubs are OK only if the epic’s asset table is queued in the same PR series and tracked here.

### Acceptance

- [ ] Title shows exactly New / Load / Settings / Quit
- [ ] Quit exits play / exported build
- [ ] New / Load / Settings do not crash (stub or real shell)
- [ ] Art imported under `game/art/ui/` (vfx under `game/art/vfx/` if used)
- [ ] `TEST_RESULT: PASS`; play diagnostics clean when MCP available

---

## OS-3 — Settings shell

### Outcome

Settings opens from the title and is a real screen with **Audio**, **Graphics**, and **Controls** sections (placeholders allowed). Back returns to title. Controllers can open and leave it (full gamepad pass completes in OS-6).

### Maps to

| ID | Feature |
| --- | --- |
| 1.4 | Settings shell |

### In scope

- Settings scene or panel with three section placeholders
- Controls section acknowledges KBM + gamepad (copy or empty rows; rebind can wait)
- Back / cancel to title
- Non-persisted sliders/toggles OK for v0 if labeled as placeholders

### Out of scope

- Full rebind UI — Deferred: [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md)
- Graphics preset application that fights Summer/editor
- Cloud sync

### Dependencies

- OS-2 title entry point

### Work

- Settings UI tree + navigation
- Wire Settings button from title
- Optional: write/read a thin `user://settings.cfg` only if cheap; otherwise placeholders with TODO tied to a later epic
- Tests: open settings from title state; return to title

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Settings panel / sheet chrome | `game/art/ui/settings_panel.png` | Early | Dark jewel panel, readable hierarchy, not a dashboard card stack; sparse highlights |
| Section tab or header icons | `game/art/ui/icon_audio.png`, `icon_graphics.png`, `icon_controls.png` | With panel | Simple mystical anime UI icons; gold/cyan accent on dark; no text in image |
| Slider / toggle widget skins | `game/art/ui/widget_slider.png`, `widget_toggle.png` | With panel | Match button chrome from OS-2; readable at 1080p and gamepad focus |
| Back affordance (if not text-only) | `game/art/ui/icon_back.png` | Optional | Same icon language |

Reuse OS-2 focus ring / button chrome where possible — do not invent a second UI style.

### Acceptance

- [ ] Settings reachable from title and dismissible to title
- [ ] Audio / Graphics / Controls sections exist (placeholder content OK)
- [ ] New UI art under `game/art/ui/`
- [ ] Tests + diagnostics gates as above

---

## OS-4 — Load shell (empty state)

### Outcome

Load opens from the title. With no saves, the player sees a clear empty state (“no saves” or equivalent), not a broken list. Back returns to title. Ready for real slots when persistence lands (pack 05 / character save).

### Maps to

| ID | Feature |
| --- | --- |
| 1.5 | Load shell |

### In scope

- Load screen with empty state
- Detect “no saves” via existing or thin save probe (Millbrook save path OK as temporary probe if isolated)
- Back to title
- Hook for future slot list UI

### Out of scope

- Multi-slot browser polish / character preview renders — Deferred: [`DEF-004`](../backlog/deferred/DEF-004-load-browser-polish.md)
- Migrating Millbrook town saves into hub saves — Deferred: [`DEF-005`](../backlog/deferred/DEF-005-millbrook-save-migration.md)

### Dependencies

- OS-2; optional shared save probe with current `GameState` only as a temporary signal

### Work

- Load UI + empty state branch
- Wire Load from title
- Tests: empty state when no save file; back to title

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Empty-state illustration | `game/art/ui/load_empty.png` | With shell | Quiet mystical still — closed portal or unlit village — mood of “nothing saved yet”; **no** fake save-slot UI drawn into the art |
| Future save-slot frame (optional now) | `game/art/ui/save_slot_frame.png` | Optional | Empty frame chrome for later list; dark jewel; leave portrait area blank |

Copy/UI string is code, not baked into the illustration.

### Acceptance

- [ ] Load shows empty state when no saves
- [ ] Does not crash if save exists but is not yet supported (message or ignore with log)
- [ ] Art under `game/art/ui/`
- [ ] Tests + diagnostics gates as above

---

## OS-5 — New → creator handoff

### Outcome

**New** never skips customization in the real flow. From title, New enters the character-creation flow entry point. Until pack 02 exists, that entry is a dedicated **creator stub scene** (not the hub, not Millbrook name-only create), labeled as creator, with Back to title and a debug-only skip if needed.

### Maps to

| ID | Feature |
| --- | --- |
| 1.6 | New → creator |

### In scope

- Title New → creator flow route
- Stub creator landing that is obviously “character creation next,” not “type a name and spawn in town”
- Back to title
- Debug skip (F-key or hidden) may jump to hub/town **only** for development; not shown as the intended path

### Out of scope

- Race / morph / outfit implementation (pack 02 epics)
- Writing final character save schema

### Dependencies

- OS-2; pack 02 will replace the stub body

### Work

- Flow controller / state machine: Boot → Title → Creator → (future Hub)
- Remove intended-path dependency on Millbrook name create
- Tests: New lands on creator stub; Back returns to title

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Creator stub backdrop | `game/art/ui/creator_stub_bg.png` | With handoff | Soft character-atelier atmosphere (mirror / light shafts / dark jewel room); implies customization; no full character sheet UI in the image |
| Transition veil / wipe (optional) | `game/art/vfx/title_to_creator_wipe.png` | Polish | Short mystical wipe or light bloom; sparse |

**Call-forward:** pack 02 must list creator kit assets (`game/art/characters/`) — race presets, UI chrome, turnaround lighting. OS-5 only ships stub/transition art so New does not reuse title key art as a fake creator. Retire stub art when atelier ships — Deferred: [`DEF-006`](../backlog/deferred/DEF-006-creator-stub-art-retirement.md).

### Acceptance

- [ ] New → creator stub (not hub spawn, not Millbrook name create as the real path)
- [ ] Back to title works
- [ ] Debug skip (if present) is not a title button
- [ ] Stub/transition art under `game/art/ui/` or `game/art/vfx/`
- [ ] Tests + diagnostics gates as above

---

## OS-6 — Controller from boot

### Outcome

Title, Settings, Load, Quit, and the creator stub are fully usable on a gamepad without a mouse. Focus is visible. Stick/D-pad move; Accept confirms; Cancel backs out.

### Maps to

| ID | Feature |
| --- | --- |
| 1.7 | Controller from boot |

### In scope

- UI focus navigation for OS-2–OS-5
- Gamepad device detection / default focus when a pad is present
- On-screen prompt glyphs for Accept / Cancel (and Navigate if needed)
- Same actions work with keyboard

### Out of scope

- Full in-game action rebind (Controls section may say “coming later”) — Deferred: [`DEF-003`](../backlog/deferred/DEF-003-controls-rebind.md)
- Mouse-cursor emulation mode as the gamepad solution

### Dependencies

- OS-2 minimum; complete against OS-3–OS-5 when those shells exist

### Work

- InputMap actions: `ui_up/down/left/right`, accept, cancel — verify joypad mappings
- Focus visuals on buttons/sliders
- Disable unintended focus escape to hidden Millbrook HUD
- Tests: simulate joypad UI events where feasible; at least verify focus neighbors + action bindings exist
- Manual / Summer play: pad-only smoke on title → settings → back → load → back → new → back → quit

### Asset generation

| Asset | Dest | Generate when | Prompt intent (after lock prefix) |
| --- | --- | --- | --- |
| Gamepad glyph set | `game/art/ui/glyph_a.png`, `glyph_b.png`, `glyph_dpad.png`, `glyph_stick.png` (names as needed) | With focus pass | Clean mystical anime UI button glyphs; readable; consistent with chrome; no Sony/Xbox trademark replicas — generic shapes + labels in code if needed |
| Focus ring / highlight | `game/art/ui/focus_ring.png` | With glyphs | Bright sparse rim (moon-white / gold / cyan) on dark; readable at menu scale |
| Optional “Press to start” pulse | `game/art/ui/press_start_pulse.png` | Only if boot uses it | Soft emissive pulse; no wall of marketing badges |

### Acceptance

- [ ] Pad-only: open title, enter settings, back, enter load, back, enter New stub, back, quit
- [ ] Focus ring always visible on the focused control
- [ ] No reliance on moving a mouse cursor with the stick
- [ ] Glyph/focus art under `game/art/ui/`
- [ ] Tests + pad smoke + diagnostics when MCP available

---

## Pack-level definition of done

This pack is **Playable** when:

1. Cold boot → splash/load → title feels like a game open.
2. Four title actions behave per OS-2–OS-5.
3. Gamepad path works per OS-6.
4. Generated UI art is imported under `game/art/ui/` (and vfx if used), locked to art-style v1.
5. `.\scripts\test.ps1` prints `TEST_RESULT: PASS`.
6. Play + `summer_get_diagnostics` (when MCP available) shows no new errors for the boot flow.
7. Millbrook town is no longer the first thing you see on launch.

**Not required for this pack:** real character morphs, Sanctum destination art, portal worlds, combat.

---

## Implementation notes for agents

- Prefer a small flow owner (autoload or root flow scene) over burying title logic in `game/main.gd` Millbrook hooks.
- Keep engine state authoritative; title does not need an LLM.
- Generate art in the same change series as the screens that show it; do not merge title “forever gray” without the asset table above tracked as follow-up in-branch.
- When pack 02 starts, replace OS-5 stub body; keep the New route. Rope in [`DEF-006`](../backlog/deferred/DEF-006-creator-stub-art-retirement.md) in that same series.
- Before implementing: review [`../backlog/deferred/`](../backlog/deferred/) Open tickets; link any deferment you newly create.
