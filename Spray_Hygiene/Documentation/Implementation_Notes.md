# Spray & Hygiene — Implementation Notes

## Development build 0.7.0.0

The development foundation includes:
- Four pure Lua gameplay models and validated configuration.
- Engine-independent server-gated state container.
- Sprayer-only specialization registration and per-vehicle XML save/load code.
- Read-only native spray callback observer (diagnostic work-cycle count only).
- Initial server-to-client stream snapshot for sprayer condition and cleaning residues.
- Client snapshot values are validated and client-side code does not write authoritative state.
- Manual model and runtime test plans.

## Official API basis
The public GIANTS Developer Network FS25 LUADOC (Script v1.20.0.0) documents specialization registration, TypeManager validation/finalization, per-vehicle savegame XML schema, specialization saveToXMLFile serialization, and initial onWriteStream/onReadStream callbacks.

## Explicit limitations
- No FS25 runtime or dedicated-server test has been performed.
- Registration hook and save/reload need validation against the installed game patch and other mods.
- The observer only counts native active spray cycles; it does not calculate worked hectares or degrade condition.
- Initial network snapshot is implemented; incremental dirty-state replication is not.
- No in-game UI or player actions exist.
- Farmland contamination is not yet persisted to a mission-level savegame file.
- Drift and field contamination are not connected to engine callbacks.
- Native spray application, fill consumption and work-area parameters remain untouched.

## Safety boundary
The observer remains read-only. Never override Sprayer or ExtendedSprayer processing, deduct fill, or mutate workAreaParameters. The server owns savegame state; clients only receive an initial snapshot.

## Next implementation gate
Add a bounded, server-authoritative dirty-state update path for condition and cleaning, then implement mission-level farmland contamination persistence. Both require dedicated-server validation.
