# FS25 AgriSystems — Project Concept

## 1. Overview
FS25 AgriSystems is an independent modding project for Farming Simulator 25. It aims to introduce deeper agricultural management systems, realistic farming processes and additional responsibilities for farm operators.

The project currently consists of two independent mods:
1. AgriSystems Spray & Hygiene
2. AgriSystems Farm Biosecurity

Both mods follow shared development principles but must install, run, save and uninstall independently. Neither requires the other.

## 2. Core philosophy
- **Realism:** represent believable agricultural processes using bounded, transparent gameplay models.
- **Interconnected systems:** actions can have consequences beyond a single interaction.
- **Player responsibility:** good management should prevent problems; negligence may create additional work and costs.
- **Modularity:** systems should be independently configurable wherever technically possible.
- **Performance and multiplayer:** use server-authoritative logic, event-driven updates and bounded processing.

## 3. AgriSystems Spray & Hygiene
Four independently configurable modules:
- **Spray Drift:** weather/equipment-based drift propensity, transport direction and off-target exposure. This is a calibrated gameplay approximation, not CFD.
- **Sprayer Engineering:** equipment condition, nozzle wear/blockage, coverage uniformity and calibration. Native FS25 crop application and fill consumption must remain unchanged.
- **Sprayer Cleaning:** tank, line/boom, filter and nozzle-group residues; rinse/flush procedures and abstract product carry-over classes.
- **Field Contamination:** mechanical transfer of weed seeds, crop residues and pathogen loads by machinery. Initial storage is farmland-level until field-position identity is proven.

## 4. AgriSystems Farm Biosecurity
- Quarantine for newly purchased or returning livestock.
- Group-level disease exposure and progression using configurable abstract profiles.
- Vehicle, trailer, equipment and visitor hygiene.
- Barn/pen hygiene and clean-before-disinfect logic.
- A derived Biosecurity Score with an actionable component breakdown.

The model is a gameplay system, not veterinary diagnosis or clinical treatment advice.

## 5. Product boundaries
Spray & Hygiene and Farm Biosecurity are separate products. Future cross-mod interactions may be considered, but neither mod may require the other. There is no third shared runtime package.

## 6. Technical direction
- Lua script mods and XML configuration where appropriate.
- Verified FS25 APIs and guarded integration adapters.
- Server-authoritative simulation and validated client requests.
- Versioned savegame persistence using mod-owned stable identifiers.
- No global per-frame scans; event-driven updates and dirty-state replication.
- Separate packages with modDesc.xml at each ZIP root.

## 7. Current project status
Technical research and both detailed specifications are complete at source-review level. The initial Spray & Hygiene manifest/bootstrap/configuration foundation has been committed. No gameplay feature has been runtime-certified, Farm Biosecurity implementation has not started, and no public releases are available.

See Documentation/Development_Roadmap.md for milestones and each mod's Technical_Specification.md for implementation contracts.
