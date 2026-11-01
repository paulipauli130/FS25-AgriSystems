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
- The exact FS25 `FillUnit:onFillUnitFillLevelChanged` event signature is `(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)`. GIANTS' FillUnit implementation raises this event after updating fill state and dirty flags. This is an event callback for changes, not a per-frame polling API. Consumers should filter by the relevant fill-unit index and run authoritative state changes on the server where appropriate.
- `ExtendedSprayer` exists in the FS25 API. Its `getSprayerUsage()` extends the base usage calculation and may adjust it according to Precision Farming data/work areas. It is an optional extension, not a universal sprayer interface; the mod must not require it.
- `ExtendedSprayer.getFillTypeSourceVehicle(sprayer)` shows that the product can be consumed from a separate source vehicle/fill unit. It first checks the sprayer's own fill unit, then scans configured `spec_sprayer.fillTypeSources` for a compatible source vehicle and fill unit. This is important for multi-vehicle and externally supplied sprayer configurations; never assume the tank is on the same object as the boom.
- The FS25 `WeedSpotSpray` specialization registers `onEndWorkAreaProcessing` as an event listener. Its implementation checks `self.isServer`, `self.spec_sprayer.workAreaParameters.isActive`, the spray fill type, `sprayVehicle`, and `usage` before updating herbicide statistics. This is direct FS25 evidence that the base Sprayer work-area lifecycle exposes useful server-side application data to other specializations.
- The FS25 `ExtendedSprayer:processSprayerArea()` implementation obtains the work-area start, width, and height world positions and performs its relevant density-map processing under `self.isServer`. This confirms the work-area processing path has explicit server-side behavior.
- GIANTS' FS25 vehicle utility code traverses attached implements through `getAttachedImplements()`, then recurses into each `implement.object`. `ExtendedSprayer.getValidSprayerToUse()` also searches `rootVehicle.childVehicles` for a valid sprayer. These are concrete patterns for discovering equipment beyond the root tractor, but the final mod should handle nil objects and avoid double-processing the same implement.
- FS25 exposes `VehicleConfigurationDataSprayerNodes`, which loads configured `sprayerNozzles.nozzle` node entries and creates extended sprayer effect nodes. This confirms nozzle-related node/effect configuration exists; it does not demonstrate physical nozzle wear or pressure simulation.

### Important limitation on the base Sprayer source

The official FS25 GDN material surfaced so far provides direct base-Sprayer state through dependent specializations such as `WeedSpotSpray`, but the full base `Sprayer` class source and all of its exact method signatures have not yet been independently inspected in the current research pass. A prior FS22 GDN result shows `Sprayer:onStartWorkAreaProcessing()` and `onEndWorkAreaProcessing()` calculating and consuming usage, including external fill sources; that is **FS22-only evidence** and must not be presented as proof of identical FS25 implementation. The FS25 `WeedSpotSpray` evidence confirms the work-area callback and selected fields, but not every detail of base Sprayer consumption logic.

### Current conclusion

The most promising server-authoritative observation point for a real application event is the base sprayer work-area processing lifecycle, using its active state and actual usage rather than merely `getIsTurnedOn()`. The FS25 `WeedSpotSpray` implementation directly validates this integration pattern. Product sourcing must be resolved per sprayer configuration: the source tank may be the sprayer itself or another linked vehicle. ExtendedSprayer provides one verified example of that resolution, but because it is optional, we need a generic fallback based on the base Sprayer configuration.

The reviewed official API material does not establish a built-in nozzle-wear model, clogging model, or hydraulic pressure simulation. Those would therefore be custom AgriSystems simulation systems, not existing FS25 values we can simply read. We must investigate the base `Sprayer` usage calculation and effect setup further before choosing an extension point. Avoid modifying the game's actual fill-level consumption in a way that conflicts with its normal server processing.

## Animals and husbandry – initial FS25 findings

### Confirmed in the FS25 GDN

