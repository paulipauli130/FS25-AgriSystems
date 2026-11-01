# Farm Biosecurity — Implementation Notes

## Development build 0.4.0.0
- Independent bootstrap, configuration and pure disease/quarantine/hygiene/score models.
- Server-gated bounded StateStore.
- PlaceableHusbandryAnimals-only specialization with persistent Placeable uniqueId.
- One logical cohort per animal type + configured subtype ID per husbandry; transient engine cluster IDs are never persisted.
- Per-placeable save/load for disease, quarantine, hygiene and elapsed in-game hours.
- Server-side hourly disease/quarantine progression.
- Initial server-to-client snapshot for cohort and hygiene state, bounded to 512 cohorts and 128 surfaces.
- Client snapshot application is read-only from the client's perspective; only the server writes authoritative state.

## Important granularity decision
Same-subtype clusters in one husbandry are aggregated into one logical cohort. This avoids losing state when engine cluster IDs split, merge or regenerate, but does not distinguish same-subtype subgroups within one pen.

## Explicit limitations
- Specialization registration, hourly callback order, XML reload and network stream serialization are source-reviewed but not runtime-tested.
- Exposure/contact event integration, quarantine release actions, hygiene actions, UI and incremental dirty-state replication are not implemented.
- No dedicated-server validation has been performed.
- No clinical accuracy claims are made.

## Safety boundary
Only the server creates, progresses and saves cohort state. Engine cluster IDs are not persistent identifiers. Unsupported subtype metadata is skipped without clearing existing state.
