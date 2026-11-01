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
- **Field lookup – community implementation evidence:** the FS25 mod Realistic Soil & Fertilizer uses `g_fieldManager:getFieldAtWorldPosition(x, z)` as its primary field lookup and reports improved accuracy on complex maps. Its development notes explicitly distinguish `fieldId` from `farmlandId`. This is a useful real-world FS25 implementation reference, but the method signature/behavior has not yet been cross-checked against a directly surfaced GDN class page in this research pass.
- FS25 specializations expose lifecycle callbacks such as `onLoad`, `onPostLoad`, `onReadStream`, `onWriteStream`, `onReadUpdateStream`, and `onWriteUpdateStream`. GDN examples explicitly describe `onWriteStream` as server-side on join and `onReadStream` as client-side on join.
- FS25 placeable specializations can register savegame XML paths with `registerSavegameXMLPaths(schema, basePath)` and persist values with `saveToXMLFile(xmlFile, key, usedModNames)`. The GDN `PlaceableFarmhouse` is one documented example. The `PlaceableFactory` example shows nested data being written with `xmlFile:setSortedTable(...)` and delegated storage serialization via `storage:saveToXMLFile(...)`.
- FS25 event examples establish a standard custom-network-event pattern: serialize object references and state in `writeStream`, reconstruct them in `readStream`, then apply the change in `run`. GIANTS examples such as `FlashlightToggleLightEvent` and `ProductionPointProductionStatusEvent` send client requests to the server or broadcast server-originated changes to clients. The server checks the connection direction and broadcasts accepted changes.

### Current architecture recommendation (research-based, not code)

- Keep gameplay state authoritative on the server. Clients should request actions; they should not directly decide disease status, contamination state, drift results, or equipment wear.
- In each custom event, validate sender permissions, farm ownership/access, object validity, and state transition on the server before applying it. Broadcast only accepted results to clients.
- Use initial object streams for state a joining client must know immediately, and update streams/events for subsequent changes. Savegame XML is a separate persistence layer; it does not replace network synchronization.
- For field tracking, resolve the actual crop field with `g_fieldManager:getFieldAtWorldPosition(x, z)` where verified, and separately resolve farmland ID/owner with `g_farmlandManager`. Do not use farmland ID as a field ID.
- For animal quarantine, do not persist an array index. Prefer a verified stable identity composed from the husbandry identity plus cluster ID, with a migration/cleanup strategy for cluster changes. This remains provisional until FS25 cluster lifecycle is inspected.

### Current conclusion

The FS25 API provides separate systems for farmland ownership and crop-field data. It also provides established savegame XML patterns and distinct network stream/event callbacks. AgriSystems state should be authoritative on the server, saved persistently, and replicated only when clients need to display or react to it. We should not assume that writing a savegame value automatically synchronizes it to multiplayer clients.

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

1. Cross-check `g_fieldManager:getFieldAtWorldPosition(x, z)` against the direct FS25 GDN source and confirm its return type.
2. Inspect exact `FieldManager` position-to-field lookup methods and field object semantics.
3. Select the persistence host for each mod's custom state and document save/load behavior under dedicated server restart and client join.
4. Decide how global registries are loaded, saved, versioned, and migrated without conflicting with existing game save data.

## General research rules

- Prefer official GIANTS documentation and game scripts.
- Community mods and community LUADOC are secondary evidence, not authoritative API guarantees.
- Do not assume FS22 code works unchanged in FS25.
- Record exact function signatures, units, coordinate conventions, lifecycle, and server/client behavior before implementation.
- Keep unresolved items explicitly marked as unresolved.


## Deeper FS25 source inspection – sprayer lifecycle, fields, and animal husbandry

> Evidence note: The following source-level cross-checks use the public community mirror `MyGameSteamOfficial/fs25-lua-api`, which exposes selected FS25 game Lua files. This is not a GIANTS-published source repository. Treat it as secondary source evidence and re-check against the installed game build before release. The mirror's index is incomplete: absence of a class/file from this repository does not prove that the class does not exist in the game.

### Base FS25 Sprayer – source-level findings

The mirrored FS25 `vehicles/specializations/Sprayer.lua` confirms these exact callbacks:

- `Sprayer:onStartWorkAreaProcessing(dt)`
- `Sprayer:onEndWorkAreaProcessing(dt, hasProcessed)`
- `Sprayer:processSprayerArea(workArea, dt)`
- `Sprayer:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)`
- `Sprayer:onStateChange(state, data)`

The specialization registers both work-area callbacks and the fill-unit callback as event listeners.

