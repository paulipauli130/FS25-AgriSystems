# Farm Biosecurity — Implementation Notes

## Development build 0.2.1.0
- Independent modDesc and bootstrap listener.
- Validated configuration.
- Group-level disease progression and explicit contact-based exposure model.
- Conservative disease-state helpers for split and merge operations.
- Quarantine model with elapsed in-game hours, release request and hygiene-compliance gate.
- Surface hygiene model with separate dirt cleaning and disinfection contact-time window. Contamination is reduced only after the configured contact time elapses.
- Derived Biosecurity Score.
- Server-gated engine-independent StateStore for husbandry/group records.
- Transient engine-cluster-to-mod-group mapping is memory-only and cleared on load.
- Split helper copies disease/quarantine state to child groups and preflights record capacity.
- Merge helper preserves the most advanced disease state and strictest quarantine; invalid/duplicate source IDs are rejected.
- Manual model test plan and standalone Lua assertion suite.

## Explicit limitations
- No placeable specialization or actual AnimalClusterSystem callback integration.
- Mod-owned husbandry/group IDs must be supplied by a future adapter and persisted by the future placeable specialization.
- Split/merge helpers require explicit, verified parent/child relationships from the engine adapter.
- No group/husbandry savegame XML, network events, UI, costs or action triggers.
- No disease or quarantine gameplay effect is active.
- No FS25 runtime or GIANTS TestRunner validation has been performed.

## Safety boundary
Engine cluster IDs are transient references only and are never serialized. Ambiguous cluster reconciliation must not clear disease or quarantine. Exposure remains restricted to explicit server-confirmed contact opportunities.
