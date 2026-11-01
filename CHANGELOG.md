# Changelog

All notable project changes are documented here.

## [Unreleased]
- Continue engine integration, persistence, networking and runtime validation.

## [Farm Biosecurity 0.2.1.0] - 2026-11-01
### Changed
- Disinfection now has an explicit contact-time window; contamination is reduced only after the required time elapses.
- Group split capacity is preflighted; merge rejects duplicate or invalid IDs.

## [Farm Biosecurity 0.2.0.0] - 2026-11-01
### Added
- Bounded server-gated group StateStore.
- Transient engine-cluster-to-mod-group mapping, excluded from persistence.
- Conservative disease-state split/merge helpers.
- Quarantine inheritance across split/merge operations.

## [Farm Biosecurity 0.1.0.0] - 2026-11-01
### Added
- Independent modDesc and bootstrap foundation.
- Validated configuration, group disease progression and explicit contact-based exposure.
- Quarantine, surface hygiene and derived Biosecurity Score models.

## [Spray & Hygiene 0.7.0.0] - 2026-11-01
### Added
- Initial server-to-client Sprayer condition and cleaning snapshot.
- Bounded stream serialization for nozzle groups and residue entries.

### Safety
- Client state remains non-authoritative.
- Native spray application, fill consumption and work-area parameters remain untouched.

## [Spray & Hygiene 0.6.0.0] - 2026-11-01
### Added
- Initial Sprayer-only vehicle specialization registration.
- Read-only native spray callback observer.
- Per-vehicle savegame XML schema and serialization.

## [Spray & Hygiene 0.5.0.0] - 2026-11-01
### Added
- Server-gated engine-independent Spray & Hygiene state container.

## [Spray & Hygiene 0.4.0.0] - 2026-11-01
### Added
- Farmland-level contamination model with bounded records and class-specific loads.

All versions above are development foundations, not certified releases.
