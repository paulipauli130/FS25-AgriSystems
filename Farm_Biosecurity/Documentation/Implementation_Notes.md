# Farm Biosecurity — Implementation Notes

## Development build 0.1.0.0
- Independent modDesc and bootstrap listener.
- Validated configuration with module toggles, quarantine, disease progression, hygiene and normalized score weights.
- Group-level disease model with susceptible, incubating, infectious, recovering and recovered states.
- Explicit exposure calculation requiring a caller-confirmed contact opportunity and server-supplied deterministic roll. No spontaneous infection is generated.
- Quarantine model with elapsed in-game hours, release request and hygiene-compliance gate.
- Surface hygiene model with separate dirt cleaning and disinfection. Disinfection is rejected while dirt exceeds its threshold.
- Derived Biosecurity Score with weighted components and breakdown.
- Manual model test plan.

## Explicit limitations
- Not connected to PlaceableHusbandryAnimals, AnimalClusterSystem or actual animal groups.
- No engine cluster ID is used as persistent identity.
- No husbandry/group persistence, network events, UI, costs or action triggers.
- No disease or quarantine gameplay effect is active.
- Profiles are abstract gameplay parameters, not veterinary or pathogen-accuracy claims.
- No FS25 runtime or GIANTS TestRunner validation has been performed.

## Next implementation gate
Implement placeable specialization and mod-owned husbandry/group identity after validating exact FS25 cluster update/save/load callbacks. Then add versioned persistence and server-to-client snapshots.