At `onStartWorkAreaProcessing(dt)`, the base sprayer reads its configured fill-unit index and fill type, calculates `usage` using `getSprayerUsage(fillType, dt)`, checks its own tank, and otherwise scans `spec.fillTypeSources` for active compatible source vehicles and fill-unit indices. It also handles externally supplied product separately. It writes the selected `sprayVehicle`, `sprayVehicleFillUnitIndex`, `sprayFillType`, `sprayFillLevel`, `usage`, and `usagePerMin` into `spec.workAreaParameters`, then resets per-area counters and sets `isActive = false` before actual area processing.

The base `processSprayerArea(workArea, dt)` returns without applying when available spray fill level is zero. Otherwise it obtains the work-area start/width/height world positions and calls `FSDensityMapUtil.updateSprayArea(...)`. Only after that operation does it set `workAreaParameters.isActive = true` and accumulate changed/total/stat area values. This makes `isActive` a much stronger signal than merely checking whether the implement is switched on.

At `onEndWorkAreaProcessing(dt, hasProcessed)`, the server checks `workAreaParameters.isActive`. If active, it deducts `usage` from the selected source vehicle/fill unit (unless the source is external), updates farm spray statistics, and updates the last worked area. A mod must not independently deduct the same usage or it will double-consume product.

The native usage formula in the mirrored source is:

```lua
scale * litersPerSecond * self.speedLimit * workWidth * dt * 0.001
```

Here `scale` comes from the configured fill-type/usage scale, `litersPerSecond` from the registered spray type (default 1), `workWidth` from the configured usage width or work-area width, and `dt` is milliseconds. The output is a volume amount in the fill-unit's liters convention. `usagePerMin` is derived as `usage / dt * 1000 * 60`. This is the native nominal-consumption calculation, not a measured pressure or flow sensor.

**Implementation consequence:** the safest first integration is a server-side observer of completed work-area processing, reading the recorded state only where callback ordering is verified. If changing actual spray rate is desired, a narrowly scoped specialization overwrite of `getSprayerUsage` may be more coherent than a second fill-level deduction, but it affects native consumption and must preserve Precision Farming/ExtendedSprayer overrides. That extension decision still requires an in-game compatibility test. For the first version, model wear/clogging as a quality/coverage penalty rather than altering native fill consumption.

**External-fill caveat:** `sprayVehicle` may be nil when product is supplied externally (for example, purchased fertilizer). Native processing can still apply product and count usage without deducting a normal fill unit. Telemetry must treat `sprayVehicle == nil` as a valid external-source case, not a failed sprayer.

### FieldManager lookup – correction to earlier assumption

The inspected mirrored FS25 `field/FieldManager.lua` contains the field collection and farmland-to-field mapping, but a search of the complete mirrored file did **not** find a method named `getFieldAtWorldPosition` or `getFieldById`. The mirror may be incomplete and the public GDN pages surfaced so far do not confirm that method. Therefore:

- `g_fieldManager:getFieldAtWorldPosition(x, z)` remains **unverified community-mod evidence**, not an established FS25 public API.
- Do not make it a hard dependency in the first implementation.
- A robust first release can use verified farmland ID/owner lookup for ownership association and treat crop-field ID as optional until the exact installed-game lookup is established. If field identity is needed, use a compatibility adapter that returns “unknown” rather than guessing.
- The source's `farmlandIdFieldMapping` maps farmland IDs to field objects during map loading; it is not shown to be a general world-position field query.

### FS25 husbandry specialization – source-level findings

The mirrored FS25 `PlaceableHusbandryAnimals.lua` confirms:

- `onLoad(savegame)` creates `spec.clusterSystem = AnimalClusterSystem.new(self.isServer, self)` and subscribes to `AnimalClusterUpdateEvent`.
- The placeable exposes `getClusters()`, `getCluster(index)`, `getClusterById(id)`, and `getClusterSystem()`.
- New clusters are queued with `clusterSystem:addPendingAddCluster(cluster)`; the husbandry is activated with `raiseActive()`.
- `updatedClusters(husbandry)` verifies the update belongs to this placeable, retrieves the cluster list, raises `onHusbandryAnimalsUpdate`, publishes `MessageType.HUSBANDRY_ANIMALS_CHANGED`, and schedules visual updates.
- The placeable's `onUpdate(dt)` calls `clusterSystem:update(dt)` only when `self.isServer`.
- `onReadStream(streamId, connection)` and `onWriteStream(streamId, connection)` delegate initial synchronization to the cluster system.
- `saveToXMLFile(xmlFile, key, usedModNames)` and `loadFromXMLFile(xmlFile, key)` delegate persistence to the cluster system under `key .. ".clusters"`.
- Periodic reproduction creates new cluster objects and queues them through `addPendingAddCluster`.
- Riding a single animal from a multi-animal cluster reduces the source cluster count and clones a cluster for the rideable vehicle. Thus clusters can be split by gameplay actions.

