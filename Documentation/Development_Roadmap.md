# Development Roadmap

## Current status

Spray & Hygiene has four pure models, a state container, early Sprayer-only specialization, per-vehicle XML save/load and initial server-to-client snapshot. Farm Biosecurity has an independent bootstrap, four pure models, bounded group StateStore, PlaceableHusbandryAnimals-only specialization, per-placeable cohort persistence and server-side hourly progression hooks. All engine-facing features are source-reviewed but not runtime-tested. Both mods have standalone Lua model tests and independent packaging scripts. No public release is available.

## Phase 1 — Research and specifications (complete)
- [x] Project structure and conventions.
- [x] Public GDN/API research and local FS25 source audit.
- [x] Sprayer native processing and Precision Farming extension-chain review.
- [x] WindUpdater access path, values and units source-verified.
- [x] Animal cluster identity, save/load, network and merge behavior source-verified.
- [x] FieldManager mapping clarified; farmland-level fallback selected.
- [x] Both technical specifications and multiplayer/persistence criteria.

## Phase 2 — Shared development conventions
- [x] Independent mod namespaces/configuration.
- [x] Standalone Lua model assertion tests.
- [x] Independent runtime-only ZIP packaging script.
- [ ] Finalize shared event/XML schema conventions.
- [ ] Establish TestRunner invocation and installed game patch.

## Phase 3 — Spray & Hygiene
- [x] Bootstrap, configuration and four pure gameplay models.
- [x] Server-gated state container.
- [x] Sprayer-only specialization and read-only native callback observer.
- [x] Per-vehicle XML save/load code (runtime reload untested).
- [x] Initial server-to-client snapshot.
- [ ] Runtime-load validation and GIANTS log review.
- [ ] Incremental dirty-state replication.
- [ ] Connect condition/coverage to measured spraying work.
- [ ] Cleaning actions, costs and UI.
- [ ] Wind provider/drift integration.
- [ ] Mission-level farmland contamination persistence/contact adapter.

## Phase 4 — Farm Biosecurity
- [x] Independent modDesc, localization and bootstrap.
- [x] Disease, contact-exposure, quarantine, hygiene and score models.
- [x] Bounded server-gated group StateStore and conservative split/merge helpers.
- [x] PlaceableHusbandryAnimals-only specialization and persistent placeable identity.
- [x] Subtype-level logical cohorts, excluding engine cluster IDs from persistence.
- [x] Per-placeable save/load for disease, quarantine and hygiene state.
- [x] Server-side hourly progression hook for disease and quarantine.
- [ ] Runtime-load, callback-order and save/reload validation.
- [ ] Contact/exposure event integration and quarantine release actions.
- [ ] Hygiene cleaning/disinfection actions and costs.
- [ ] Server-to-client snapshot and dirty-state replication.
- [ ] Vehicle/equipment/visitor/barn integration and UI.

## Phase 5 — Validation and release
- [ ] Execute pure Lua model tests in a compatible Lua runtime.
- [ ] Run PowerShell packaging script and inspect ZIP contents.
- [ ] GIANTS TestRunner matching installed patch.
- [ ] Single-player save migration/regression.
- [ ] Dedicated-server host/client/late-join/reconnect tests.
- [ ] Precision Farming, AI, Courseplay and animal-system compatibility.
- [ ] Performance tests on large farms.
- [ ] Release separate ZIPs only after acceptance tests pass.

## Development rules
- Mods install, run, save and uninstall independently.
- No third shared runtime dependency.
- Server owns gameplay state; clients submit validated intent.
- Disabled modules preserve vanilla behavior.
- Never modify native sprayer consumption in v1.
- No runtime feature is complete until tested on the target patch.
