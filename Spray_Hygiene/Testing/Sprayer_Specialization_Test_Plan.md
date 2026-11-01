# Sprayer Specialization — Runtime Test Plan

## Load and registration
1. Start a clean FS25 profile with only AgriSystems Spray & Hygiene enabled.
2. Confirm the mod is listed without XML or Lua load errors.
3. Confirm the registration log has no unknown/duplicate specialization errors.
4. Load a map and inspect log.txt for callback/schema errors.
5. Confirm only vehicle types with base Sprayer receive the specialization.
6. Confirm non-sprayer vehicles and placeables load normally.
7. Repeat with Precision Farming enabled and on a dedicated server.

## Native behavior regression
1. Spray a test field with the mod enabled and compare against the mod disabled.
2. Compare native fill consumption and treated area.
3. Test an implement using its own fill unit and an external fill source.
4. Test AI work and manual work.
5. Confirm no additional fill is deducted and no work-area state is modified by AgriSystems.

## Save/load
1. Save with a sprayer in default condition.
2. Use a development-only harness to set condition, calibration, nozzle groups and residues.
3. Save, restart and verify all values reload.
4. Test malformed values and unknown schema version; defaults must be used safely.
5. Test vehicle sale/deletion and reload; no orphaned per-vehicle record should remain.

## Multiplayer snapshot
1. Dedicated server owns and saves authoritative state.
2. Client join receives condition, calibration, nozzle blockage and residues.
3. Late join receives the same state as already connected clients.
4. Client-side state changes do not overwrite server state.
5. Confirm stream counts are bounded and malformed data is safely clamped.

## Release gates
- No runtime test is marked passed until the exact FS25 patch and test save are recorded.
- Verify the actual installed patch and matching GIANTS TestRunner before release.
