# Farm Biosecurity — Implementation Notes

## Development build 0.4.0.0
- Independent mod bootstrap, validated configuration and pure disease/quarantine/hygiene/score models.
- Server-gated bounded StateStore with per-husbandry cohort state.
- PlaceableHusbandryAnimals-only specialization and persistent husbandry identity from Placeable uniqueId.
- Stable logical cohort key: animal type plus configured subtype ID. Same-subtype clusters are aggregated; engine cluster IDs are never persisted.
- Per-placeable XML save/load for disease, quarantine, hygiene surfaces and elapsed in-game hour counter.
- Cohorts are discovered through onHusbandryAnimalsUpdate; newly discovered cohorts enter quarantine.
- Server-side onHourChanged progression advances disease state and quarantine once per in-game hour.
- The bootstrap preserves a lazily initialized state store instead of replacing it during map load.

## Important granularity decision
One logical cohort per configured subtype in each husbandry avoids unstable engine cluster IDs. It aggregates same-subtype engine clusters and does not distinguish separate same-subtype subgroups inside one pen.

## Explicit limitations
- Specialization registration, hourly callback order and XML reload are source-reviewed but not runtime-tested.
- No exposure/contact event integration or release/cleaning action UI exists. Quarantine cannot yet be released through gameplay.
- No network snapshot/delta synchronization or runtime validation has been performed.
- No disease or quarantine gameplay effect should be considered release-ready before SP and dedicated-server testing.
