# Spray & Hygiene — Implementation Notes

## Development build 0.5.0.0

The development foundation includes:
- modDesc and bootstrap listener.
- Validated default configuration.
- Pure Lua sprayer-condition model (condition, wear, calibration, nozzle-group blockage and coverage factor).
- Pure Lua cleaning/residue model (tank, lines and filters; abstract product classes and explicit carry-over matrix).
- Pure Lua spray-drift risk estimator with bounded inputs, risk bands and normalized explicit wind-to direction.
- Pure Lua farmland-level contamination model with bounded class loads, machinery-contact transfer, field washing and a 256-record storage cap.
- Server-gated, engine-independent state container for sprayer condition/cleaning records and farmland contamination.
- English and German localization starter files.
- Manual model test plans.

## Official API review
The public GDN LUADOC currently identifies Script v1.20.0.0 and Engine v1.20.0.0. It documents vehicle-specialization persistence hooks such as onLoad, saveToXMLFile and savegame XML path registration patterns. These are the intended route for per-vehicle state, rather than a separate local settings file. Actual vehicle specialization registration and callback integration remain unimplemented.

## Explicit limitations
- Models and state container are not connected to FS25 vehicle, weather, field or farmland callbacks.
- No specialization is registered or injected.
- The state container is not serialized to savegame XML and is not persistent across reloads.
- No multiplayer synchronization is implemented.
- Drift is a gameplay heuristic, not a calibrated physical deposition simulator.
- Farmland IDs must be supplied by a future server-side adapter after validated machinery/field contact.
- No native spray application, fill consumption, crop state or field state is changed.
- The mod has not yet been loaded in FS25 or run through GIANTS TestRunner.

## Safety boundary
All models are engine-independent and do not modify native fill levels or spray usage. Future field transfer must be server-authoritative, event-driven and use validated farmland IDs. Do not introduce per-frame world scans or crop penalties before runtime and balance testing.

## Next implementation gate
Choose and verify a persistent vehicle identity, implement the per-vehicle XML save/load adapter using the official specialization hooks, then implement the separate mission-level farmland save path. Keep native Sprayer processing untouched.
