# Spray & Hygiene — Implementation Notes

## Development build 0.3.0.0

The development foundation includes:
- modDesc and bootstrap listener.
- Validated default configuration.
- Pure Lua sprayer-condition model (condition, wear, calibration, nozzle-group blockage and coverage factor).
- Pure Lua cleaning/residue model (tank, lines and filters; abstract product classes and explicit carry-over matrix).
- Pure Lua spray-drift risk estimator with bounded inputs, risk bands and normalized explicit wind-to direction.
- English and German localization starter files.
- Manual model test plans.

## Explicit limitations

- The models are not yet connected to FS25 vehicle callbacks.
- No vehicle specialization is registered or injected.
- No savegame persistence or multiplayer synchronization is implemented.
- The drift estimator is a gameplay heuristic, not a calibrated physical spray-drift simulation.
- Wind direction is not read from the game; its sign convention must be validated in-game before use.
- No native spray application, fill consumption, wind, contamination or cleaning gameplay behavior is changed.
- The mod has not yet been loaded in FS25 or run through GIANTS TestRunner.

## Safety boundary

The condition model is independent of vehicle objects and native fill units. A future observer may call it only after successful server-side native spraying has been established. The cleaning model is data-only; rinse actions must validate water, costs, permission and server authority. The drift model accepts explicit input values only and must not be connected to WindUpdater until direction and authority behavior are runtime-verified.

## Next implementation gate

Validate the descriptor and bootstrap in the target game. Then implement the server-side observation adapter without overriding native Sprayer processing or deducting fill a second time.
