# State Store — Model Test Plan

## Scope
Tests the server-owned, engine-independent state container. It does not test FS25 XML persistence, network events, vehicle identity resolution or savegame callbacks.

## Cases
1. Server construction creates schema version 1 with empty vehicle and farmland records.
2. Client instances reject load and all mutations.
3. A valid vehicle key can be initialized and returns default condition and cleaning state.
4. A vehicle record can be replaced; model validators clamp condition and residue values.
5. Invalid, empty, non-string and overlong vehicle keys are rejected.
6. The 512-vehicle cap prevents new records but permits updates/removal of existing records.
7. Removing an unknown vehicle returns false; removing an existing record marks state dirty.
8. Field contamination is validated through the existing 256-farmland cap and configured maximum load.
9. Loading malformed data returns a safe validated state and clears dirty state.
10. Exported data is detached; editing exported nested tables must not mutate live state.
11. markSaved clears dirty state; subsequent mutation sets it again.
12. Schema version is always normalized to the current version on load.

## Runtime gates
- Stable vehicle key must be selected from a verified persistent game identifier before engine integration.
- XML read/write adapter and savegame schema registration are not implemented here.
- Multiplayer replication and late-join snapshots are not implemented.
- Never claim savegame persistence until reload tests pass in FS25.
