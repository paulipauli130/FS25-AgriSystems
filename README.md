# FS25 AgriSystems

**Realistic and modular gameplay systems for Farming Simulator 25.**

AgriSystems is an open-source modding project focused on deeper agricultural processes, realistic mechanics and interconnected farm-management systems.

The project contains two independent FS25 script mods. Each mod is designed to install, run, save and uninstall without depending on the other.

> **Project status: Early implementation**
>
> Technical research and both detailed specifications are complete. The first development foundation for Spray & Hygiene is now in the repository. No gameplay feature has been runtime-certified and no public release is available yet.

---

## Projects

### 1. AgriSystems Spray & Hygiene

A modular system for crop protection, spraying technology, machine hygiene and mechanical contamination transfer.

Planned modules:
- **Spray Drift** — bounded drift and off-target exposure based on weather and equipment.
- **Sprayer Engineering** — equipment condition, nozzle wear/blockage and application quality.
- **Sprayer Cleaning** — tank, line, filter and nozzle-group residues and cleaning procedures.
- **Field Contamination** — transfer of weed seeds, crop residues and pathogen loads through machinery.

The modules are designed to be configurable and independently enabled. Native FS25 spray application and fill consumption must remain unchanged.

### 2. AgriSystems Farm Biosecurity

A separate mod for livestock quarantine, group-level disease exposure, vehicle/equipment/visitor hygiene, barn hygiene and a derived Biosecurity Score.

Both products are independent. Neither requires the other, and there is no third shared runtime package.

---

## Development status

| Area | Status |
|---|---|
| Project structure and conventions | Complete |
| FS25 source/API research | Complete at source-review level |
| Spray & Hygiene technical specification | Complete |
| Farm Biosecurity technical specification | Complete |
| Spray & Hygiene bootstrap/configuration foundation | Initial source committed; not yet game-tested |
| Spray & Hygiene gameplay systems | Not implemented |
| Farm Biosecurity implementation | Not started |
| GIANTS TestRunner / in-game validation | Pending |
| Public releases | None |

See [Development Roadmap](Documentation/Development_Roadmap.md) for detailed milestones and [CHANGELOG](CHANGELOG.md) for repository changes.

## Development principles

- **Realism:** use plausible, bounded gameplay models rather than unsupported claims of physical accuracy.
- **Modularity:** independent systems and configuration.
- **Performance:** event-driven work and bounded update intervals; no global per-frame scans.
- **Multiplayer:** server-authoritative simulation and validated client requests.
- **Compatibility:** preserve native FS25 behavior and avoid overwriting other mods' extension chains.
- **Transparency:** distinguish source-reviewed behavior from runtime-tested behavior.

## Repository layout

- `Spray_Hygiene/` — independent mod source, configuration, documentation and tests.
- `Farm_Biosecurity/` — independent mod source, configuration, documentation and tests.
- `Core/` — development-time shared conventions/source only; not a required third mod.
- `Documentation/` — project architecture, research and roadmap.
- `Testing/` — test plans, reports and local test material (savegames/logs are not committed).

## Development and testing

The installable mod folder must contain `modDesc.xml` at its root. Development source and documentation remain in the repository; release ZIPs are built separately with only runtime files.

Target platform is Farming Simulator 25 on PC/Mac. Multiplayer and dedicated-server support are design goals, not certified until tested in-game. Console script-mod support is not promised.

See [Development Setup](Documentation/Development_Setup.md) and the individual mod specifications.

## Contributing

Bug reports, feature proposals, documentation improvements and tested code contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes.

## License

The project is distributed under the MIT License. See [LICENSE](LICENSE).
