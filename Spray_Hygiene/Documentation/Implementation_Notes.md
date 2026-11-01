# Spray & Hygiene — Implementation Notes

## Development build 0.4.0.0

The development foundation includes:
- modDesc and bootstrap listener.
- Validated default configuration.
- Pure Lua sprayer-condition model (condition, wear, calibration, nozzle-group blockage and coverage factor).
- Pure Lua cleaning/residue model (tank, lines and filters; abstract product classes and explicit carry-over matrix).
- Pure Lua spray-drift risk estimator with bounded inputs, risk bands and normalized explicit wind-to direction.
- Pure Lua farmland-level contamination model with bounded class loads, machinery-contact transfer, field washing and a 256-record storage cap.
- English and German localization starter files.
- Manual model test plans.

## Explicit limitations

- Models are not connected to FS25 vehicle, weather, field or farmland callbacks.
- No specialization is registered or injected.
- No savegame persistence or multiplayer synchronization is implemented.
- Drift is a gameplay heuristic, not a calibrated physical deposition simulator.
- Farmland IDs must be supplied by a future server-side adapter after validated machinery/field contact.
- No native spray application, fill consumption, crop state or field state is changed.
- The mod has not yet been loaded in FS25 or run through GIANTS TestRunner.

## Safety boundary

All models are engine-independent and do not modify native fill levels or spray usage. Future field transfer must be server-authoritative, event-driven and use validated farmland IDs. Do not introduce per-frame world scans or crop penalties before runtime and balance testing.

## Next implementation gate

Implement the server-owned state container and versioned persistence schema, then validate mod loading in the target game. Keep native Sprayer processing untouched.
