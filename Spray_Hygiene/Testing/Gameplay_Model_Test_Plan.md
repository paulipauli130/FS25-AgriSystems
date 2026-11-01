# Spray & Hygiene — Gameplay Model Test Plan

## Scope

This plan covers the pure Lua model layer. It does not certify GIANTS engine integration. The models are not yet connected to vehicle callbacks, savegame XML or network events.

## Sprayer condition model

1. A newly created state has condition 100, wear 0 and calibration 100.
2. Invalid, NaN or infinite values are replaced with safe defaults.
3. Applying work with zero area changes no state.
4. Applying work with a positive area degrades condition and calibration without accessing any vehicle or fill-unit API.
5. Condition, wear, calibration and blockage remain within 0–100.
6. Blockage can be set and cleared independently for a nozzle group.
7. Servicing restores only the supplied condition/calibration values; it does not silently clear nozzle blockage.
8. Coverage factor remains between the configured minimum and 1.0.

## Cleaning/residue model

1. New state contains empty tank, line and filter residue collections.
2. Residue is stored by abstract product class and compartment.
3. Adding residue is bounded; repeated additions cannot exceed 1.0 per class/compartment.
4. Cleaning one compartment does not clear the other compartments.
5. Cleaning effectiveness 0 leaves residue unchanged; effectiveness 1 clears it.
6. Carry-over is calculated only from the explicit compatibility matrix; missing pairs default to zero.
7. Total residue is the sum of stored non-negative entries.

## Engine integration tests still required

- Load the mod in the exact target FS25 patch and inspect log.txt.
- Verify XML descriptor and all script paths.
- Verify modules remain inert when their toggles are disabled.
- Only connect condition degradation after successful native work-area processing is confirmed on the server.
- Never change native fill-unit levels or native spray usage.
- Test Precision Farming, AI, external fill sources and multiplayer before enabling the observer.
