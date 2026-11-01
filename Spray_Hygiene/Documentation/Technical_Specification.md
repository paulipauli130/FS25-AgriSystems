# AgriSystems Spray & Hygiene — Technical Specification

Status: implementation-ready design; runtime gates explicitly retained. Target: FS25 PC/Mac, single-player and dedicated-server multiplayer. Independent package: `FS25_AgriSystems_SprayHygiene.zip`.

## 1. Scope and principles
Four independently configurable modules: (1) spray drift/off-target exposure, (2) sprayer condition/nozzle performance/application quality, (3) tank/line/filter cleaning and product carry-over, (4) mechanical field contamination transfer. Preserve native crop application and native fill consumption. No replacement of density-map application, no second fill deduction, no CFD, no per-nozzle 3D hydraulic simulation, no real chemical compatibility/label claims. All product classes are game abstractions.

## 2. Runtime architecture and authority
Script-only specialization mod, PC/Mac. Server is sole authority for gameplay state, calculations, persistence and validation. Clients send action requests only. Server validates sender, farm permission, ownership/access, object reference, distance, tool state, resources and cooldown. Initial snapshot on join; compact dirty-state deltas afterward. No per-frame world scans. Missing API/data must fail safely and log once. Save state in mod-owned versioned savegame XML; local modSettings only for UI preferences.

## 3. Verified FS25 interfaces
### Wind
Full decompiled source confirms `g_currentMission.environment.weather.windUpdater`; `getCurrentValues()` returns dirX, dirZ, velocity m/s, cirrus factor. Listener methods add/removeWindChangedListener and callback setWindValues exist. Guard the path and finite values. Direction sign (wind-to/from) remains a runtime test gate; drift penalties stay disabled/neutral until confirmed. Server authority and listener lifecycle also require dedicated-server/map-transition tests.
### Sprayer
Base callbacks: onStartWorkAreaProcessing, processSprayerArea, onEndWorkAreaProcessing, getSprayerUsage and fill-level change callback. Native usage is computed and deducted by base game at successful end. External source may have nil sprayVehicle. Precision Farming wraps usage, area processing and end callback. Hard rule: never deduct usage, mutate native usage/workAreaParameters, or override Sprayer/ExtendedSprayer processing in v1. Observe successful processing server-side after callback order is verified.
### Farmland/fields
Use FarmlandManager world-position-to-farmland lookup and owner/access APIs. FieldManager:getFieldById maps farmland ID to Field object; it is not coordinate lookup. No getFieldAtWorldPosition in FieldManager. V1 contamination is farmland-level.
### Registration
Register unique namespaced specialization once; inject idempotently only into vehicle types containing base Sprayer during validation before finalization. Finalization registers callbacks/events/listeners. Skip unsupported types cleanly.

## 4. Gameplay models
### Drift
Separate nozzle propensity, transport and receptor exposure. Use bounded deterministic model: `P = clamp(W × D × H × V × E × C, 0, Pmax)`; W wind response (m/s), D droplet/nozzle profile, H boom height, V forward-speed/turbulence factor, E weather evaporation modifier only when reliable inputs exist, C condition/stability. Transport direction uses validated wind vector; receptor exposure = propensity × distance attenuation × receptor sensitivity × exposure interval. No claim of exact physical distance. Low wind is not automatically safe; inversion/dead-calm modifier only if supported inputs exist. Feedback shows risk band, downwind direction and affected farmland; configurable deposition effects, never silent arbitrary crop destruction.
### Equipment condition
Persistent condition 0–100, wear 0–100, blockage 0–100 per nozzle group, calibration/service state, optional profile. Condition affects coverage/uniformity/efficacy, not native liters. Damaged nozzles may distort pattern or flow; v1 represents quality penalty, not invented hydraulic pressure. Generic fallback profile required. Service/calibration consumes configurable time/cost/resources.
### Cleaning
Track bounded residue in tank, lines/boom and filter/nozzle group (aggregate where necessary). Emptying/product switch does not clear residue. Rinse/flush consumes water/time/optional cleaner; flushing lines and cleaning filters/nozzles are distinct. Carry-over = residual load × configured compatibility coefficient. Compatibility classes are mod-defined abstractions, not chemical facts.
### Field transfer
Store bounded contamination per farmland ID (e.g. weed seed, crop residue, pathogen-transfer load). Increase only on relevant machinery/field contact via event-driven work-state and coarse sampling. Reduce at wash/clean actions. No terrain scan. Exact field-level geometry deferred.

## 5. Configuration schema
Versioned server/save settings: module toggles; drift wind scale/risk cap/update interval/buffer/weather modifier; condition degradation per hectare/blockage/service cost/min coverage; cleaning water/flush/filter factors and compatibility matrix; farmland transfer rate/wash reduction/max load; debug toggle/log level. Validate ranges, clamp/revert invalid values, warn once, ignore unknown keys, migrate old schemas. Local preferences must not control shared simulation.

## 6. Persistence and identity
Unique XML root and schema version. Persist sprayer condition/wear/blockage/calibration/residues, farmland contamination keyed by farmland ID, server settings and migration version. Do not persist runtime node IDs as stable identity. Reconcile missing/removed implements safely; ignore unknown/orphaned records safely. Mod removal must not corrupt vanilla save.

## 7. Events and UI
Actions: service, calibrate, rinse tank, flush lines, clean filter/nozzles, wash equipment. Events carry bounded primitives and valid network object refs. Server recomputes costs/results and rejects stale refs/unauthorized requests. UI: module status, condition/coverage, residues and actions, drift risk/direction only when valid, farmland contamination. English/German localization; standard in-game UI; no external service.

## 8. Performance/compatibility
No global per-frame scans. Event-driven spraying and bounded wind sampling; dirty-state replication; cached type checks; bounded records. Test Precision Farming on/off, AI, external fill source, attached tank, base sprayer variants, Courseplay if installed, dedicated server, map transitions and other sprayer mods. Never overwrite native extension chains.

## 9. Acceptance tests
- All modules off: vanilla spray area and fill consumption unchanged.
- No double consumption; own and external fill sources work.
- PF on/off retains native behavior/statistics.
- Missing wind yields no false drift; controlled wind proves vector sign and downwind direction.
- Identical inputs/config/seed produce deterministic drift.
- Condition changes coverage feedback but not native consumption.
- Rinse/flush reduces residues; carry-over respects configured class matrix.
- Farmland contamination persists across reload.
- Client cannot forge state or service without permission.
- Late join/reconnect/restart synchronize and persist state.
- Invalid config recovers; no per-frame full-world scan; uninstall preserves vanilla save.

## 10. Runtime release gates
Verify wind sign, dedicated-server weather authority, listener cleanup/map transition, callback ordering with PF/AI/external tanks, event serialization/late join. Field contamination stays farmland-level in v1. Run GIANTS TestRunner matching installed game patch, then SP and dedicated-server regression matrix.

## 11. Packaging
ZIP root contains modDesc.xml and runtime assets only. Exclude docs/tests/research/.git/tools/logs. Separate independent package and version. Filename remains `FS25_AgriSystems_SprayHygiene.zip`.
