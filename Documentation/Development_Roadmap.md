# Development Roadmap

## Current status — models, state container and early Sprayer specialization

Spray & Hygiene contains four pure gameplay models, a server-gated state container, Sprayer-only specialization registration, per-vehicle XML save/load code, a read-only native callback observer and an initial server-to-client snapshot. All engine-facing work remains source-reviewed and untested in FS25. No gameplay penalties or native spray changes are active.

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
- [x] Bootstrap and validated configuration foundation.
- [x] Pure Lua condition, cleaning, drift and farmland contamination models.
- [x] Server-gated engine-independent state container (not mission-persistent).
- [x] Sprayer specialization registration restricted to base Sprayer types (source-reviewed).
- [x] Read-only native spray callback observer (diagnostic count only).
- [x] Per-vehicle XML schema and save/load code (runtime reload not yet tested).
- [x] Initial server-to-client snapshot for per-vehicle condition and cleaning state.
- [ ] Runtime-load validation and GIANTS log review.
- [ ] Validate registration hook on exact target patch and mod load order.
- [ ] Test per-vehicle save/reload and stream serialization in game.
- [ ] Incremental dirty-state replication.
- [ ] Connect condition/coverage model to measured successful spraying work.
- [ ] Cleaning actions, costs and in-game UI.
- [ ] Wind provider and drift model behind runtime validation gate.
- [ ] Mission-level farmland contamination persistence and contact adapter.
- [ ] UI/localization completion and packaging.

## Phase 4 — Farm Biosecurity implementation
- [ ] Minimal modDesc and placeable specialization registration.
- [ ] Husbandry identity/reconciliation and persistence.
- [ ] Quarantine and disease progression.
- [ ] Vehicle/equipment/visitor/barn hygiene.
- [ ] Biosecurity Score and UI/localization.
- [ ] Packaging.

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
