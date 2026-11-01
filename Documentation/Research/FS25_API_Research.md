# FS25 API Research

> Research status: ongoing. This document records verified findings and unresolved questions. Do not treat unverified assumptions as implementation guidance.

## Official references

- [GIANTS Developer Network – FS25 Scripting API](https://gdn.giants-software.com/documentation_scripting_fs25.php)
- [GIANTS Developer Network – FS25 Modding Tutorials](https://www.farming-simulator.com/dlc-detail.php?country=us&dlc_id=fs25mt60&lang=en)

The currently surfaced GDN reference identifies Script v1.20.0.0 and Engine v1.20.0.0.

## Weather and wind

### Confirmed in the FS25 GDN

- The FS25 GDN Weather category currently lists `Twister` as its only documented script class. It does not document a general weather manager API or a public wind-speed / wind-direction getter.
- The FS25 GDN documents `PlaceableWindTurbine:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)`. Its implementation uses the direction components to rotate the turbine and passes `windVelocity` to rotor-speed calculation. This confirms that the engine supplies wind direction components and a wind-velocity value to this callback. It does **not** by itself establish a supported public getter for other mods.
- The FS25 GDN documents the turbine's XML `optimalWindSpeed` as a wind speed in m/s.

### Additional reference – older GIANTS documentation

- The FS22 GDN's `PlaceableWindTurbine:onFinalizePlacement()` shows `g_currentMission.environment.weather.windUpdater`, registers the turbine as a wind-changed listener, and calls `windUpdater:getCurrentValues()` to obtain `windDirX`, `windDirZ`, and `windVelocity`.
- This is a useful lead only. It is **not yet verified as an FS25-compatible access path** and must not be used as an implementation assumption without checking the actual FS25 scripts/runtime.

### Current conclusion

Wind-dependent spray drift appears technically plausible because FS25's own wind-turbine specialization receives wind direction and velocity. However, the exact safe mod-facing access method, units for the returned velocity, update/listener lifecycle, and multiplayer authority/synchronization still need confirmation against FS25 source or an in-game runtime test. No wind API should be coded until those points are verified.

## Sprayer processing, attached implements, and fill units

### Confirmed in the FS25 GDN

- `FillUnit` is the vehicle specialization for capacities and tanks. Its documented methods include `getFillUnits()`, `getFillUnitByIndex(index)`, `getFillUnitExists(index)`, `getFillUnitCapacity(index)`, `getFillUnitFillLevel(index)`, `getFillUnitFillLevelPercentage(index)`, `getFillUnitFillType(index)`, and `getFillUnitFreeCapacity(index)`.
- `getFillUnitFillLevel(index)` returns the current fill level; `getFillUnitFillType(index)` returns the fill-type index. Fill units are indexed per vehicle; do not assume every sprayer uses the same index.
- `ExtendedSprayer` exists in the FS25 API. Its `getSprayerUsage()` checks whether the vehicle is turned on, reads `spec_sprayer`, determines the active spray type, and uses work-area width and vehicle speed in usage calculations.
- `Sprayer:onEndWorkAreaProcessing(dt, hasProcessed)` is a useful processing lifecycle point. GIANTS' own FS25 `WeedSpotSpray:onEndWorkAreaProcessing()` checks `self.isServer`, `spec_sprayer.workAreaParameters.isActive`, the spray fill type, `sprayVehicle`, and `usage` before updating herbicide statistics.
- The FS25 `ExtendedSprayer:processSprayerArea()` implementation obtains the work-area start, width, and height world positions and performs its relevant density-map processing under `self.isServer`. This confirms the work-area processing path has explicit server-side behavior.
- GIANTS' FS25 vehicle utility code traverses attached implements through `getAttachedImplements()`, then recurses into each `implement.object`. `ExtendedSprayer.getValidSprayerToUse()` also searches `rootVehicle.childVehicles` for a valid sprayer. These are concrete patterns for discovering equipment beyond the root tractor, but the final mod should handle nil objects and avoid double-processing the same implement.
- FS25 exposes `VehicleConfigurationDataSprayerNodes`, which loads configured `sprayerNozzles.nozzle` node entries and creates extended sprayer effect nodes. This confirms nozzle-related node/effect configuration exists; it does not demonstrate physical nozzle wear or pressure simulation.

### Current conclusion

The most promising server-authoritative observation point for a real application event is the sprayer work-area processing lifecycle, using its active state and actual usage rather than merely `getIsTurnedOn()`. The relevant work-area data also gives us a basis to calculate affected area and application intensity. A recursive attached-implement scan is feasible using documented GIANTS patterns.

The reviewed official API material does not establish a built-in nozzle-wear model, clogging model, or hydraulic pressure simulation. Those would therefore be custom AgriSystems simulation systems, not existing FS25 values we can simply read. We must investigate the base `Sprayer` usage calculation and effect setup further before choosing an extension point. Avoid modifying the game's actual fill-level consumption in a way that conflicts with its normal server processing.

## Animals and husbandry – initial FS25 findings

### Confirmed in the FS25 GDN

- The FS25 Animals API category includes `AnimalLoadingTrigger`. It resolves supported animal type names through `g_currentMission.animalSystem:getTypeIndexByName()` and exposes the trigger's configured animal types through `getAnimals()`. This is trigger/type selection, not a complete husbandry-health interface.
- FS25 has animal-related network events, including `AnimalCleanEvent` and `AnimalNameEvent`. `AnimalCleanEvent` identifies a husbandry object and animal cluster ID, then applies a dirt change to that cluster. This confirms that at least some animal state is represented per cluster and changed through network events.
- FS25 `PlaceableHusbandryMilk` and `PlaceableHusbandryStraw` expose `onHusbandryAnimalsUpdate(clusters)`. Their implementations iterate animal clusters, read each cluster's subtype and age, resolve subtype data through `g_currentMission.animalSystem`, and calculate production/consumption values. This is evidence for an animal-cluster update lifecycle and subtype-based animal data.

### Current conclusion and limitations

The FS25 API provides animal clusters, subtype/age information in husbandry update callbacks, and networked animal actions. This gives Farm Biosecurity a plausible foundation for tracking livestock groups and attaching custom health/quarantine state to a husbandry/cluster identity.

The reviewed FS25 documentation does **not** establish a built-in disease, infection, vaccination, or quarantine system. Those mechanics must be custom. We have not yet verified the base FS25 husbandry specialization's full public API, stable cluster identifiers/lifecycle, animal movement between husbandries, or savegame persistence strategy. Those are required before deciding whether disease state belongs to a cluster, a husbandry, or a separate registry.

## Research questions still open

### Sprayer engineering

1. Inspect the base FS25 `Sprayer` implementation and exact registration/lifecycle methods, including when `workAreaParameters` is populated and reset.
2. Verify exact meaning and units of `workAreaParameters.usage`, `sprayFillType`, and `sprayVehicleFillUnitIndex`.
3. Determine whether an overwrite of `Sprayer:getSprayerUsage()` or a work-area event listener is safer for custom flow/pressure calculations, and how to avoid double consumption.
4. Confirm whether all stock and modded sprayers use the same specialization and identify graceful fallback behavior for custom implementations.
5. Investigate nozzle node/effect configuration to see whether individual sections/nozzles can be mapped reliably. Do not infer nozzle count from visuals alone.
6. Decide how custom wear/clogging state is stored and synchronized on the server.

### Weather

1. Inspect the FS25 game scripts for the weather/wind updater implementation and the FS25 `PlaceableWindTurbine` call site.
2. Confirm whether `weather.windUpdater:getCurrentValues()` exists in FS25, and record its exact return values and units.
3. Confirm whether wind values are global or position-dependent, and establish the direction-vector convention.
4. Determine whether wind values should be read server-side and replicated to clients for consistent multiplayer drift calculations.

### Animals and husbandry

1. Inspect the base FS25 husbandry and cluster-system source for exact methods and lifecycle.
2. Verify stable cluster IDs, cluster add/remove/move events, and how animals transferred between husbandries are represented.
3. Inspect savegame serialization and network events before selecting a persistence model for quarantine/disease status.
4. Determine what stock animal dirt/cleanliness state can be reused and what must remain custom disease/biosecurity state.

### Other systems

- Field and work-area APIs for application detection.
- Events, networking, and savegame persistence.
- Feature-to-API feasibility matrix before finalizing mod folder structures.

## General research rules

- Prefer official GIANTS documentation and game scripts.
- Community mods and community LUADOC are secondary evidence, not authoritative API guarantees.
- Do not assume FS22 code works unchanged in FS25.
- Record exact function signatures, units, coordinate conventions, lifecycle, and server/client behavior before implementation.
- Keep unresolved items explicitly marked as unresolved.