**Identity conclusion:** husbandry object + cluster ID is a useful current lookup address, but should not yet be treated as a permanent disease identity. The source mirror does not include the implementation of `AnimalClusterSystem` or the cluster class, so it does not establish ID generation, survival across save/load, uniqueness scope, ID reuse, or every merge/removal path. For an initial disease model, store state against a husbandry-scoped cluster ID with explicit reconciliation rules, and keep a mod-owned persistent record ID separate from the engine cluster ID. If a cluster is split or replaced, state inheritance must be an explicit policy rather than assumed from the engine.

### Version and source limitations

- The public source mirror is not the official GDN and its index does not include all FS25 classes. It is valuable for concrete implementation paths, but not enough to claim every file reflects the latest live game patch.
- The official GDN is the primary API contract. The installed game's own `dataS` scripts are the final source of truth for a given game build.
- The official FS25 API page currently surfaced in this research identifies Script/Engine v1.20.0.0, while the game's public changelog lists later patch updates. Before release, record the exact local game build and re-check source-sensitive hooks against that build.


## Weather access and mod configuration – evidence status

### Wind access

- FS25 GDN confirms the callback `PlaceableWindTurbine:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)`; it uses the direction components for turbine orientation and passes velocity into rotor-speed calculation. This confirms the engine's wind system supplies these values to at least one FS25 specialization.
- The FS22 GDN explicitly shows `g_currentMission.environment.weather.windUpdater`, `addWindChangedListener(self)`, and `getCurrentValues()`. This remains older-version evidence only.
- A publicly indexed FS25 weather mod source excerpt calls `self.windUpdater:getCurrentValues()` and passes the returned values into weather objects. This is community-mod source evidence, not a complete proof of a stable public API or its multiplayer semantics.
- The official FS25 GDN Weather category still does not expose a general documented `Weather` / `WindUpdater` class or getter in the material inspected. The selected public FS25 source mirror also does not include the weather updater implementation.
- A recent FS25 ModHub mod, Dynamic Wind, confirms that other mods can modify the active map's wind speed/direction behavior and provides a settings control, but its public ModHub description does not document its internal API.

**Decision:** wind is a supported design target but remains an integration risk until checked against the installed FS25 `dataS` weather scripts and a dedicated-server test. Build the drift calculation behind a `WindProvider` adapter. The adapter must report unavailable/invalid values cleanly and use a configurable fallback (no drift or a clearly labelled neutral wind), rather than reading an assumed global path throughout gameplay code. Read wind authoritatively on the server; replicate only the resulting drift state/summary needed by clients. Confirm direction sign convention empirically with a known wind vane/turbine orientation and a test sprayer before using it for downwind contamination.

### Settings and persistence separation

The FS25 modding references inspected describe two different configuration lifetimes:

1. **Global mod options:** the game writes per-mod settings under the user's FS25 `modSettings/<modName>/` directory. These are appropriate for defaults and player/server configuration such as enabling modules, realism multipliers, debug logging, and UI preferences. Community references show this folder is used by established mods, but exact read/write helper APIs and dedicated-server ownership must be verified against the chosen implementation.
2. **Savegame simulation state:** state that belongs to a farm/save (equipment condition, field contamination, livestock quarantine, outbreak history, cleaning records) must be stored with the savegame or a savegame-associated XML file, not solely in global modSettings. Otherwise two saves on one profile could leak state into one another.
3. **Multiplayer authority:** global settings must be loaded consistently by the server and validated; simulation state must be loaded and saved by the server. Clients receive the state they need through initial streams and subsequent events. Do not let each client independently persist authoritative simulation state.

A separate in-game settings tab is feasible, but it is a larger UI integration task. The first implementation should prefer a robust XML configuration with safe defaults and a compact in-game settings surface only after the simulation is stable. Avoid relying on direct edits to the base game's SettingsModel; a custom settings UI should integrate through supported menu extension patterns and be optional.

### Mod packaging and metadata

