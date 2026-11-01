# Changelog

All notable project changes are documented here.

## [Unreleased]
- Continue engine integration, persistence, networking and runtime validation.

## [Farm Biosecurity 0.1.0.0] - 2026-11-01
### Added
- Independent modDesc and bootstrap foundation.
- Validated configuration with module toggles and normalized score weights.
- Group-level disease progression and explicit contact-based exposure models.
- Quarantine model with hygiene-compliance release gate.
- Surface dirt-cleaning and disinfection model.
- Derived weighted Biosecurity Score and component breakdown.
- Manual gameplay model test plan.

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
