# Farm Biosecurity — Gameplay Model Test Plan

## Disease
1. New group starts susceptible.
2. Exposure is evaluated only after confirmed contact.
3. Zero risk never infects; roll below risk accepts exposure; roll equal/above rejects.
4. Exposure moves susceptible to incubation; repeated exposure does not reset progression.
5. Incubation advances to infectious, then recovering, then recovered.
6. Split copies disease state to every child group.
7. Merge retains the most advanced disease state and highest severity/exposure.
8. Invalid profiles and malformed state fail safely.

## Quarantine
1. New/returning group starts quarantined.
2. Duration alone does not release without request and hygiene compliance.
3. Split copies quarantine restrictions.
4. Merge keeps quarantine active if any source group remains quarantined.
5. Merged quarantine uses the earliest start, longest duration and conservative compliance.

## Hygiene and score
1. Dirt cleaning reduces dirt only.
2. Disinfection fails while dirt exceeds threshold.
3. Score components clamp to 0..1; weights normalize; score does not mutate source state.

## StateStore
1. Client instances reject mutations and loading.
2. Group count cap is enforced per husbandry.
3. Engine cluster bindings are transient and cleared on load.
4. Exported state is detached from live state.
5. Malformed records are skipped; valid disease/quarantine state survives round-trip.

## Runtime gates
No engine integration, save/load or multiplayer tests are included. Verify exact FS25 split/merge callbacks and stable mod-owned IDs before using these helpers in gameplay.
