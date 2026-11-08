# Changelog

## [Unreleased]
- Continue FS25 runtime integration and validation.

## [Spray & Hygiene 1.0.1.0] - 2026-11-08
### Added
- Incremental server-to-client synchronization for sprayer condition and cleaning state through FS25 vehicle dirty flags and update streams.
- Deterministic ordering of bounded nozzle-group and residue entries in network snapshots.
- Regression coverage for operating-time wear and zero-wear configuration.

### Validation
- Lua syntax, model tests and package validation are covered by CI.
- Multiplayer update-stream behavior still requires an in-game host/client test; this is not a certified release.

## [Spray & Hygiene 1.0.0.0] - 2026-11-05
### Added
- Savegame-specific persistence for host settings.
- Improved the in-game status and settings layout.
- Fixed the native menu icon resource and binary option state refresh.

### Validation
- Savegame settings persistence and in-game callback/UI behavior require runtime confirmation.

## [Spray & Hygiene 0.8.8.0] - 2026-11-03
### Added
- Host-only in-game controls for the mod master switch, wear, calibration degradation and wear-rate multiplier.
- Server-side operating-time wear and calibration degradation after successful native spray work.
- Updated generated ESC menu icon with a monochrome sprayer pictogram.

### Validation
- In-game callback/UI validation remains open.

## [Spray & Hygiene 0.8.7.0] - 2026-11-03
### Fixed
- Resolve the locally controlled vehicle through the documented FS25 `g_localPlayer:getCurrentVehicle()` API before mission/player compatibility fallbacks.
- Add a one-time vehicle-resolution diagnostic, including the selected source and local-player vehicle state, so a missing reference is visible in the log.

### Validation
- Source change is based on GIANTS FS25 Lua documentation. In-game confirmation is still pending.

## [Farm Biosecurity 0.4.3.0] - 2026-11-02
### Changed
- Advanced the independent Farm Biosecurity development build to 0.4.3.0.
- Current foundation includes husbandry specialization, subtype-level cohorts, per-placeable persistence, hourly server-side progression and an initial client snapshot.
- Runtime callback order, save/reload and multiplayer behavior remain unverified in FS25.

## [Spray & Hygiene 0.8.6.0] - 2026-11-02
### Added
- Native in-game status page for sprayer condition, wear, calibration, nozzle blockage and residue model values.
- Runtime diagnostics for specialization loading and sprayer discovery.

### Changed
- Corrected external localization XML format and specialization registration.
- Added the Sprayer specialization to eligible base-game vehicle types before type validation.
- Updated menu vehicle resolution to prioritize the mission-controlled vehicle, with player vehicle references as fallbacks.
- Removed the mission-wide first-sprayer fallback to avoid selecting an unrelated sprayer.

### Validation
- The earlier in-game vehicle selection issue remains subject to runtime confirmation.

## [Farm Biosecurity 0.4.1.0] - 2026-11-01
### Changed
- Enabled base Placeable hourly callback subscription.
- Added initial client snapshot stream and fixed specialization-specific savegame XML paths.
- Corrected specialization names to match the FS25 manager API.

## [Farm Biosecurity 0.4.0.0] - 2026-11-01
### Added
- Placeable specialization, subtype cohort state, per-placeable save/load, hourly progression and initial server-to-client snapshot.

## [Farm Biosecurity 0.3.0.0] - 2026-11-01
### Added
- Husbandry specialization and persistent subtype cohort identity.

## [Farm Biosecurity 0.2.0.0] - 2026-11-01
### Added
- Bounded server-side group state store and conservative split/merge helpers.

## [Farm Biosecurity 0.1.0.0] - 2026-11-01
### Added
- Independent bootstrap and disease, quarantine, hygiene and score models.

## [Spray & Hygiene 0.7.1.0] - 2026-11-01
### Changed
- Corrected specialization manager name and per-vehicle savegame XML paths.
- Kept native spray callback observer read-only.

## [Spray & Hygiene 0.7.0.0] - 2026-11-01
### Added
- Initial server-to-client Sprayer state snapshot.

## [Spray & Hygiene 0.6.0.0] - 2026-11-01
### Added
- Sprayer specialization and per-vehicle XML save/load foundation.

## [Spray & Hygiene 0.5.0.0] - 2026-11-01
### Added
- Server-gated state container.

All entries are development foundations, not certified releases.
