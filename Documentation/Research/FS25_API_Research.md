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

## Sprayer and fill-unit interfaces

### Confirmed in the FS25 GDN

- `FillUnit` is documented as the vehicle specialization for capacities and tanks; it manages fill types, capacities, and fill-level changes.
- The documented interface includes `getFillUnits()`, `getFillUnitByIndex(index)`, `getFillUnitCapacity(index)`, `getFillUnitFillLevel(index)`, `getFillUnitFillLevelPercentage(index)`, `getFillUnitFillType(index)`, and `getFillUnitFreeCapacity(index)`.
- `getFillUnitFillLevel(index)` returns the current fill level; `getFillUnitFillType(index)` returns the fill-type index. The implementation accesses the corresponding fill-unit entry in `spec_fillUnit.fillUnits`.
- `ExtendedSprayer` exists in the FS25 API. Its documented methods include `getSprayerUsage`, `getCurrentSprayerMode`, `getValidSprayerToUse`, and `getIsVehicleValid`. GIANTS' implementation of `getSprayerUsage` checks `self:getIsTurnedOn()`, reads `self.spec_sprayer`, resolves the active spray type, and uses work-area width and vehicle speed in usage calculations.
- The documented `ExtendedSprayer:processSprayerArea` processes a work area using its start/width/height nodes and executes the relevant field processing on the server. This provides a verified integration point to investigate for application detection, but not yet a complete implementation design.

### Current conclusion

Tank state and fill type can be read through documented FS25 FillUnit methods on objects that actually have the FillUnit specialization. Sprayer state and work-area processing are represented by FS25 sprayer-related specializations. We still need to establish a robust way to identify all sprayer implementations, including attached implements and non-standard modded sprayers, and determine the best safe hook points for nozzle wear, pressure/flow simulation, cleaning residues, and drift calculations. Do not assume every sprayer uses the same fill-unit index or the same specialization combination.

## Remaining verification steps

### Weather

1. Inspect the FS25 game scripts for the weather/wind updater implementation and the FS25 `PlaceableWindTurbine` call site.
2. Confirm whether `weather.windUpdater:getCurrentValues()` exists in FS25, and record its exact return values and units.
3. Confirm whether wind values are global or position-dependent, and establish the direction-vector convention.
4. Determine whether wind values should be read server-side and replicated to clients for consistent multiplayer drift calculations.

### Sprayer and fill units

1. Inspect FS25 `Sprayer`, `FillUnit`, `WorkArea`, and `ExtendedSprayer` source and exact specialization prerequisites.
2. Verify how attached implements are traversed and how sprayer fill units are selected for multi-tank or multi-product equipment.
3. Identify reliable hooks for detecting actual application rather than merely a switched-on sprayer.
4. Check server/client execution and synchronization before designing wear, clogging, or contamination state.

### Other systems

- Field and work-area APIs for application detection.
- Animal and husbandry APIs for Farm Biosecurity.
- Events, networking, and savegame persistence.
- Feature-to-API feasibility matrix before finalizing mod folder structures.

## General research rules

- Prefer official GIANTS documentation and game scripts.
- Community mods and community LUADOC are secondary evidence, not authoritative API guarantees.
- Do not assume FS22 code works unchanged in FS25.
- Record exact function signatures, units, coordinate conventions, lifecycle, and server/client behavior before implementation.
- Keep unresolved items explicitly marked as unresolved.
