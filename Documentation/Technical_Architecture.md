# Technical Architecture

## 1. Product boundaries
AgriSystems consists of two independently installable FS25 script mods: Spray & Hygiene and Farm Biosecurity. There is no required shared runtime package or third ZIP. Common conventions/source may be duplicated at build time; each final ZIP must be standalone.

## 2. Runtime model
- Target FS25 PC/Mac; console script-mod support is not promised.
- Server authoritative for all shared simulation, validation, persistence and random seeds.
- Client requests actions; server validates sender/farm/object/permissions/distance/resources/state.
- Initial snapshot on connection; compact dirty-mask update streams afterward.
- Savegame XML is authoritative for simulation settings/state. Local modSettings are client UI preferences only.
- Each mod has unique specialization/event/XML namespaces and independent versioning.

## 3. FS25 integration contracts
### Spray & Hygiene
- Base Sprayer start/process/end callbacks are observation points. Native game calculates and deducts usage. External fill sources may leave source vehicle nil.
- Precision Farming wraps usage, area processing and end processing. Do not override these functions or alter workAreaParameters/usage in v1.
- Wind path: g_currentMission.environment.weather.windUpdater; getCurrentValues returns dirX, dirZ, velocity m/s, cirrus factor. Listener add/remove methods exist. Vector sign and dedicated-server authority are runtime gates.
- FarmlandManager position lookup is supported. FieldManager:getFieldById maps farmland ID to Field; not a world position query. V1 uses farmland-level contamination.
### Farm Biosecurity
- PlaceableHusbandryAnimals owns AnimalClusterSystem and exposes cluster getters; cluster updates are event-driven.
- Engine cluster IDs are transient, regenerated on load and changed by split/merge. Persistent biosecurity records require mod-owned IDs and conservative reconciliation.
### Registration
- SpecializationManager registration and TypeManager validation/finalization are distinct phases. Inject only into eligible vehicle/placeable types with required base specializations. Make injection idempotent and namespaces unique.

## 4. State and persistence
Each mod owns a versioned XML root. Persist only mod-owned stable IDs and gameplay state; rebuild runtime object/cluster mappings on load. Validate ranges and schema versions; ignore unknown keys; migrate conservatively. Orphan records are bounded and safely pruned. Uninstall must not damage vanilla save data.

## 5. Events and security
- Vehicle state updates use FS25 specialization dirty flags and update-stream callbacks, not custom client-authored state events.
- Server changes state and raises its specialization dirty flag; clients only deserialize and validate the bounded payload.
- Initial vehicle snapshots remain separate from incremental updates so late joiners receive the current state.
- Never trust client-submitted simulation values. Server calculates and validates results. Avoid full-state broadcasts per tick.

## 6. Performance
No global per-frame scans. Event-driven callbacks, bounded intervals, cached type checks, dirty-state replication, bounded records/history. Group-level animal model in v1. Farmland-level contamination in v1.

## 7. Runtime gates
- Dirty-flag allocation and update-stream callback behavior in actual FS25 multiplayer.
- Wind vector sign and actual drift direction.
- Dedicated-server weather authority, listener lifecycle and client synchronization.
- Sprayer callback timing with Precision Farming, AI, external tanks and other mods.
- Cluster reconciliation through split/merge/reproduction/riding/death/save-load/late join.
- Placeable/vehicle type validation order and load-order compatibility.
- Field geometry lookup only if field-level contamination is later introduced.

## 8. Testing and release
Run GIANTS TestRunner matching the installed patch, then actual single-player and dedicated-server tests. Acceptance matrices live in each mod's Technical_Specification.md. Package each mod separately with modDesc.xml at ZIP root; exclude documentation, tests, repository metadata and developer tools.

## 9. Implementation status
- Research and both technical specifications: complete at source-review level.
- Spray & Hygiene: specialization, server-side wear observer, savegame settings and initial/incremental state synchronization implemented in source; runtime load, save/reload and multiplayer behavior not yet verified.
- Farm Biosecurity: gameplay models, specialization, persistence foundation and initial snapshot implemented; runtime behavior not yet verified.
- GIANTS TestRunner and in-game SP/MP/dedicated-server validation: pending.

The codebase must not mark a feature complete until the relevant current-patch runtime tests pass.
