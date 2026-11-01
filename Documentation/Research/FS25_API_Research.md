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

## Animals and husbandry – FS25-confirmed versus older-version clues

### Confirmed in the FS25 GDN

- `AnimalCleanEvent` carries a husbandry object reference, a `clusterId`, and a dirt delta. On receipt, it resolves the cluster through `husbandry:getClusterById(clusterId)` and applies `cluster:changeDirt(-delta)` when the cluster and method exist. This proves that FS25 has a husbandry-scoped cluster lookup used by a network event. It does not prove that every animal type exposes the same cleanliness or health properties.
- `PlaceableHusbandryMilk:onHusbandryAnimalsUpdate(clusters)` iterates the supplied cluster list, resolves each `subTypeIndex` through `g_currentMission.animalSystem:getSubTypeByIndex()`, reads `cluster:getAge()` and `cluster:getNumAnimals()`, and derives production. `PlaceableHusbandryStraw` uses the same cluster callback pattern for feed/manure calculations.

### Older-version implementation clue – not an FS25 API guarantee

- The detailed `PlaceableHusbandryAnimals` page currently found through GDN search is explicitly FS22. It shows methods such as `getClusters()`, `getClusterById(id)`, `getClusterSystem()`, `addCluster(cluster)`, and `addAnimals(...)`; it creates `AnimalClusterSystem.new(self.isServer, self)`, subscribes to `AnimalClusterUpdateEvent`, and delegates save/load and stream synchronization to the cluster system.
- The same FS22 implementation serializes cluster data via `clusterSystem:saveToXMLFile(...)` and `clusterSystem:loadFromXMLFile(...)`, and synchronizes it through `clusterSystem:writeStream(...)` / `readStream(...)`. This is a strong architecture clue but must be rechecked against FS25 before using exact names or behavior.
- The FS22 implementation also demonstrates that cluster membership can change: animals may be added, removed, reproduced into new clusters, or cloned/adjusted when a rideable animal is loaded. This reinforces why custom disease state must not be keyed only by animal count or cluster array index.

### Current conclusion and limitations

FS25 itself confirms cluster-ID lookup in an animal network event and cluster iteration in husbandry update callbacks. This is enough to justify further investigation of cluster-level biosecurity, but not enough yet to define a persistent cluster identity model.

Disease, infection, vaccination, and quarantine are not documented as built-in FS25 systems in the reviewed references. These mechanics would be custom. Before implementation, we must inspect the FS25 husbandry/cluster source to verify stable identifiers, cluster replacement/merge/split behavior, movement between husbandries, and save/load semantics. A cluster's array position is not a safe persistent key. A cluster ID is promising, but its uniqueness scope and lifecycle must be confirmed.

## Farmland, fields, persistence, and networking

### Confirmed in the FS25 GDN

- `FarmlandManager:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)` maps world X/Z coordinates to a farmland ID. The documented implementation converts world coordinates into the farmland bit-vector map and reads the ID at that point. A return value of `0` means the position is not valid/buyable farmland.
- `FarmlandManager:getFarmlandOwner(farmlandId)` returns the owning farm ID and returns `0` when no owner mapping exists. `getFarmlandAtWorldPosition(x, z)` returns the farmland object, and `getCanAccessLandAtWorldPosition(farmId, x, z)` checks farm access at a world position.
- `FarmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x, z)` checks whether the sampled position belongs to that farm. `getIsOwnedByFarmAlongLine(...)` can test ownership along a line, which may be useful for diagnostics but is not a substitute for sampling the actual sprayer work-area footprint.
- These methods concern farmland parcels/ownership, not crop-field identity. A single farmland can contain more than one field or non-field area. Spray & Hygiene should therefore store farmland association separately from any future crop-field identity.
- The FS25 `FieldManager` is a separate manager with its own `fields` collection, `farmlandIdFieldMapping`, `loadFromXMLFile()`, and `saveToXMLFile()`. Its `saveToXMLFile(xmlFilename)` writes field records and pending field updates to a dedicated fields XML file. This confirms that field data is managed and persisted separately from farmland ownership.
- FS25 specializations expose lifecycle callbacks such as `onLoad`, `onPostLoad`, `onReadStream`, `onWriteStream`, `onReadUpdateStream`, and `onWriteUpdateStream`. GDN examples explicitly describe `onWriteStream` as server-side on join and `onReadStream` as client-side on join.
- FS25 placeable specializations can register savegame XML paths with `registerSavegameXMLPaths(schema, basePath)` and persist values with `saveToXMLFile(xmlFile, key, usedModNames)`. The GDN `PlaceableFarmhouse` is one documented example. The `PlaceableFactory` example shows nested data being written with `xmlFile:setSortedTable(...)` and delegated storage serialization via `storage:saveToXMLFile(...)`.
- `FillUnit` registers the event `onFillUnitFillLevelChanged` as well as fill-type and filling-state events. This can be used as an event-driven signal for tank state changes rather than polling every frame, subject to the exact callback signature documented above.

### Current conclusion

The FS25 API provides separate systems for farmland ownership and crop-field data. It also provides established savegame XML patterns and distinct network stream callbacks. AgriSystems state should be authoritative on the server, saved persistently, and replicated only when clients need to display or react to it. We should not assume that writing a savegame value automatically synchronizes it to multiplayer clients.

For Spray & Hygiene, field identity should be resolved through the FieldManager/field system where possible, while farmland ownership remains a separate attribute. For Farm Biosecurity, a persistent server-side registry or placeable/cluster-associated data may be feasible, but the correct key and lifecycle depend on the still-open husbandry/cluster investigation.

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

1. Inspect the FS25 husbandry and cluster-system source for exact methods and lifecycle.
2. Verify stable identifiers, cluster add/remove/merge/split behavior, and how animals transferred between husbandries are represented.
3. Inspect FS25 cluster savegame serialization and network events before selecting a persistence model for quarantine/disease status.
4. Determine which stock animal dirt/cleanliness state is available across animal types and what must remain custom disease/biosecurity state.

### Field and persistence integration

1. Inspect exact `FieldManager` position-to-field lookup methods and field object semantics.
2. Select the persistence host for each mod's custom state and document save/load behavior under dedicated server restart and client join.
3. Decide how global registries are loaded, saved, versioned, and migrated without conflicting with existing game save data.

## General research rules

- Prefer official GIANTS documentation and game scripts.
- Community mods and community LUADOC are secondary evidence, not authoritative API guarantees.
- Do not assume FS22 code works unchanged in FS25.
- Record exact function signatures, units, coordinate conventions, lifecycle, and server/client behavior before implementation.
- Keep unresolved items explicitly marked as unresolved.
