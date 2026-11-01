# Spray & Hygiene — Implementation Notes

## Development build 0.2.0.0

The initial development foundation now includes:
- `modDesc.xml` and bootstrap listener.
- Validated default configuration.
- Pure Lua sprayer-condition model (condition, wear, calibration, nozzle-group blockage and coverage factor).
- Pure Lua cleaning/residue model (tank, lines and filters; abstract product classes and explicit carry-over matrix).
- English and German localization starter files.

## Explicit limitations
- The models are not yet connected to FS25 vehicle callbacks.
- No vehicle specialization is registered or injected.
- No savegame persistence or multiplayer synchronization is implemented.
- No native spray application, fill consumption, wind, contamination or cleaning gameplay behavior is changed.
- The mod has not yet been loaded in FS25 or run through GIANTS TestRunner.

## Safety boundary
The condition model is deliberately independent of vehicle objects and native fill units. A future observer may call it only after successful server-side native spraying has been established. The cleaning model is a data model only; actual rinse actions must later validate water, costs, permission and server authority.

## Next implementation gate
Validate the mod descriptor and bootstrap in the target game. Then implement the server-side observation adapter without overriding native Sprayer processing or deducting fill a second time.
