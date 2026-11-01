# Development Roadmap

## Current status — implementation foundation started

Research and design are complete at source-review level. The first Spray & Hygiene bootstrap/configuration files are now committed. This is infrastructure only: no gameplay specialization or gameplay effect is implemented, and the mod has not yet been loaded in the game or run through GIANTS TestRunner.

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
- [ ] Runtime-load validation and GIANTS log review.
- [ ] Sprayer specialization registration and non-invasive observation.
- [ ] Server persistence/configuration and networking.
- [ ] Sprayer condition and coverage model.
- [ ] Cleaning/residue model.
- [ ] Wind provider and drift model behind runtime validation gate.
- [ ] Farmland contamination.
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
- No runtime feature is marked complete until tested in-game.
- Source review is not a substitute for current-patch runtime validation.
