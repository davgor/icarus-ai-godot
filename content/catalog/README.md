# Content catalog

Approved defs live here. Pipeline and schema: [`../12-CONTENT-CATALOG.md`](../12-CONTENT-CATALOG.md).

```text
buildings/   approved building JSON
items/       approved item JSON
props/       approved prop JSON (optional)
_inbox/      pending + ready_for_review drafts — not sampled by runtime
```

Flow: agent generates through **mesh**, marks `ready_for_review` → you set `approved` → move out of `_inbox/`. First pump: **log cabin set** (target **20** approved buildings). Sanctum materials v0: wood / metal / fiber. Art mirrors under `game/art/catalog/`.