- Every mod package needs its own root `modDesc.xml`, unique technical mod name, version, title/description, icon, script load list, localization reference, and multiplayer declaration.
- The two AgriSystems mods must have separate technical names and independent ZIP packages. They must not depend on each other being installed.
- Keep shared source concepts in the repository's common design layer, but compile/copy only the required common files into each distributable mod package. Do not require a third shared ZIP unless a hard technical dependency is deliberately introduced and accepted.
- Keep the mod folder root flat at package level: `modDesc.xml` must be at the ZIP root, not nested one folder deeper. This is consistent with FS25 mod loading conventions documented by community tooling and the official mod packaging model.
- Localization should be external and complete for English and German from the first public build. Internal documentation remains English, as agreed for the public repository.

### Unresolved implementation verification

The following cannot be honestly closed from public documentation alone and need a local FS25 installation/runtime test:
- Exact wind updater object path, listener registration/removal, units and direction convention in the user's current game patch.
- Whether wind state is already synchronized in a way accessible to server-only gameplay logic, and whether weather changes expose an event suitable for sampling.
- Exact modSettings XML read/write helper and path behavior on dedicated servers.
- Actual callback ordering when multiple specializations observe sprayer work-area processing, especially with Precision Farming, AI workers, externally supplied fertilizer and attached tanks.
- Exact field lookup API and cluster-system internal ID lifecycle, since the public source mirror is incomplete.


## Gameplay model research – agronomic and biosecurity evidence

This section defines evidence-backed gameplay relationships. It deliberately does not prescribe false precision: the real-world sources identify influencing factors and direction of effect, but they do not provide one universal formula that can be transplanted into FS25.

### Spray drift – factors and proposed model boundaries

Government and extension guidance consistently identifies the following factors as relevant to off-target spray movement:

- wind speed and direction at nozzle/release height;
- atmospheric stability and gustiness, including increased risk during dead-calm inversion conditions;
- droplet size / spray quality;
- nozzle type and condition;
- spray pressure;
- boom height above target;
- forward speed and boom stability;
- temperature and relative humidity, through droplet evaporation;
- crop canopy and target interception;
- sensitive areas and downwind buffer zones.

Sources: UK HSE spray drift guidance; Health Canada applicator summary; Ontario government guidance; Agriculture Victoria guidance.

**Direction of effect for gameplay:**
- Higher sustained wind generally increases downwind transport; gusty or rapidly changing direction increases unpredictability.
- Dead calm must not be treated as automatically risk-free; inversion conditions can leave droplets suspended and allow later movement.
- Smaller droplets are more drift-prone; larger/coarser droplets reduce drift.
- Higher boom height increases time/distance available for transport; lowering the boom within correct overlap/coverage limits reduces drift.
- High pressure often produces finer droplets for conventional hydraulic nozzles; pressure/nozzle relationships are nozzle-specific, so a single global pressure curve is not physically universal.
- Higher travel speed can create turbulence, boom bounce and unstable height, increasing risk.
- High temperature and low relative humidity increase evaporation and can make droplets smaller.
- Damaged/dirty nozzles and poor calibration can create uneven output and unintended droplet distributions.
- A crosswind is not intrinsically safe; the important question is whether wind carries spray toward a sensitive receptor.

**Recommended FS25 abstraction:** calculate a bounded risk/transport score, not a CFD simulation. Keep separate components:
1. drift propensity at the nozzle (droplet class, pressure/nozzle, height, temperature/humidity, maintenance);
2. transport direction and distance (wind vector/speed, gust factor, time aloft);
3. receptor exposure (downwind position, buffer distance, sensitive-area category);
4. deposition/retention on the target (crop canopy and spray application quality).

This separation makes tuning and debugging possible. The model should output explainable reasons (e.g. “fine droplets + high boom + downwind sensitive edge”), not only an opaque number. Keep a conservative default mode and allow drift to be disabled or tuned by server configuration.

**Important physical limitation:** wind vector alone is insufficient to predict where every droplet lands. Real spray drift depends on droplet-size distribution, evaporation, atmospheric turbulence, nozzle characteristics, target interception and terrain. FS25 does not expose a physical droplet simulation for arbitrary mods in the reviewed API. The initial mod should therefore use a deterministic, calibrated gameplay approximation, clearly labelled as such.

### Sprayer engineering – wear, blockage and calibration

The sources establish that spray quality depends on nozzle choice, pressure, calibration, nozzle condition and operating settings. The reviewed FS25 base Sprayer provides nominal usage and work-area processing, not actual hydraulic pressure measurements or per-nozzle flow sensors.

