# Farm Biosecurity — Gameplay Model Test Plan

## Disease
1. New group starts susceptible.
2. Exposure is evaluated only after a confirmed contact event.
3. Zero risk never infects; a roll below risk accepts exposure.
4. A roll equal to or above risk rejects exposure.
5. Exposure moves susceptible to incubation; repeat exposure does not reset progression.
6. Incubation advances to infectious, then recovering, then recovered.
7. Invalid profiles and malformed state fail safely.
8. Time and risk inputs are bounded.

## Quarantine
1. New/returning group starts quarantined.
2. Duration alone does not release without request and hygiene compliance.
3. Early release request remains active until duration expires.
4. Release occurs only when every gate passes.

## Hygiene
1. Surface records are bounded and validated.
2. Dirt cleaning reduces dirt only.
3. Disinfection fails while dirt exceeds threshold.
4. Disinfection reduces contamination only after dirt is sufficiently low.
5. Invalid IDs and loads are rejected or clamped.

## Score
1. Components clamp to 0..1.
2. Weights normalize through configuration.
3. Zero total weight returns score 0.
4. Score is derived and does not mutate source records.

## Runtime gates
No engine integration, save/load or multiplayer tests are included. Validate cluster split/merge, server authority and dedicated-server behavior before enabling gameplay.
