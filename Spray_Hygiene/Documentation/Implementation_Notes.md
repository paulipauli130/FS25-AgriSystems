# Spray & Hygiene — Implementation Notes

## Development build 0.6.0.0

The development foundation includes:
- Validated configuration and four pure Lua gameplay models.
- Engine-independent server-gated state container.
- Registered vehicle specialization restricted to vehicle types that already contain base-game Sprayer.
- Per-vehicle savegame XML schema for condition, wear, calibration, nozzle-group blockage and tank/line/filter residues.
- Server-only save/load of the per-vehicle model state.
- Read-only observer on the native onEndWorkAreaProcessing callback. It records a diagnostic work-cycle count only; it does not change native spray application, work-area parameters or fill consumption.
- Manual test plans.

## Official API basis
The public GIANTS Developer Network FS25 LUADOC (Script v1.20.0.0) documents:
- SpecializationManager:addSpecialization and TypeManager:addSpecialization.
- TypeManager:validateTypes and TypeManager:finalizeTypes as separate lifecycle stages.
- SpecializationUtil.registerEventListener and its duplicate-listener checks.
- Vehicle.xmlSchemaSavegame registration, per-vehicle savegame keys, and specialization saveToXMLFile serialization.

The registration hook adds the specialization to Sprayer types during type validation, before finalization registers the specialization callbacks. This ordering is source-reviewed against the documented TypeManager implementation; it still requires in-game validation against the user's installed patch and mod load order.

## Explicit limitations
- No runtime test has been performed in FS25 or on a dedicated server.
- The specialization is not yet proven to load successfully with every mod type manager/load order.
- The observer currently counts active native spray work cycles only. It does not calculate worked hectares or degrade equipment condition.
- Vehicle condition and cleaning data are now saved per vehicle through the specialization save path, but reload persistence still needs an actual save/reload test.
- Farmland contamination is not yet written to a mission-level savegame file.
- No multiplayer state replication or client UI exists.
- Drift and field contamination remain disconnected from engine callbacks.
- No native spray application or fill consumption is modified.

## Safety boundary
The observer must remain read-only. Never override Sprayer or ExtendedSprayer processing, deduct fill, or mutate workAreaParameters. Only server-side state may be saved. Unsupported schema versions fall back to default state.

## Next implementation gate
Run a real FS25 load/save/reload cycle and inspect log.txt. Then add server-authoritative replication for the per-vehicle state and implement the mission-level farmland contamination persistence adapter.