Recommended custom model:
- Store nozzle condition and blockage as mod-owned equipment state, not as a fake native FS25 property.
- Model a partially blocked nozzle as reduced/uneven flow and coverage, not simply “more liters used”.
- Model worn nozzle output as deviation from its reference flow and spray pattern; avoid assuming all wear causes only increased flow or only reduced pressure.
- Model pump/pressure as a simplified commanded/available pressure value if no reliable native pressure signal exists.
- Calibration should compare expected total output against measured/simulated output over a fixed interval or test area.
- Apply condition effects to coverage uniformity and efficacy. Keep the native game application and consumption path intact in the first release.
- Make nozzle count/type mapping data-driven and optional. Do not assume all sprayers expose physical nozzle objects or one node per nozzle.

The game should not require players to manually calibrate every time. Offer a simple calibration action and a configurable realism level. If nozzle metadata is unavailable, use a generic equipment profile with a warning rather than breaking support for the implement.

### Sprayer cleaning – residues and contamination

SDSU Extension's sprayer clean-out guidance emphasizes that residue can remain in the tank, hoses, boom, nozzle bodies, strainers, filters, screens and boom ends. It recommends emptying the tank, rinsing/agitating, flushing the boom and lines, cleaning filters/nozzles, and following the product label and machine manual. Some products require repeated rinses or specific tank-cleaning solutions.

Recommended gameplay model:
- Track residue separately for tank, plumbing/boom, filters and nozzle assemblies, but allow a simplified combined-residue mode for performance and usability.
- A tank rinse alone must not instantly clear all system residue.
- Cleaning effectiveness depends on rinse volume, agitation/time, flushing through the boom, filter/nozzle cleaning and whether a compatible cleaner is used.
- Switching from one product to another should create a contamination risk proportional to remaining residue and product incompatibility.
- A cleaning operation should consume water/cleaner and time, and create rinse waste that must be disposed of at an appropriate location in realistic mode.
- Avoid real chemical compatibility claims for invented in-game product names. Use abstract compatibility classes such as compatible / caution / incompatible and keep them configurable.
- Cleaning outside surfaces/tires can be a separate optional hygiene action; it should not be conflated with internal tank cleaning.

### Field contamination – transfer model

Plant disease and weed-seed transfer by equipment is a plausible gameplay mechanic, but it should be kept distinct from spray drift:
- Spray drift is airborne off-target movement during/after application.
- Field contamination is mechanical transfer via tires, implements, crop residues, soil, mud and weed seeds.
- Record contamination by field or farmland only after the field identity strategy is validated. Until then, farmland-level state is safer than inventing a field ID.
- Equipment contamination should be accumulated from relevant work/field contact, then reduced by cleaning at a wash point.
- Avoid scanning every terrain pixel or every frame. Use event-driven work-area callbacks and coarse spatial sampling with server-side throttling.

### Farm Biosecurity – transmission and control factors

Government and animal-health guidance consistently supports the following biosecurity pathways and controls:
- New or returning livestock can introduce disease; isolate/quarantine and monitor them before mixing with resident stock.
- Sick animals should be separated; avoid shared feed/water/equipment and direct contact where possible.
- People, vehicles, trailers, boots, clothing and shared equipment can carry contaminated mud, manure or organic material between sites.
- Visitor access should be restricted, routed through designated entry/parking areas, and recorded where traceability is needed.
- Clean first, then disinfect. Disinfectant choice, dilution and contact time matter; applying disinfectant over dirt is not equivalent to proper cleaning.
- Buildings, pens, vehicles, livestock trailers, handling equipment, feed/water troughs and footwear can require cleaning/disinfection.
- Internal farm biosecurity (separation, dedicated equipment, age groups, all-in/all-out where appropriate) is distinct from external biosecurity (controlling introduction from outside).
- Vaccination can reduce risk/severity for specific diseases but is disease-specific and should not be represented as universal immunity.

Sources: UK Government livestock disease prevention; Australian Department of Agriculture livestock producer guidance; WOAH foot-and-mouth disease recommendations; Canadian Food Inspection Agency farm biosecurity planning; Western Australia DPIRD biosecurity steps.

**Recommended FS25 abstraction:** model a small number of disease profiles with configurable incubation, infectiousness, transmission routes, severity and recovery. Keep disease-specific parameters data-driven. Do not simulate real veterinary diagnosis or treatment. The game should communicate risk and management consequences, not claim clinical accuracy.

### Biosecurity transmission graph

