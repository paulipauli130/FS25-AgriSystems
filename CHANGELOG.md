# Changelog

## [Unreleased]
- Continue engine integration, persistence, networking and runtime validation.

## [Farm Biosecurity 0.2.2.0] - 2026-11-01
### Changed
- Added a hard cap of 128 husbandry records and clamps the per-husbandry group cap.
- Retained the 1024-surface limit per husbandry.

## [Farm Biosecurity 0.2.1.0] - 2026-11-01
### Changed
- Disinfection now has an explicit contact-time window.
- Group split capacity is preflighted; merge rejects duplicate or invalid IDs.

## [Farm Biosecurity 0.2.0.0] - 2026-11-01
### Added
- Bounded server-gated group StateStore and transient engine-cluster mapping.
- Conservative disease split/merge helpers and quarantine inheritance.

## [Farm Biosecurity 0.1.0.0] - 2026-11-01
### Added
- Independent mod bootstrap, validated configuration and pure disease, quarantine, hygiene and score models.

## [Spray & Hygiene 0.7.0.0] - 2026-11-01
### Added
- Initial server-to-client Sprayer condition and cleaning snapshot.

## [Spray & Hygiene 0.6.0.0] - 2026-11-01
### Added
- Initial Sprayer-only specialization and per-vehicle XML save/load code.

## [Spray & Hygiene 0.5.0.0] - 2026-11-01
### Added
- Server-gated engine-independent state container.

## [Spray & Hygiene 0.4.0.0] - 2026-11-01
### Added
- Farmland-level contamination model.

All entries are development foundations, not certified releases.
