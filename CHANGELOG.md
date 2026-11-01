# Changelog

## [Unreleased]
- Continue engine integration and runtime validation.

## [2026-11-01] — API and integration corrections
- Corrected both specialization registrations to use the exact unprefixed names stored by FS25 SpecializationManager.
- Aligned per-vehicle and per-placeable savegame XML paths with specialization-specific serialization keys.
- Documented public GDN TypeManager, SpecializationManager and Placeable serialization behavior.

## [Farm Biosecurity 0.4.1.0]
- Enabled base Placeable hourly callback subscription for husbandry progression.

## [Farm Biosecurity 0.4.0.0]
- Added placeable specialization, subtype cohort state, per-placeable save/load, hourly progression and initial server-to-client snapshot.

## [Farm Biosecurity 0.3.0.0]
- Added husbandry specialization and persistent subtype cohort identity.

## [Farm Biosecurity 0.2.0.0]
- Added bounded server-side group state store and conservative split/merge helpers.

## [Farm Biosecurity 0.1.0.0]
- Added independent bootstrap and disease, quarantine, hygiene and score models.

## [Spray & Hygiene 0.7.0.0]
- Added initial server-to-client Sprayer state snapshot.

## [Spray & Hygiene 0.6.0.0]
- Added Sprayer specialization and per-vehicle XML save/load foundation.

## [Spray & Hygiene 0.5.0.0]
- Added server-gated engine-independent state container.

All entries are development foundations, not certified releases.