A practical state model can be represented as:
- **Sources:** infected or exposed animal groups, contaminated equipment/vehicles, contaminated visitor routes, contaminated pens/buildings.
- **Contacts:** animal mixing/movement, shared equipment, shared feed/water, people/vehicle movement, manure/bedding handling.
- **Controls:** quarantine, separation, visitor restrictions, dedicated equipment, cleaning, disinfection, vaccination where defined, and movement restrictions.
- **Outcomes:** exposure, infection after incubation, recovery/death/removal as abstract game outcomes, and contamination decay/clearance after cleaning.

Risk should depend on exposure intensity and hygiene state, not random disease generation without a pathway. Random events may introduce an initial external threat, but subsequent spread should be explainable by contacts and control failures.

### Biosecurity score – design warning

A single Biosecurity Score is useful as a player-facing summary, but should not be the source of truth. Store the underlying factors (quarantine compliance, cleaning, visitor controls, equipment hygiene, housing hygiene, animal health monitoring). Derive the score from these factors. This avoids a single arbitrary number masking the reason for risk and allows separate module tuning.

### Scope control for first releases

- Spray Drift: deterministic risk/transport approximation, clear visual or HUD feedback, sensitive-area/buffer handling, server-side calculation.
- Sprayer Engineering: nozzle/equipment condition and coverage penalty; postpone hydraulic pressure simulation until a reliable implement profile/data source exists.
- Sprayer Cleaning: tank/line/filter residue with a simple rinse/flush workflow first; expand to detailed components later.
- Field Contamination: optional and coarse-grained; implement only after stable spatial field/farmland resolution.
- Farm Biosecurity: cluster-level disease exposure with quarantine, equipment/vehicle/visitor hygiene and a derived Biosecurity Score. Do not attempt full veterinary epidemiology in the first version.


## Official GDN cross-check – FieldManager API surface

The direct FS25 GDN page for `FieldManager` (Script v1.20.0.0) lists only these declared functions: `delete`, `initDataStructures`, `loadFromXMLFile`, `loadMapData`, `new`, `saveToXMLFile`, and `unloadMapData`. It does **not** list `getFieldAtWorldPosition` as a FieldManager method. The GDN code also shows `self:getFieldById(fieldId)` internally, but this is not listed as a declared FieldManager function on that page; it may be inherited or otherwise provided by the field/manager base system.

A community FS25 soil mod changelog reports `g_fieldManager:getFieldAtWorldPosition(x, z)` as its primary field lookup and calls it a Tier 0 API. Its development documentation recommends that lookup, but the public game-source mirror inspected here does not contain a corresponding implementation, and the public source file for the mod's current branch did not expose the call in the expected core files. This is therefore a discrepancy between the official class reference and community implementation notes.

**Updated decision:** do not assume that `getFieldAtWorldPosition` is a stable public method on every FS25 build. Before coding field-specific state, inspect the exact local game build for the method and confirm its return type and nil behavior. If it exists, wrap it in a single adapter and validate the returned field object/ID. If it does not, use farmland association for the first release or implement a separate geometry-based lookup only if map compatibility tests justify the cost. This is a known blocker for exact field-level contamination, not for the other Spray & Hygiene modules.

## FS25 runtime and compatibility notes

- The FS25 1.24 changelog reports that Lua `loadstring` was disabled for security reasons. The project must not use `loadstring` or dynamic compilation as a configuration or plugin mechanism.
- Avoid depending on undocumented Lua standard-library behavior or game internals that change between patches. Use ordinary Lua tables, explicit numeric bounds, and documented engine APIs. Keep compatibility shims small and centralized.
- A mod should declare multiplayer support only if all authoritative simulation is server-side and every client-visible state change is synchronized. A metadata flag alone does not make the mod multiplayer-safe.
- Keep script loading deterministic in `modDesc.xml`: shared constants/utilities first, then state/data classes, then event classes, then managers/specializations, then optional UI. Avoid relying on incidental filesystem enumeration or file order.
- Add explicit guards for optional game systems and mod integrations (Precision Farming, AI workers, external fill sources, map-specific field systems). Missing optional dependencies must degrade gracefully rather than prevent the mod from loading.
- Never overwrite a global game class method unless the extension point is required and tested. Prefer specialization event listeners; if an overwrite is unavoidable, call the supplied `superFunc` exactly once and preserve its return values/state side effects.

## Implementation readiness implications

The following areas are now sufficiently understood to design their first implementation layer:
- Server-authoritative event and persistence architecture.
- Native sprayer work-area lifecycle, fill source resolution, and nominal usage formula.
- Husbandry cluster lookup and delegated save/load/stream synchronization at the placeable level.
- Real-world factors that should influence drift, cleaning, sprayer condition, and biosecurity gameplay.

