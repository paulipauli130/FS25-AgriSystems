# FS25 AgriSystems

**Realistic and modular gameplay systems for Farming Simulator 25.**

AgriSystems is an open-source modding project focused on deeper agricultural processes, realistic mechanics and interconnected farm-management systems.

The project contains two independent FS25 script mods. Each mod is designed to install, run, save and uninstall without depending on the other.

> **Project status: Early implementation**
>
> Spray & Hygiene has four pure gameplay models, a Sprayer-only specialization, per-vehicle state persistence, savegame-specific host settings, an initial server-to-client snapshot and incremental dirty-state update-stream callbacks. Farm Biosecurity has disease, quarantine, hygiene and score models, a husbandry specialization, subtype cohorts, per-placeable persistence, hourly progression and an initial state snapshot. Engine-facing code has not yet been validated in FS25 gameplay. The latest CI build passes; multiplayer update-stream behavior still requires an in-game test. No public release is available.

## Projects

### 1. AgriSystems Spray & Hygiene
A modular system for crop protection, spraying technology, machine hygiene and mechanical contamination transfer.

- **Spray Drift** — bounded drift and off-target exposure based on weather and equipment.
- **Sprayer Engineering** — equipment condition, nozzle wear/blockage and application quality.
- **Sprayer Cleaning** — tank, line, filter and nozzle-group residues and cleaning procedures.
- **Field Contamination** — transfer of weed seeds, crop residues and pathogen loads through machinery.

Native FS25 spray application and fill consumption must remain unchanged.

### 2. AgriSystems Farm Biosecurity
An independent livestock system with group-level disease exposure/progression, quarantine, barn/equipment hygiene and a derived Biosecurity Score.

Logical cohorts are aggregated by configured animal subtype within each husbandry. This deliberately avoids relying on transient FS25 animal-cluster IDs.

## Development status

| Area | Status |
|---|---|
| Public API research and specifications | Complete at source-review level |
| Spray & Hygiene gameplay models | Implemented; not engine-integrated |
| Spray & Hygiene specialization/save/network foundation | Implemented in source; runtime test pending |
| Farm Biosecurity gameplay models and state store | Implemented |
| Farm Biosecurity placeable persistence/hourly progression/snapshot | Early implementation; runtime test pending |
| Standalone Lua model tests | Executed successfully in GitHub Actions CI |
| Independent ZIP packaging script | Executed successfully in GitHub Actions CI; build artifacts generated |
| GIANTS TestRunner / in-game validation | Pending |
| Public releases | None |

See Documentation/Development_Roadmap.md, CHANGELOG.md and the individual mod Implementation Notes.

## Development principles
- **Realism:** bounded gameplay models, no unsupported physical or veterinary accuracy claims.
- **Modularity:** independent systems and configuration.
- **Performance:** event-driven work and bounded update intervals; no global per-frame scans.
- **Multiplayer:** server-authoritative simulation and validated client requests.
- **Compatibility:** preserve native FS25 behavior and avoid overwriting other mods' extension chains.
- **Transparency:** distinguish source-reviewed behavior from runtime-tested behavior.

## Repository layout
- Spray_Hygiene/ — independent mod source, configuration, documentation and tests.
- Farm_Biosecurity/ — independent mod source, configuration, documentation and tests.
- Core/ — development-time shared conventions/source only; not a required third mod.
- Documentation/ — project architecture, research and roadmap.
- Testing/ — test plans and standalone model tests.
- tools/ — Windows PowerShell packaging script.

## Build and testing
Run PowerShell from the repository root:

    .\tools\Build-Mods.ps1

The script validates modDesc source references, localization files and dynamically loaded specialization files, then creates separate ZIPs under Releases. It does not run GIANTS TestRunner.

Target platform is Farming Simulator 25 on PC/Mac. Multiplayer and dedicated-server support are design goals, not certified until tested in-game. Console script-mod support is not promised.

## License
MIT. See LICENSE.
