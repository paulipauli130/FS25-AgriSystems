# Changelog

## [Unreleased]
- Continue engine integration, persistence, networking and runtime validation.

## [Farm Biosecurity 0.3.1.0] - 2026-11-01
### Changed
- Retry persistent husbandry identity acquisition after placeable finalization.
- Avoid writing nil disease IDs to XML.

## [Farm Biosecurity 0.3.0.0] - 2026-11-01
### Added
- PlaceableHusbandryAnimals-only specialization and per-placeable cohort save/load.
- Stable husbandry identity from the base-game persistent Placeable uniqueId.
- Subtype cohort model avoids persisting unstable engine cluster IDs.

## [Farm Biosecurity 0.2.2.0] - 2026-11-01
### Changed
- Bounded husbandry and group state storage.

## [Farm Biosecurity 0.2.1.0] - 2026-11-01
### Changed
- Disinfection requires the configured contact-time window.

## [Farm Biosecurity 0.2.0.0] - 2026-11-01
### Added
- Bounded server-gated group StateStore and conservative split/merge helpers.

## [Farm Biosecurity 0.1.0.0] - 2026-11-01
### Added
- Independent bootstrap and disease, quarantine, hygiene and score models.

## [Spray & Hygiene 0.7.0.0] - 2026-11-01
### Added
- Initial server-to-client Sprayer state snapshot.

## [Spray & Hygiene 0.6.0.0] - 2026-11-01
### Added
- Initial Sprayer specialization and per-vehicle XML save/load code.

All entries are development foundations, not certified releases.
