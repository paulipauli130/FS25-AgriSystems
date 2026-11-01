# Field Contamination Model — Test Plan

## Scope

This is a pure Lua farmland-level state model. It does not discover fields, inspect terrain, scan machinery or connect to FS25 callbacks. The caller must supply a server-validated positive farmland ID after a confirmed contact event.

## Deterministic checks

1. New state has no farmland records.
2. Invalid, zero, negative, fractional, NaN and infinite farmland IDs are rejected.
3. Only positive integer farmland IDs create records.
4. Contamination classes are independent within each farmland record.
5. Loads are bounded by the supplied maximum (0–1); invalid amounts fall back to zero.
6. Equipment-to-field transfer equals equipmentLoad × transferRate × contactFactor for valid normalized inputs.
7. Zero equipment load, transfer rate or contact factor produces no transfer.
8. Washing one farmland reduces only that farmland's loads.
9. Washing with reduction 0 changes nothing; reduction 1 clears all loads.
10. Missing records/classes return zero.
11. State validation copies only well-formed records and caps storage at 256 farmland records.
12. Repeated additions cannot exceed the configured maximum for a class.

## Engine integration gates

- Resolve world position to farmland ID through the verified FarmlandManager API on the server.
- Confirm that contact is genuine machinery/field work, not merely vehicle proximity.
- Sample only at bounded work intervals; never scan the entire map per frame.
- Persist records by farmland ID with a versioned XML schema.
- Test farmland ownership changes, map-specific farmland IDs, deleted farmland and savegame reload.
- Do not apply crop penalties until transfer values and gameplay effects are balanced in-game.
