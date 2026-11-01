# Farm Biosecurity — Implementation Notes

## Development build 0.3.1.0
- Independent mod bootstrap, validated configuration and pure disease/quarantine/hygiene/score models.
- Server-gated bounded StateStore with per-husbandry cohort state.
- PlaceableHusbandryAnimals-only specialization registration.
- Stable husbandry identity uses the base-game persistent Placeable uniqueId; identity acquisition is retried after placeable finalization if not available in the first load callback.
- Cohort identity is animal type plus configured subtype ID. All engine clusters of the same subtype in one husbandry are aggregated into one logical cohort; transient cluster IDs are not persisted.
- Placeable savegame XML schema, load and save paths for cohort disease/quarantine state and hygiene surfaces.
- Animal cohort creation is observed through onHusbandryAnimalsUpdate; newly seen cohorts start in quarantine.
- No physical animal movement restriction or disease exposure is active yet.

## Important granularity decision
FS25 animal cluster IDs are runtime identities and are regenerated/changed by cluster operations. To avoid unsafe ID matching, this implementation uses one persistent logical cohort per configured subtype in each husbandry. This deliberately aggregates same-subtype engine clusters. It avoids losing disease/quarantine state on cluster split/merge, but does not distinguish separate same-subtype subgroups inside one pen.

## Explicit limitations
- Placeable specialization registration and XML serialization are source-reviewed but not runtime-tested.
- Cohort progression, quarantine clock advancement, exposure/contact events and hygiene actions are not wired to gameplay.
- No incremental network replication or UI exists.
- No runtime validation has been performed in FS25 or on a dedicated server.

## Safety boundary
Only the server creates or saves cohort state. The engine's cluster ID is never persisted. Unsupported subtype metadata is skipped without clearing existing state. No clinical claims are made.
