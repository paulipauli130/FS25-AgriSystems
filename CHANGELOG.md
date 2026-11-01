# Changelog

All notable changes to FS25 AgriSystems are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). There are no public releases yet; entries under Unreleased describe repository development, not released gameplay features.

## [Unreleased]

### Added
- Initial Spray & Hygiene mod manifest and bootstrap foundation.
- Validated configuration defaults for all four planned modules.
- Pure Lua sprayer-condition model: condition, wear, calibration, nozzle-group blockage and coverage factor.
- Pure Lua cleaning/residue model for tank, lines and filters with abstract product-class carry-over.
- Pure Lua spray-drift risk estimator with bounded inputs, risk bands and normalized explicit wind-to direction.
- English and German localization starter files.
- Manual gameplay-model and spray-drift test plans.

### Changed
- Completed source-level FS25 API research and both independent mod technical specifications.
- Updated project overview, architecture, roadmap and development setup to reflect implementation status.

### Not yet implemented or runtime-certified
- Sprayer specialization registration and non-invasive processing observation.
- Connecting condition degradation to successful native spraying.
- Cleaning actions, water/resource costs and in-game UI.
- Wind provider integration, calibrated spray drift and farmland contamination.
- Farm Biosecurity gameplay.
- Savegame persistence, network events and release packaging.
- GIANTS TestRunner, single-player, multiplayer and dedicated-server validation.

## Releases

No official releases yet.