The following remain build-specific or source-incomplete and must be treated as explicit verification gates before the affected module is coded:
- FS25 wind updater path, values, units, direction convention and multiplayer behavior.
- Exact field-at-position lookup API and return type.
- AnimalClusterSystem/cluster implementation: ID generation, persistence stability, merge/split/removal behavior.
- Exact callback order for our own specialization relative to native Sprayer and optional third-party specializations.
- Exact modSettings read/write path behavior on a dedicated server and how host settings are distributed to connected clients.


## Release, platform, and test strategy

### Current toolchain compatibility

The GDN downloads page lists:
- Farming Simulator 25 TestRunner v0.9.23 for FS25 1.25.0+ (20 October 2026).
- TestRunner v0.9.22 for FS25 1.24.0+ (29 September 2026).
- Icon Generator v10.0.5 for FS25 1.24.0+.

This establishes that the current official test toolchain has moved to the 1.25 generation, while the surfaced GDN scripting reference still labels its API Script/Engine v1.20.0.0. Do not assume that the API documentation version number is the same as the current game patch. Record both separately in research and test reports.

**Release requirement:** run the matching GIANTS TestRunner on each unpacked mod folder before creating the release ZIP, then test the final ZIP in the actual game. TestRunner is a validation gate, not a substitute for runtime, multiplayer, savegame migration, or compatibility testing.

### Platform consequences

These AgriSystems mods require Lua script code. External script mods are a PC/Mac target; they are not suitable for console distribution/crossplay under the current FS25 script-mod restrictions. The project should declare PC/MAC as the intended platform and must not promise PS5/Xbox support.

Multiplayer and dedicated-server support remain achievable on PC/Mac, but every client must use the same mod version and the server must own authoritative simulation. Test a true dedicated server, not only a locally hosted listen server.

### ModHub-facing package requirements

GIANTS' ModHub guidelines state that mod filenames should use the `FS25_` prefix, avoid version numbers and non-English characters in the filename, and preserve the published filename for updates (using the prescribed update suffix for submission packages). The `modDesc` version should match the game version targeted by the submission. Descriptions must be clear and detailed in supported languages.

For this project:
- Technical ZIP names: `FS25_AgriSystems_SprayHygiene.zip` and `FS25_AgriSystems_FarmBiosecurity.zip` (final exact technical naming to be fixed before the first public build).
- Keep the two mods independent and separately selectable.
- Use separate version histories/changelogs even though they share a repository.
- Do not bundle source repository documentation, tests, Git files, or development assets into the player ZIP.
- Verify the final ZIP has `modDesc.xml` at archive root, not in an extra wrapper directory.

### Minimum test matrix

**Single-player**
- Fresh save, existing save, save/reload, mod disabled and re-enabled.
- Default map and at least one complex community map.
- Base-game sprayers across different configurations (self tank, external tank, variable work width, different nozzle/effect setups).
- Empty tank, partially filled tank, external purchase/source, AI helper use, implement attach/detach, fill-type change.
- Settings defaults, changed settings, reset, invalid/missing config values.

**Multiplayer / dedicated server**
- Host and remote client join while the mod is active.
- Late join while equipment/animal/field state already exists.
- Two clients operating different sprayers/vehicles simultaneously.
- Client disconnect/reconnect and server restart.
- Permission and farm ownership validation for actions.
- Ensure no client-only duplicate simulation, double consumption, divergent state, or save corruption.

**Compatibility**
- Precision Farming present/absent.
- Courseplay/AI worker present/absent.
- External fill tanks and common sprayer source configurations.
- Map with unusual farmland/field geometry.
- Other script mods that add settings pages or modify sprayer behavior.
- Mod load order changed; no hard dependency on another AgriSystems ZIP.

**Performance**
- Large map with many fields/farmlands.
- High number of animals/husbandries.
- Many active sprayers and attached implements.
- Ensure no full-table or full-map scans every frame; use event-driven updates, bounded sampling and dirty-state replication.
- Log only state transitions/errors by default; detailed traces behind a debug setting.

**Regression**
- Confirm native crop application and native fill-unit consumption remain unchanged when optional realism modules are disabled.
- Confirm disabling one module does not disable unrelated modules.
- Confirm uninstalling a mod does not corrupt the save; define whether orphaned mod-owned XML is retained or safely ignored.


## Script-only integration – registering with existing sprayer vehicle types

The FS25 GDN documents the relevant manager lifecycle:

