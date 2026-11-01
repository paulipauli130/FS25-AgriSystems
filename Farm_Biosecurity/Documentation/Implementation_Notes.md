# Farm Biosecurity — Implementation Notes

## Development build 0.2.2.0
- Independent mod bootstrap and validated configuration.
- Group-level disease progression, explicit contact-based exposure and conservative split/merge helpers.
- Quarantine with hygiene-compliance release gate.
- Dirt cleaning followed by disinfection with a real contact-time completion step.
- Derived weighted Biosecurity Score.
- Server-gated StateStore for husbandry/group records.
- Transient engine-cluster-to-mod-group mapping is memory-only and cleared on load.
- Storage is bounded to 128 husbandries, a configured maximum of 1–2048 groups per husbandry, and 1024 hygiene surfaces per husbandry.
- Split preflights record capacity; merge rejects invalid/duplicate IDs.
- Standalone Lua assertion suite and manual test plan.

## Explicit limitations
- No placeable specialization or actual AnimalClusterSystem callback integration.
- Mod-owned husbandry/group IDs still require an engine adapter and savegame persistence.
- Split/merge helpers require explicit verified relationships from the engine adapter.
- No group/husbandry XML persistence, network events, UI, costs or action triggers.
- No gameplay effect is active; no FS25 runtime or GIANTS TestRunner validation has been performed.

## Safety boundary
Engine cluster IDs are transient references only and are never serialized. Ambiguous reconciliation must not clear disease or quarantine. Exposure requires a server-confirmed contact opportunity.
