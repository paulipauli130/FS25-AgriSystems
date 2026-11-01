# Development Roadmap

## Current status

Spray & Hygiene contains four pure gameplay models, a state container, early Sprayer-only specialization, per-vehicle XML save/load code and an initial server-to-client snapshot. These engine-facing features are source-reviewed but not runtime-tested. Farm Biosecurity has an independent bootstrap, four pure gameplay models, a bounded StateStore, PlaceableHusbandryAnimals-only specialization and per-placeable cohort save/load code. Both mods have standalone Lua assertion suites and independent runtime packaging scripts. Neither mod is runtime-certified.

## Phase 1 — Research and specifications (complete)
- [x] Project structure and conventions.
- [x] Public GDN/API research and local FS25 source audit.
- [x] Sprayer native processing and Precision Farming extension-chain review.
- [x] WindUpdater access path, values and units source-verified.
- [x] Animal cluster identity, save/load, network and merge behavior source-verified.
- [x] FieldManager mapping clarified; farmland-level fallback selected.
- [x] Both technical specifications and multiplayer/persistence acceptance criteria.

## Phase 2 — Shared development conventions
- [x] Independent mod namespaces and configuration conventions.
- [x] Standalone Lua model assertion tests.
- [x] Independent runtime-only ZIP packaging script.
- [ ] Finalize shared event/XML schema conventions.
- [ ] Establish TestRunner invocation and supported game patch in local test environment.

## Phase 3 — Spray & Hygiene
- [x] Bootstrap, configuration and four pure gameplay models.
- [x] Server-gated engine-independent state container.
- [x] Sprayer-only specialization registration (source-reviewed).
- [x] Read-only native spray callback observer.
- [x] Per-vehicle XML schema/save/load code (runtime reload untested).
- [x] Initial server-to-client snapshot.
- [ ] Runtime-load validation and GIANTS log review.
- [ ] Incremental dirty-state replication.
- [ ] Connect condition/coverage to measured spraying work.
- [ ] Cleaning actions, costs and UI.
- [ ] Wind provider and drift integration.
- [ ] Mission-level farmland contamination persistence/contact adapter.

## Phase 4 — Farm Biosecurity
- [x] Independent modDesc, localization and bootstrap.
- [x] Disease progression, explicit contact exposure, quarantine, hygiene and score models.
- [x] Bounded server-gated StateStore and conservative split/merge helpers.
- [x] PlaceableHusbandryAnimals-only specialization registration (source-reviewed).
- [x] Stable per-placeable identity using base-game uniqueId.
- [x] Subtype-level cohort reconciliation to avoid persisting engine cluster IDs.
- [x] Per-placeable savegame XML schema and cohort/hygiene serialization code (runtime reload untested).
- [ ] Runtime-load and placeable save/reload validation.
- [ ] Quarantine clock and disease progression on game time.
- [ ] Server-to-client snapshot and dirty-state replication.
- [ ] Contact/exposure events and hygiene actions.
- [ ] Vehicle/equipment/visitor/barn integration and UI.

## Phase 5 — Validation and release
- [ ] Execute pure Lua model tests in a compatible Lua runtime.
- [ ] Run PowerShell packaging script and inspect ZIP contents.
- [ ] GIANTS TestRunner matching installed patch.
- [ ] Single-player save migration and regression.
- [ ] Dedicated-server host/client/late-join/reconnect tests.
- [ ] Precision Farming, AI, Courseplay and animal-system compatibility.
- [ ] Performance tests on large farms.
- [ ] Separate ZIP releases only after acceptance tests pass.

## Development rules
- The two mods install, run, save and uninstall independently.
- No third shared runtime dependency.
- Server owns gameplay state; clients submit validated intent.
- Disabled modules preserve vanilla behavior.
- Never modify native sprayer consumption in v1.
- No runtime feature is complete until tested on the target game patch.
- Source review is not runtime certification.
