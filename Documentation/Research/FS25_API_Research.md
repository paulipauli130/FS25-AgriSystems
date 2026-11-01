# Farming Simulator 25 – API Research

**Status:** Initial source review  
**Last reviewed:** 2026-11-01  
**Scope:** Technical feasibility research for FS25 AgriSystems  
**Implementation status:** No gameplay code has been started.

---

## 1. Primary Official Reference

The primary technical reference is the GIANTS Developer Network (GDN):

- [GIANTS Developer Network – Documentation](https://gdn.giants-software.com/documentation.php)
- [Farming Simulator 25 Lua API Reference](https://gdn.giants-software.com/documentation_scripting_fs25.php)
- [GIANTS Software – FS25 Modding Tutorials 6.0](https://www.farming-simulator.com/dlc-detail.php?country=us&dlc_id=fs25mt60&lang=en)
- [GIANTS Developer Network – Modding Tutorials](https://gdn.giants-software.com/videoTutorials2.php?LANGUAGE=en&c=5&p=0&s=3)

The GDN currently identifies its FS25 scripting reference as **Script v1.20.0.0** and **Engine v1.20.0.0**. The reference is divided into script and engine API categories.

Relevant script API categories visible in the official reference include:

- Animals
- Events
- Field
- FillTypes
- Networking
- Placeables
- Specialization and Specializations
- Vehicles
- Weather

These categories establish that official API documentation exists for the main areas relevant to AgriSystems. They do **not** by themselves prove that every planned gameplay feature can be implemented through a supported public interface.

## 2. Official Modding Workflow

GIANTS' official FS25 Modding Tutorials 6.0 cover the modding toolchain and the creation of a vehicle mod, including:

- Modding tools and Blender workflow
- Surface materials and object hierarchy
- Physics components and functional nodes
- modDesc.xml and vehicle XML setup
- Vehicle functions and additional features
- Mod packaging and ModHub submission

This is a useful official learning path. AgriSystems is primarily a script/gameplay project, so the Lua API reference and scripting tutorials are especially important.

## 3. Research Areas and Open Questions

The following areas must be checked against the exact FS25 API and, where necessary, tested in-game before implementation.

### 3.1 Sprayer Engineering

Questions to resolve:

- How can a script reliably identify active sprayer vehicles and their working tools?
- Which values expose fill level, fill type, application rate, working width and working state?
- Can nozzle configuration or pressure be read from existing vehicle XML/specializations?
- Can wear, blockage and flow variation be added without replacing or breaking base-game vehicle behaviour?
- Which existing functions are safe extension points?

**Status:** Not yet verified at class/function level.

### 3.2 Spray Drift and Weather

Questions to resolve:

- Which weather API values expose wind speed and direction?
- Are values available in a stable world-space coordinate system?
- What update frequency is appropriate?
- Can the actual spray working area be sampled or queried without expensive field-wide scans?
- How can drift be represented without modifying base-game crop or field systems unsafely?

**Status:** The official API contains a Weather category. The exact wind accessors and their units/coordinate conventions still need verification.

### 3.3 Sprayer Cleaning and Residues

Questions to resolve:

- How are sprayer fill types and tank contents represented?
- Can residues be tracked independently from the base-game fill level?
- How can cleaning water consumption be represented?
- What happens when a vehicle is saved, reloaded, sold or reset?
- How can the system avoid changing the behaviour of unrelated fill types?

**Status:** Not yet verified at class/function level.

### 3.4 Field Contamination

Questions to resolve:

- Which field/terrain APIs allow a vehicle's actual work area to be identified?
- Can contamination be stored per field or per sampled area without excessive savegame data?
- How can transfer from tyres, tools or other equipment be detected?
- Can the mechanic work on modded maps without relying on map-specific assumptions?

**Status:** The official API contains a Field category. Exact field and work-area interfaces still need verification.

### 3.5 Farm Biosecurity and Animals

Questions to resolve:

- How are animal husbandry objects, animal groups and animal statistics represented?
- Can newly purchased animals be identified as a separate group?
- Are animal movement, purchase, sale and transfer events exposed?
- Can quarantine and disease state be persisted safely?
- Which systems are available on dedicated servers?

**Status:** The official API contains an Animals category. Exact animal and husbandry interfaces still need verification.

### 3.6 Multiplayer and Persistence

Questions to resolve:

- Which event registration and network stream patterns are used by FS25?
- Which state changes must be server-authoritative?
- How should clients receive state updates?
- Which savegame loading/saving hooks are supported?
- How should save data be versioned and migrated?

**Status:** The official API contains Events and Networking categories. The exact supported patterns must be confirmed before choosing an implementation.

## 4. Technical Research Rules

1. Prefer the official GDN documentation and official GIANTS tutorials.
2. Use existing FS25 mods and community repositories as secondary examples only.
3. Do not assume that an FS22 API, class name or code sample works unchanged in FS25.
4. Record the exact class, function, arguments, return values and version for every API used.
5. Verify units, coordinate systems, server/client execution context and lifecycle behaviour.
6. Do not mark an API as usable until its behaviour has been checked in-game or confirmed by reliable source code/documentation.
7. Do not begin implementation while a feature depends on an unverified API.

## 5. Next Research Tasks

- [ ] Inspect the FS25 Weather API for wind speed, wind direction and update behaviour.
- [ ] Inspect vehicle and implement APIs for sprayer identification and working state.
- [ ] Inspect fill type and fill unit APIs for tank and residue tracking.
- [ ] Inspect Field and work-area APIs for spatial sampling.
- [ ] Inspect Animals and husbandry APIs for animal group identification.
- [ ] Inspect Events, Networking and savegame APIs for multiplayer persistence.
- [ ] Create a feature-to-API feasibility matrix.
- [ ] Only then define the final physical mod folder structures.

---

## 6. Reference Notes

The GDN page is versioned and may change as FS25 updates. Re-check the reference when the game or scripting version changes.

A community script-mod starter is available at [Jos-Modding/FS25_ScriptModStarter](https://github.com/Jos-Modding/FS25_ScriptModStarter). It may be useful as a secondary example of script-mod structure, specialization registration, multiplayer events and savegame persistence. It is **not** an official GIANTS specification and must not be copied without checking every pattern against the current game version.
