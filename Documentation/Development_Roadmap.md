# Development Roadmap

## Current status

Spray & Hygiene contains four pure gameplay models, a state container, early Sprayer-only specialization, per-vehicle XML save/load code and an initial server-to-client snapshot. These engine-facing features are source-reviewed but not runtime-tested. Farm Biosecurity now has an independent bootstrap and four pure gameplay models. Neither mod is runtime-certified and no public release is available.

## Phase 1 — Research and specifications (complete)
- [x] Project structure and contribution conventions.
- [x] Public GDN/API research and local FS25 source audit.
- [x] Sprayer native processing and Precision Farming extension-chain review.
- [x] WindUpdater access path, return values and units source-verified.
- [x] Animal cluster identity, save/load, network and merge behavior source-verified.
- [x] FieldManager mapping clarified; farmland-level fallback selected.
- [x] Spray & Hygiene and Farm Biosecurity technical specifications.
- [x] Multiplayer authority, persistence, performance, compatibility and acceptance criteria.

## Phase 2 — Shared development conventions
- [ ] Define build/package scripts and versioning.
- [x] Define independent mod namespaces and initial configuration conventions.
- [ ] Finalize shared event and XML schema conventions.
- [ ] Establish TestRunner invocation and supported game patch in the local test environment.

## Phase 3 — Spray & Hygiene implementation
- [x] Bootstrap and validated configuration.
- [x] Pure Lua condition, cleaning, drift and farmland contamination models.
- [x] Server-gated engine-independent state container.
- [x] Sprayer specialization registration restricted to base Sprayer types (source-reviewed).
- [x] Read-only native spray callback observer.
- [x] Per-vehicle XML schema and save/load code (runtime reload not yet tested).
- [x] Initial server-to-client snapshot.
- [ ] Runtime-load validation and GIANTS log review.
- [ ] Incremental dirty-state replication.
- [ ] Connect condition/coverage model to measured successful spraying work.
- [ ] Cleaning actions, costs and in-game UI.
- [ ] Wind provider and drift model behind runtime validation gate.
- [ ] Mission-level farmland contamination persistence and contact adapter.
- [ ] Packaging and release validation.

## Phase 4 — Farm Biosecurity implementation
- [x] Independent modDesc and bootstrap foundation.
- [x] Group-level disease progression model.
- [x] Explicit contact-based exposure calculation.
- [x] Quarantine model with hygiene-compliance release gate.
- [x] Dirt cleaning and disinfection model.
- [x] Derived weighted Biosecurity Score.
- [ ] Placeable specialization registration.
- [ ] Husbandry identity and conservative cluster reconciliation.
- [ ] Group and husbandry persistence.
- [ ] Server networking and late-join snapshot.
- [ ] Quarantine and hygiene actions, costs and UI.
- [ ] Vehicle/equipment/visitor/barn integration.
- [ ] Runtime validation and packaging.

## Phase 5 — Validation and release
- [ ] GIANTS TestRunner matching the installed patch.
- [ ] Single-player regression and save migration.
- [ ] Dedicated-server host/client/late-join/reconnect tests.
- [ ] Precision Farming, AI, Courseplay and animal-system compatibility.
- [ ] Performance tests on large farms.
- [ ] Separate ZIP releases; publish only after all acceptance tests pass.

## Development rules
- The two mods must install, run, save and uninstall independently.
- No third shared mod dependency. Shared source may be copied into each package at build time only.
- Server owns gameplay state; clients submit validated intent.
- Disabled modules must preserve vanilla behavior.
- Never modify native sprayer consumption in v1.
- No runtime feature is marked complete until the relevant current-patch tests pass.
- Source review is not a substitute for runtime validation.
