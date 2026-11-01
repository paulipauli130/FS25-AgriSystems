# Development Roadmap

## Current status — four pure gameplay models committed

Research and design are complete at source-review level. Spray & Hygiene now contains a bootstrap, validated configuration, sprayer-condition, cleaning/residue, spray-drift and farmland-contamination data models. These are not connected to FS25 callbacks, persistence or networking. No gameplay effect is active and no in-game validation has been performed.

## Phase 1 — Research and specifications (complete)
- [x] Project structure and contribution conventions.
- [x] Public GDN/API research and local FS25 source audit.
- [x] Sprayer native processing and Precision Farming extension-chain review.
- [x] WindUpdater access path, return values and units source-verified.
- [x] Animal cluster identity, save/load, network and merge behavior source-verified.
- [x] FieldManager mapping clarified; farmland-level fallback selected.
- [x] Spray & Hygiene technical specification.
- [x] Farm Biosecurity technical specification.
- [x] Multiplayer authority, persistence, performance, compatibility and acceptance criteria.

## Phase 2 — Shared development conventions
- [ ] Define build/package scripts and versioning.
- [x] Define independent mod namespaces and initial configuration conventions.
- [ ] Finalize shared event and XML schema conventions.
- [ ] Establish TestRunner invocation and supported game patch in the local test environment.

## Phase 3 — Spray & Hygiene implementation
- [x] Initial modDesc and bootstrap/configuration foundation committed (not runtime-tested).
- [x] Pure Lua condition and cleaning/residue models committed (not engine-integrated).
- [x] Pure Lua bounded spray-drift risk estimator committed (not engine-integrated or calibrated).
- [x] Pure Lua farmland-level contamination model committed (not engine-integrated).
- [ ] Runtime-load validation and GIANTS log review.
- [ ] Sprayer specialization registration and non-invasive observation.
- [ ] Server persistence/configuration and networking.
- [ ] Connect condition/coverage model to verified successful spraying events.
- [ ] Cleaning actions, costs and in-game UI.
- [ ] Wind provider and drift model behind runtime validation gate.
- [ ] Farmland contact adapter and contamination effects.
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
