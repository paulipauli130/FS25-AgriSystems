# Changelog

## [Unreleased]
- Continue FS25 runtime integration and validation.

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
- GitHub Actions CI/build completed successfully on main (run 41477064419).
- The current in-game test still reports that the menu does not recognize the selected vehicle. This remains an open runtime issue; no working fix is claimed.

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
- Server-gated engine-independent state container.

All entries are development foundations, not certified releases.
