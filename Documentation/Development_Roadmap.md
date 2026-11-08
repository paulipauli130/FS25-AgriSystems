# Development Roadmap

## Current status

Both independent mods have pure gameplay models, bootstraps, standalone Lua model test suites and runtime-only packaging. Spray & Hygiene has a Sprayer specialization, per-vehicle save/load, savegame-specific host settings, an initial server-to-client snapshot and incremental dirty-state update-stream callbacks. Farm Biosecurity has disease, quarantine, hygiene and score models, a husbandry specialization, subtype cohorts, per-placeable persistence, hourly progression and an initial state snapshot. Engine-facing code remains untested in actual FS25 gameplay. No public release is available.

## Phase 1 — Research and specifications
- [x] Project structure, conventions and technical specifications.
- [x] Public GDN/API research and local FS25 source audit.
- [x] Sprayer processing/PF extension-chain review.
- [x] WindUpdater path and values source-reviewed.
- [x] Animal cluster identity, save/load and merge behavior source-reviewed.
- [x] Farmland mapping clarified.
- [x] Multiplayer authority, persistence and compatibility criteria.

## Phase 2 — Development conventions
- [x] Independent mod namespaces/configuration.
- [x] Standalone Lua model assertion tests.
- [x] GitHub Actions workflow for Lua model tests.
- [x] Independent runtime-only ZIP packaging script with source/localization validation.
- [ ] Confirm installed game patch and matching GIANTS TestRunner.

## Phase 3 — Spray & Hygiene
- [x] Bootstrap, configuration and four pure gameplay models.
- [x] Server-gated state container.
- [x] Sprayer-only specialization and server-side operating-time wear observer.
- [x] Per-vehicle XML schema/save/load code (runtime reload untested).
- [x] Initial server-to-client snapshot.
- [x] Incremental dirty-state update-stream callbacks (source implemented; runtime test pending).
- [ ] Runtime-load, save/reload and multiplayer log validation.
- [ ] Connect condition/coverage to measured spraying work.
- [ ] Cleaning actions, costs and UI.
- [ ] Wind provider/drift integration.
- [ ] Mission-level farmland contamination persistence/contact adapter.

## Phase 4 — Farm Biosecurity
- [x] Independent modDesc, localization and bootstrap.
- [x] Disease, contact-exposure, quarantine, hygiene and score models.
- [x] Bounded server-gated group StateStore and conservative split/merge helpers.
- [x] PlaceableHusbandryAnimals-only specialization and persistent placeable identity.
- [x] Subtype-level logical cohorts; no engine cluster IDs persisted.
- [x] Per-placeable save/load for disease, quarantine, hygiene and elapsed game hours.
- [x] Server-side hourly disease/quarantine progression hook.
- [x] Initial server-to-client cohort/hygiene snapshot.
- [ ] Runtime-load, callback-order, save/reload and stream validation.
- [ ] Contact/exposure events and quarantine release actions.
- [ ] Hygiene cleaning/disinfection actions and costs.
- [ ] Incremental dirty-state replication.
- [ ] Vehicle/equipment/visitor/barn integration and UI.

## Phase 5 — Validation and release
- [x] Execute pure Lua model tests in GitHub Actions.
- [x] Run PowerShell packaging script in GitHub Actions and generate both mod ZIP artifacts.
- [ ] Manually inspect package contents and test installation in FS25.
- [ ] Test each mod separately in the actual FS25 patch.
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
