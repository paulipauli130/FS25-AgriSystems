# Farm Biosecurity — Runtime Test Plan

## Registration and load
1. Enable only Farm Biosecurity and start a test save with one animal husbandry.
2. Check log.txt for missing source files, specialization registration errors, XML schema errors or Lua exceptions.
3. Confirm only placeable types with PlaceableHusbandryAnimals receive the specialization.
4. Confirm non-husbandry placeables load normally.
5. Repeat with modded animal types and on a dedicated server.

## Cohort identity and persistence
1. Add at least two animal subtypes to a husbandry.
2. Confirm each configured subtype creates one logical cohort.
3. Add multiple engine clusters of the same subtype; confirm they remain one cohort.
4. Save, exit, reload and verify cohort disease/quarantine state and elapsed game hours.
5. Split/merge same-subtype engine clusters and confirm the logical cohort state is unchanged.
6. Sell a husbandry and verify no state is applied to another placeable with a different uniqueId.

## Progression
1. Verify the placeable hourly callback advances disease state by one in-game hour.
2. Verify quarantine duration uses the persisted per-husbandry clock.
3. Save/reload midway through incubation and quarantine; progression must resume correctly.
4. Confirm no infection occurs without an explicit server-side contact event.

## Multiplayer
1. Dedicated server owns progression and savegame state.
2. Client join receives cohort, quarantine and hygiene snapshot.
3. Late join receives the same state as existing clients.
4. Client state is never written back to server.
5. Confirm malformed stream counts cannot exceed configured bounds.

## Release gates
- Registration, save/reload, stream alignment and callback ordering are not considered passed until tested on the exact installed FS25 patch.
- Check that no placeable stream desynchronization occurs when a client placeable uniqueId is unavailable at callback entry.