- `SpecializationManager:addSpecialization(name, className, filename, customEnvironment)` registers a custom specialization.
- `TypeManager:validateTypes()` validates type specializations and prerequisites.
- `TypeManager:addSpecialization(typeName, specName)` adds a registered specialization to a specific vehicle type.
- `TypeManager:finalizeTypes()` subsequently registers events, functions, overwritten functions and event listeners for the specializations in each type.

A public FS25 script-mod implementation demonstrates the common integration pattern of registering the custom specialization with `g_specializationManager` and appending a function to `TypeManager.validateTypes` to inject the specialization into eligible vehicle types. This is community implementation evidence; the manager methods themselves are official GDN-documented.

**Recommended approach for Spray & Hygiene:**
1. Register the mod's own specialization once through the specialization manager.
2. During vehicle type validation, iterate registered vehicle types and add the specialization only to types that actually contain the base-game `Sprayer` specialization (and any additional prerequisites that the mod truly needs).
3. Do not add it to every vehicle type. This reduces unnecessary per-vehicle overhead and prevents unrelated types from acquiring a sprayer-only spec.
4. Let normal type finalization register the specialization's listeners and functions.
5. Use a unique namespaced specialization name derived from the mod's technical name. Avoid global generic class names and avoid modifying the base `Sprayer` class directly.
6. Keep the prerequisite check tolerant: if the vehicle lacks a sprayer or required fill-unit behavior, the mod must not attach its sprayer-specific functionality.

This registration path is more appropriate for a global script mod than editing every vehicle XML. It also avoids a dependency on individual mod authors adding our specialization manually.

**Critical compatibility checks before implementation:** exact type manager hook timing in FS25 1.25, exact base specialization object identity/name, whether type injection is repeated during map/type reloads, and interaction with other mods that also append `validateTypes`. The integration must be idempotent and log how many types were injected. It must not silently inject twice or add duplicate specialization entries.

### Event hook choice

For the Spray & Hygiene modules, the base sprayer's registered callbacks are the primary integration points. Prefer registering our own listener for:
- `onStartWorkAreaProcessing` when a pre-processing snapshot is required;
- `onEndWorkAreaProcessing` for completed server-side processing and authoritative native usage;
- `onFillUnitFillLevelChanged` for changes to the sprayer's own fill unit, while remembering that product can come from a linked external fill source.

Avoid a permanent per-frame `onUpdate` loop for drift or contamination. Use work-area callbacks to collect the work footprint and accumulate simulation time, then process at a bounded interval. If a feature must react to changing wind between work-area callbacks, use a low-frequency server-side sampling interval and cache the latest wind state.

### Separate mod namespaces

Both mods should use separate technical names and unique global namespaces. Common code can be duplicated into each package at build time, but the runtime must not assume the other mod is present. If both mods are installed, their shared helper code must not overwrite the same globals or register duplicate event classes. Prefix every event, specialization, settings file, log category and savegame XML root with its own mod identity.


## Script-only integration – livestock husbandry placeable types

The same generic FS25 `TypeManager` lifecycle is used for placeable types. The GDN documents `TypeManager:addSpecialization(typeName, specName)` and `validateTypes()`; the base FS25 husbandry specialization exposes `onHusbandryAnimalsUpdate(clusters)`, `getClusters()`, and `getClusterById(id)` through the husbandry placeable.

**Recommended Farm Biosecurity integration:**
1. Register a dedicated placeable specialization with the mod's namespace.
2. Hook the generic type validation path for the placeable type manager only.
3. Add the biosecurity specialization only to placeable types that already contain `PlaceableHusbandryAnimals`.
4. Subscribe to the husbandry's `onHusbandryAnimalsUpdate` event and reconcile the current cluster collection when it fires.
5. Use the placeable object as the husbandry scope and current cluster IDs as lookup keys, but keep a mod-owned persistent record key separate because the underlying cluster ID lifecycle is not yet proven stable.
6. Keep all disease progression, exposure, and quarantine state server-authoritative.

Do not attach the livestock disease specialization to every placeable. Do not create one update loop per animal. Update when cluster membership changes, on relevant simulation time intervals, and on contact events. A cluster represents a group and may contain multiple animals; this is suitable for scalable disease simulation but cannot represent different health status for individual animals inside one cluster unless the engine cluster is split or the mod tracks individual-level overlays itself. Individual-level simulation is therefore out of scope for the first release.

**Open technical check:** verify the exact runtime global and lifecycle for the placeable type manager in the user's FS25 1.25 build, plus whether all husbandry types use the base specialization class directly or some map/mod husbandries implement alternate animal systems.
