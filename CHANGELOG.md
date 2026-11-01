# Changelog

All notable project changes are documented here.

## [Unreleased]
- Continue FS25 runtime integration and validation.

## [0.6.0.0] - 2026-11-01
### Added
- Initial Sprayer-only vehicle specialization registration.
- Read-only observer for native spray work completion cycles.
- Per-vehicle savegame XML schema and serialization for condition and cleaning model state.
- Specialization registration lifecycle notes and runtime test gates.

### Safety
- Native spray application, fill consumption and work-area parameters remain untouched.
- No equipment wear or crop effects are applied yet.
- Runtime validation remains pending.

## [0.5.0.0] - 2026-11-01
### Added
- Server-gated engine-independent state container for sprayer and farmland state.

## [0.4.0.0] - 2026-11-01
### Added
- Farmland-level contamination model with bounded records and class-specific loads.
