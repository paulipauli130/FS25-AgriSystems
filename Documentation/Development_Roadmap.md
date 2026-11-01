# Development Roadmap

## Current status — specification phase complete, implementation not started
The source-level API research has been expanded using the complete owner-provided decompiled FS25 script tree. Both independent mod specifications are documented and ready to guide implementation. No Lua implementation or modDesc has been committed yet.

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
- [ ] Define namespaced event and XML schema conventions.
- [ ] Establish TestRunner invocation and supported game patch in the local test environment.

## Phase 3 — Spray & Hygiene implementation
- [ ] Minimal modDesc and specialization registration.
- [ ] Server persistence/configuration and networking.
- [ ] Non-invasive Sprayer observation and condition model.
- [ ] Cleaning/residue model.
- [ ] Wind provider and drift model behind runtime validation gate.
- [ ] Farmland contamination.
- [ ] UI/localization and packaging.

## Phase 4 — Farm Biosecurity implementation
- [ ] Minimal modDesc and placeable specialization registration.
- [ ] Husbandry identity/reconciliation and persistence.
- [ ] Quarantine and disease progression.
- [ ] Vehicle/equipment/visitor/barn hygiene.
- [ ] Biosecurity Score and UI/localization.
- [ ] Packaging.

## Phase 5 — Validation and release
- [ ] GIANTS TestRunner for target patch.
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
- Research/specification completion does not imply runtime certification.