- The FS25 Animals API category includes `AnimalLoadingTrigger`. It resolves supported animal type names through `g_currentMission.animalSystem:getTypeIndexByName()` and exposes the trigger's configured animal types through `getAnimals()`. This is trigger/type selection, not a complete husbandry-health interface.
- FS25 has animal-related network events, including `AnimalCleanEvent` and `AnimalNameEvent`. `AnimalCleanEvent` identifies a husbandry object and animal cluster ID, then applies a dirt change to that cluster. This confirms that at least some animal state is represented per cluster and changed through network events.
- FS25 `PlaceableHusbandryMilk` and `PlaceableHusbandryStraw` expose `onHusbandryAnimalsUpdate(clusters)`. Their implementations iterate animal clusters, read each cluster's subtype and age, resolve subtype data through `g_currentMission.animalSystem`, and calculate production/consumption values. This is evidence for an animal-cluster update lifecycle and subtype-based animal data.

### Current conclusion and limitations

The FS25 API provides animal clusters, subtype/age information in husbandry update callbacks, and networked animal actions. This gives Farm Biosecurity a plausible foundation for tracking livestock groups and attaching custom health/quarantine state to a husbandry/cluster identity.

The reviewed FS25 documentation does **not** establish a built-in disease, infection, vaccination, or quarantine system. Those mechanics must be custom. We have not yet verified the base FS25 husbandry specialization's full public API, stable cluster identifiers/lifecycle, animal movement between husbandries, or savegame persistence strategy. Those are required before deciding whether disease state belongs to a cluster, a husbandry, or a separate registry.

## Farmland, work areas, persistence, and networking

### Confirmed in the FS25 GDN

- `FarmlandManager:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)` maps world X/Z coordinates to a farmland ID. Its documented return value is `0` when the position is not valid/buyable farmland. This can support associating a recorded spray-work-area position with a farmland, but the work-area parallelogram and field ownership must not be conflated with a crop field boundary.
- FS25 specializations expose lifecycle callbacks such as `onLoad`, `onPostLoad`, `onReadStream`, `onWriteStream`, `onReadUpdateStream`, and `onWriteUpdateStream`. GDN examples explicitly describe `onWriteStream` as server-side on join and `onReadStream` as client-side on join.
- FS25 placeable specializations can register savegame XML paths with `registerSavegameXMLPaths(schema, basePath)` and persist values with `saveToXMLFile(xmlFile, key, usedModNames)`. The GDN `PlaceableFarmhouse` is one documented example. Other specializations register update-stream callbacks separately, demonstrating that save persistence and live network synchronization are distinct concerns.
- `FillUnit` registers the event `onFillUnitFillLevelChanged` as well as fill-type and filling-state events. This can be used as an event-driven signal for tank state changes rather than polling every frame, subject to the exact callback signature documented above.

### Current conclusion

The FS25 API provides a documented way to map world positions to farmland IDs, plus established specialization lifecycle hooks for savegame persistence and initial/live network synchronization. AgriSystems state should be authoritative on the server, saved persistently, and replicated only when clients need to display or react to it. We should not assume that writing a savegame value automatically synchronizes it to multiplayer clients.

For Spray & Hygiene, farmland association is feasible from world coordinates. For Farm Biosecurity, a persistent server-side registry or placeable/cluster-associated data may be feasible, but the correct key and lifecycle depend on the still-open husbandry/cluster investigation.

## Research questions still open

### Sprayer engineering

1. Inspect the base FS25 `Sprayer` implementation and exact registration/lifecycle methods, including when `workAreaParameters` is populated and reset.
2. Verify exact meaning and units of `workAreaParameters.usage`, `sprayFillType`, and `sprayVehicleFillUnitIndex` in FS25 base code.
3. Determine whether an overwrite of `Sprayer:getSprayerUsage()` or an event listener is safer for custom flow/pressure calculations, and how to avoid double consumption.
4. Confirm how base Sprayer fill-type sources are represented when ExtendedSprayer is absent.
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

### Field and persistence integration

1. Inspect exact `FarmlandManager` and field-system APIs for field identity versus farmland ownership.
2. Select the persistence host for each mod's custom state and document save/load behavior under dedicated server restart and client join.

## General research rules

- Prefer official GIANTS documentation and game scripts.
- Community mods and community LUADOC are secondary evidence, not authoritative API guarantees.
- Do not assume FS22 code works unchanged in FS25.
- Record exact function signatures, units, coordinate conventions, lifecycle, and server/client behavior before implementation.
- Keep unresolved items explicitly marked as unresolved.
