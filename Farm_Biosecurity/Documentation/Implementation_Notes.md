# Farm Biosecurity — Implementation Notes

## Development build 0.4.0.0
- Independent bootstrap, configuration and pure disease/quarantine/hygiene/score models.
- Server-gated bounded StateStore.
- PlaceableHusbandryAnimals-only specialization with persistent Placeable uniqueId.
- One logical cohort per animal type + configured subtype ID per husbandry; same-subtype clusters are aggregated and engine cluster IDs are never persisted.
- Per-placeable XML save/load for disease, quarantine, hygiene and elapsed in-game hours.
- Server-side hourly disease/quarantine progression.
- Initial server-to-client snapshot for up to 512 cohorts and 128 hygiene surfaces.
- Client snapshot reader consumes the complete packet before applying it, preserving stream alignment even if the local placeable identity is unavailable.
- Client snapshot application does not grant client authority.

## Important granularity decision
Same-subtype clusters in one husbandry are aggregated into one logical cohort. This avoids losing state when engine cluster IDs split, merge or regenerate, but does not distinguish same-subtype subgroups inside one pen.

## Explicit limitations
- Specialization registration, hourly callback order, XML reload and network stream serialization are source-reviewed but not runtime-tested.
- Exposure/contact integration, quarantine release actions, hygiene actions, UI and incremental dirty-state replication are not implemented.
- No dedicated-server validation has been performed.
- No clinical accuracy claims are made.
