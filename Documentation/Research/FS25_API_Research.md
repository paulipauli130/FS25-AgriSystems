# FS25 API Research

This document records source-level findings and runtime verification requirements for the AgriSystems mods. Source inspection is not equivalent to runtime certification.

## Primary references
- GIANTS Developer Network FS25 Scripting API: https://gdn.giants-software.com/documentation_scripting_fs25.php
- Official FS25 Modding Tutorials: https://www.farming-simulator.com/dlc-detail.php?country=us&dlc_id=fs25mt60&lang=en

## Source-reviewed integration contracts
### Wind
- Source: `environment/weather/WindUpdater.lua`, `environment/weather/Weather.lua`, `environment/weather/WindObject.lua`.
- Access path: `g_currentMission.environment.weather.windUpdater`.
- `getCurrentValues()` returns direction X/Z, velocity in m/s and cirrus factor.
- Listener API: `addWindChangedListener(listener)`, `removeWindChangedListener(listener)`; callback `setWindValues(dirX, dirZ, velocity, cirrusFactor)`.
- Direction sign (wind-to vs wind-from), dedicated-server authority and lifecycle remain runtime gates.

### Sprayer
- Source-reviewed callbacks: `onStartWorkAreaProcessing`, `processSprayerArea`, `onEndWorkAreaProcessing`, `onFillUnitFillLevelChanged`.
- Base game selects native or external fill source, computes usage, applies the density map and deducts native usage on successful processing.
- External supply may have nil `sprayVehicle`.
- Precision Farming wraps usage and area-processing methods.
- V1 must not override `getSprayerUsage` or `processSprayerArea`, mutate native usage/work-area parameters, or deduct fill a second time.
- Callback order and compatibility with PF, AI and external tanks require runtime verification.

### Animal groups
- Source: `animals/husbandry/cluster/AnimalCluster.lua`, `AnimalClusterSystem.lua`, `AnimalClusterUpdateEvent.lua`.
- Engine cluster IDs are runtime-only, regenerated on load and subject to split/merge/clone changes.
- Persistent disease/quarantine identity must be mod-owned; reconciliation must be conservative.

### Farmland
- `FarmlandManager` provides world-position-to-farmland lookup and ownership/access information.
- `FieldManager:getFieldById` maps farmland ID to a Field object; it is not a world-position query.
- V1 field contamination is stored per farmland ID until a reliable field-position resolver is verified.

## Registration and mod loading
- GDN documents specialization registration and type validation/finalization as separate lifecycle stages.
- Registration/injection must be namespaced and idempotent, and restricted to types with the required base specialization.
- The initial Spray & Hygiene bootstrap uses a script-only mod descriptor and a mod event listener. It deliberately does not register a vehicle specialization yet.

## Runtime-only gates
1. Confirm modDesc and bootstrap load on the exact target game patch.
2. Confirm event-listener lifecycle and map transitions.
3. Confirm WindUpdater vector sign and dedicated-server authority.
4. Confirm Sprayer callback order with PF, AI, external tanks and other mods.
5. Verify animal group reconciliation through all split/merge/save/load cases.
6. Verify actual vehicle/placeable type validation order and load-order interactions.

## Research status
Source-level research and design specifications are complete. Runtime validation is pending and must be recorded against the exact installed FS25 patch and GIANTS TestRunner version.
