# FS25 AgriSystems – Technical Architecture

## 1. Overview

This document describes the planned technical architecture of FS25 AgriSystems.

The architecture is designed to support two independent Farming Simulator 25 mods while maintaining consistent development standards and reusable components.

The two products are:

- AgriSystems Spray & Hygiene
- AgriSystems Farm Biosecurity

The architecture must support modular development, savegame persistence, multiplayer synchronisation and configurable gameplay systems.

**Important:** All technical implementation details must be verified against the actual Farming Simulator 25 scripting environment and available APIs before implementation.

---

## 2. Architectural Principles

The following principles guide development:

- Modularity: Each gameplay system should be implemented as a separate module.
- Independence: Both mods must function without requiring the other.
- Reusability: Common functionality should be shared where practical.
- Server Authority: Gameplay-critical calculations and state changes should be controlled by the server.
- Persistence: Relevant gameplay data must survive savegame reloads.
- Configuration: Gameplay parameters should be configurable without modifying Lua source code.
- Compatibility: Avoid unnecessary modifications to base-game systems.
- Maintainability: Code should remain readable, documented and testable.

---

## 3. High-Level Structure

```text
AgriSystems
│
├── Core
│   ├── Logging
│   ├── Configuration
│   ├── Savegame
│   ├── Events
│   ├── Networking
│   └── Utilities
│
├── Spray_Hygiene
│   ├── Main
│   ├── Modules
│   │   ├── SprayDrift
│   │   ├── SprayerEngineering
│   │   ├── SprayerCleaning
│   │   └── FieldContamination
│   ├── Config
│   └── UI
│
└── Farm_Biosecurity
    ├── Main
    ├── Modules
    │   ├── Quarantine
    │   ├── DiseaseTransmission
    │   ├── VehicleHygiene
    │   ├── EquipmentHygiene
    │   ├── BarnHygiene
    │   ├── VisitorManagement
    │   └── BiosecurityScore
    ├── Config
    └── UI
```

This is a logical architecture. The final physical folder structure may differ depending on Farming Simulator 25 loading requirements.

---

## 4. Core Systems

Common functionality should follow consistent interfaces.

### 4.1 Logging

The logging system should provide:

- Informational messages.
- Warnings.
- Errors.
- Debug output.
- Consistent prefixes for each module.
- Configurable debug logging.

Example:

```lua
AgriSystems.log("SprayDrift", "Spray drift calculation initialized")
```

### 4.2 Configuration

Gameplay parameters should be configurable.

Examples:

- Enable or disable individual modules.
- Adjust simulation intensity.
- Configure contamination risks.
- Set cleaning effectiveness.
- Adjust maintenance intervals.
- Configure notification behaviour.

Configuration should use supported XML or other appropriate formats.

### 4.3 Savegame Persistence

Gameplay data must be stored in the savegame where appropriate.

Potential data includes:

- Sprayer condition.
- Nozzle wear.
- Tank residue.
- Equipment contamination.
- Field contamination.
- Livestock quarantine status.
- Barn hygiene.
- Biosecurity Score.

Savegame data must be versioned to allow future updates without unnecessarily breaking existing saves.

### 4.4 Event System

Gameplay state changes should use a consistent event-handling approach.

Examples:

- Sprayer maintenance completed.
- Cleaning procedure completed.
- Field contamination transferred.
- Animal group placed in quarantine.
- Visitor access recorded.

The implementation must use supported Farming Simulator 25 event and networking mechanisms.

---

## 5. Module Architecture

Each gameplay module should have a clearly defined responsibility.

A module should ideally contain:

- Initialisation.
- Configuration loading.
- Runtime logic.
- State management.
- Savegame integration.
- Multiplayer integration where required.
- Cleanup and shutdown handling.

Modules should communicate through defined interfaces rather than accessing each other's internal implementation directly.

---

## 6. Multiplayer Architecture

Multiplayer compatibility is a core requirement.

The planned architecture follows these principles:

- The server is authoritative for gameplay-critical state.
- Clients receive the relevant synchronised state.
- Client-side interfaces must not independently modify authoritative gameplay data.
- Events must be validated by the server.
- Savegame persistence must be handled consistently.
- Dedicated server behaviour must be tested.

Potential synchronised data includes equipment condition, contamination states, quarantine status and relevant field information.

The exact event and synchronisation implementation must be verified against the Farming Simulator 25 networking API.

---

## 7. User Interface

Both mods should provide a consistent user experience.

Planned interface elements:

- Module status.
- Equipment condition.
- Contamination information.
- Cleaning status.
- Quarantine information.
- Biosecurity Score.
- Configuration options.
- Notifications and warnings.

The interface should communicate relevant information without overwhelming the player.

---

## 8. Performance Considerations

The simulation must avoid unnecessary continuous calculations.

Planned optimisation approaches:

- Event-driven updates where possible.
- Controlled update intervals.
- Avoid unnecessary scans of all vehicles, fields or animals.
- Cache frequently accessed data where appropriate.
- Limit multiplayer network traffic.
- Avoid excessive savegame writes.

Performance must be evaluated in realistic single-player and multiplayer scenarios.

---

## 9. Compatibility Strategy

AgriSystems should minimise conflicts with other mods.

Development guidelines:

- Avoid unnecessary overwriting of base-game functions.
- Use supported extension mechanisms.
- Check whether another mod has already modified relevant game functions.
- Handle missing or unsupported data safely.
- Log compatibility problems clearly.
- Test with common mod combinations.

Compatibility cannot be guaranteed for every third-party mod.

---

## 10. Error Handling

The system should fail safely wherever possible.

Examples:

- Missing configuration values should use documented defaults.
- Invalid savegame data should not crash the game.
- Unsupported equipment should be handled gracefully.
- Missing optional functionality should not prevent unrelated modules from loading.

Errors should provide enough information to identify the affected module and problem.

---

## 11. Development and Testing

Technical implementation should follow this sequence:

1. Verify relevant Farming Simulator 25 APIs.
2. Create a minimal working mod structure.
3. Implement logging and configuration.
4. Implement savegame persistence.
5. Establish multiplayer event handling.
6. Develop individual gameplay modules.
7. Test modules independently.
8. Test interactions between modules.
9. Perform multiplayer and dedicated server testing.
10. Document verified behaviour.

---

## 12. Open Technical Questions

The following points require investigation before implementation:

- Available APIs for sprayer pressure and nozzle data.
- Access to weather and wind information.
- Reliable identification of field areas and neighbouring fields.
- Available animal health and disease-related interfaces.
- Supported savegame extension mechanisms.
- Multiplayer event registration and synchronisation.
- Supported user interface extension mechanisms.
- Compatibility with existing vehicle and equipment mods.

These questions must be resolved through official documentation, source inspection where permitted and in-game testing.

---

## 13. Architecture Status

**Current status:** Proposed architecture.

This document describes the intended design. Implementation details may change when technical limitations or better solutions are identified.
