# DEF-021 — Arrange material spend

**Status:** Open  
**Source:** [SH-6 — Shared placement](../../epics/03-sanctum-hub.md#sh-6--shared-placement-ghost-rotate-move-remove) / [SH-7 — Building placement](../../epics/03-sanctum-hub.md#sh-7--building-placement) / [SH-11 — Layout persistence](../../epics/03-sanctum-hub.md#sh-11--layout-persistence-and-starter-kit)  
**Deferred from:** Pack 03 — starter kit is free so Arrange is playable before the bank  
**Suggested rope-in:** When the wood / metal / fiber bank and farm loop land (later cozy-sim pack, [`feature-list.md`](../../feature-list.md) §7)

## Want

Placing (or replacing) non-starter Sanctum designs spends **wood / metal / fiber** from the hub bank per `properties.material_cost`. Refunds or partial refunds on remove are a locked rule when this ships. Starter kit stays cost 0.

## Not this ticket

Starter arrange kit unlocked and free ([pack 03](../../epics/03-sanctum-hub.md)). A fourth Sanctum material. Voxel costs.

## Done when

- [ ] Non-starter place checks and deducts the three materials
- [ ] Insufficient materials refuse with readable feedback (pad + KBM)
- [ ] Bank + layout stay engine-owned and persisted
