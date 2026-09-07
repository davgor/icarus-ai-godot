# Git workflow

Git is mandatory. Every meaningful change must be recoverable. The working directory is not disposable.

## Default flow

```text
feature branch
    ↓
implementation
    ↓
tests
    ↓
review
    ↓
merge
```

Prefer this over direct uncontrolled modification of `main`.

## Branch names

Use short, purpose-shaped names:

- `bootstrap/dev-loop`
- `feat/living-town-npcs`
- `fix/player-camera`

## Agent rules

- Inspect status and diff before changing code.
- Do not commit unless asked, except when the user explicitly asks to establish or land a change.
- Do not force-push `main`.
- Do not skip hooks.
- Do not treat generated build output as source.

Summer may offer change review and rollback. **Git remains the source of truth.**
