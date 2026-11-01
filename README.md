# FS25 AgriSystems

**Realistic and modular gameplay systems for Farming Simulator 25.**

AgriSystems is an open-source modding project focused on deeper agricultural processes, realistic mechanics and interconnected farm-management systems.

The project contains two independent FS25 script mods. Each mod is designed to install, run, save and uninstall without depending on the other.

> **Project status: Early implementation**
>
> Technical research and specifications are complete at source-review level. Both mods now have pure gameplay model foundations. Spray & Hygiene has early Sprayer specialization and per-vehicle save/network code; Farm Biosecurity has group disease, quarantine, hygiene and score models. Engine-facing features remain untested in FS25. No public release is available yet.

## Projects

### 1. AgriSystems Spray & Hygiene
A modular system for crop protection, spraying technology, machine hygiene and mechanical contamination transfer.

- **Spray Drift** — bounded drift and off-target exposure based on weather and equipment.
- **Sprayer Engineering** — equipment condition, nozzle wear/blockage and application quality.
- **Sprayer Cleaning** — tank, line, filter and nozzle-group residues and cleaning procedures.
- **Field Contamination** — transfer of weed seeds, crop residues and pathogen loads through machinery.

Native FS25 spray application and fill consumption must remain unchanged.

### 2. AgriSystems Farm Biosecurity
An independent mod for livestock quarantine, group-level disease exposure/progression, vehicle/equipment/visitor hygiene, barn hygiene and a derived Biosecurity Score.

Both products are independent. Neither requires the other, and there is no third shared runtime package.

## Development status

| Area | Status |
|---|---|
| Project research and technical specifications | Complete at source-review level |
| Spray & Hygiene pure gameplay models | Implemented; not engine-integrated |
| Spray & Hygiene specialization/save/network foundation | Early source-reviewed implementation; runtime test pending |
| Farm Biosecurity pure gameplay models | Implemented; not engine-integrated |
| Farm Biosecurity engine integration | Not started |
| GIANTS TestRunner / in-game validation | Pending |
| Public releases | None |

See Documentation/Development_Roadmap.md and CHANGELOG.md.

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
- Testing/ — test plans, reports and local test material.

## Development and testing
Installable mod folders have modDesc.xml at their root. Development source and documentation remain in the repository; release ZIPs are built separately with runtime files only.

Target platform is Farming Simulator 25 on PC/Mac. Multiplayer and dedicated-server support are design goals, not certified until tested in-game. Console script-mod support is not promised.

## License
MIT. See LICENSE.
