# Sprayer Specialization — Runtime Test Plan

## Load and registration
1. Start a clean FS25 profile with only AgriSystems Spray & Hygiene enabled.
2. Confirm the mod is listed without XML or Lua load errors.
3. Confirm the registration log has no unknown/duplicate specialization errors.
4. Load a map and inspect log.txt for callback/schema errors.
5. Confirm only vehicle types with base Sprayer receive the specialization.
6. Confirm non-sprayer vehicles and placeables load normally.
7. Repeat with Precision Farming enabled and with a dedicated server.

## Native behavior regression
1. Spray a test field with the module defaults.
2. Compare native fill consumption and treated area against the mod disabled.
3. Test an implement using its own fill unit.
4. Test a sprayer drawing from an external fill source.
5. Test AI work and manual work.
6. Confirm no additional fill is deducted and no work-area state is modified by AgriSystems.

## Save/load
1. Save with a sprayer in default condition.
2. Change model values using a development-only test harness, save, restart and verify values reload.
3. Include multiple nozzle groups and residues in tank, lines and filters.
4. Test malformed values and unknown schema version; defaults must be used safely.
5. Test vehicle sale/deletion and reload; no orphaned per-vehicle record should remain because state is stored in that vehicle's save node.

## Multiplayer
1. Dedicated server saves vehicle state.
2. Client join and late join do not overwrite server state.
3. Reconnect and server restart preserve per-vehicle state.
4. Client-side calls cannot mutate persisted values.

## Release gates
- No runtime test is marked passed until the exact FS25 patch and test save are recorded.
- Verify the actual installed patch and matching GIANTS TestRunner before release.
