# Spray & Hygiene — Implementation Notes

## Development build 1.0.1.0

The current development foundation includes:
- Four pure Lua gameplay models and validated configuration.
- Engine-independent server-gated state container.
- Sprayer-only specialization registration and per-vehicle XML save/load code.
- Server-side operating-time wear and calibration degradation after successful native spray processing.
- Savegame-specific persistence for host settings.
- Initial server-to-client state snapshot for newly connected clients.
- Incremental server-to-client state updates using the vehicle dirty-mask/update-stream callbacks.
- Bounded synchronization payloads for nozzle groups and residue entries.
- Client state is validated on receipt; clients never author authoritative gameplay state.
- Standalone model tests and runtime test plans.

## Network synchronization

The specialization allocates one vehicle dirty flag through `getNextDirtyFlag()`. When the server changes condition or calibration, it raises that flag with `raiseDirtyFlags()`. FS25 then invokes `onWriteUpdateStream` for relevant client connections; the client reads the update through `onReadUpdateStream`. The initial `onWriteStream`/`onReadStream` snapshot remains in place for joining clients.

The update stream sends a compact change marker first and writes the bounded state payload only when the specialization's dirty bit is present. It does not broadcast a full payload every frame. The server remains authoritative.

## Official API basis

The public GIANTS Developer Network FS25 LUADOC (Script v1.20.0.0) documents:
- Vehicle specialization callbacks `onWriteUpdateStream(streamId, connection, dirtyMask)` and `onReadUpdateStream(streamId, timestamp, connection)`.
- Dirty-mask checks using `bit32.band(dirtyMask, spec.dirtyFlag)`.
- Dirty-flag allocation through `self:getNextDirtyFlag()`.
- State invalidation through `self:raiseDirtyFlags(spec.dirtyFlag)`.
- Initial join snapshots through `onWriteStream`/`onReadStream`.

Reference: https://gdn.giants-software.com/documentation_scripting_fs25.php?category=78&class=672&version=script

## Explicit limitations

- No FS25 runtime or dedicated-server test has been performed for the new update-stream callbacks.
- Registration hook, callback order, save/reload and network behavior need validation against the installed game patch and other mods.
- Wear currently uses successful operating time, not measured hectares or nozzle-specific flow.
- Cleaning residues and nozzle blockage are model/state foundations; automatic cleaning actions and residue accumulation are not connected to gameplay.
- Drift and field contamination are not connected to engine callbacks.
- Farmland contamination is not yet persisted to a mission-level savegame file.
- Native spray application, fill consumption and work-area parameters remain untouched.

## Safety boundary

Never override Sprayer or ExtendedSprayer processing, deduct fill, or mutate workAreaParameters. The server owns simulation and persistence. Clients only receive the initial snapshot and server-authoritative dirty-state updates.

## Next implementation gate

Run an in-game multiplayer test with two clients: verify initial state on join, wear updates during successful spraying, no updates when wear is disabled, and correct state after reconnect/save reload. After that, continue with mission-level farmland contamination persistence and validated cleaning actions.
