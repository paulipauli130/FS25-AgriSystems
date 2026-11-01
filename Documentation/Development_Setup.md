# FS25 AgriSystems – Development Setup

## 1. Overview

This document describes the recommended development environment for FS25 AgriSystems.

The goal is to establish a consistent workflow for developing, testing and maintaining both AgriSystems mods.

The project primarily uses Lua scripting and XML configuration files.

---

## 2. Required Software

### Farming Simulator 25

A working installation of Farming Simulator 25 is required for in-game testing.

The game installation also provides access to relevant game files and scripting resources for development.

### Visual Studio Code

Visual Studio Code is the recommended code editor.

It will be used for:

- Lua development.
- XML editing.
- Project-wide code navigation.
- Documentation.
- Git integration.

### Git

Git is used for version control.

All development changes should be tracked so that changes can be reviewed and reverted if necessary.

The public GitHub repository is the central location for source code and project documentation.

---

## 3. Recommended GIANTS Tools

Official tools and documentation are available through the GIANTS Developer Network.

**GDN:** https://gdn.giants-software.com/

Recommended resources:

- Farming Simulator 25 Scripting API Reference.
- GIANTS Editor.
- GIANTS Studio and available development tools.
- Official modding tutorials.
- Modding documentation and community forums.

The GIANTS Editor is mainly relevant when working with maps, 3D assets and I3D files. Pure Lua scripting does not require every graphical modding tool.

---

## 4. Recommended VS Code Extensions

### Farming Simulator IDE Support

The official GIANTS Software extension for Visual Studio Code is recommended.

It provides features such as:

- Lua IntelliSense.
- GIANTS Engine API autocomplete.
- XML schema validation.
- Lua debugging support.
- Script hot-reload support.
- Game log viewing.
- Lua documentation assistance.

Extension:

https://marketplace.visualstudio.com/items?itemName=GIANTSSoftware.farmingsimulator-ide

Additional extensions may be installed when needed.

---

## 5. Repository Workflow

The GitHub repository is the central development location.

Recommended workflow:

1. Pull the latest repository changes.
2. Create a branch for larger features or bug fixes.
3. Implement the changes locally.
4. Test the changes in Farming Simulator 25.
5. Review the game log for errors and warnings.
6. Commit the changes with a descriptive message.
7. Push the changes to GitHub.
8. Submit a Pull Request when changes should be reviewed before merging.

Small documentation changes may be committed directly to the main branch.

---

## 6. Local Development Structure

The local development environment should follow the repository structure.

```text
FS25-AgriSystems/
│
├── Documentation/
├── Core/
├── Spray_Hygiene/
├── Farm_Biosecurity/
└── Testing/
```

The actual installable mod structures will be defined separately.

Development source files and release ZIP files should remain clearly separated.

---

## 7. Testing Environment

Testing should be performed in a separate Farming Simulator 25 test environment where practical.

Test scenarios should include:

- Clean game installation.
- AgriSystems mod installed independently.
- Both AgriSystems mods installed together.
- Single-player gameplay.
- Multiplayer gameplay.
- Dedicated server gameplay.
- Existing savegame reloads.
- Compatibility with selected third-party mods.

Relevant game logs should be collected when investigating errors.

---

## 8. Game Log

The Farming Simulator log file is an important debugging resource.

On Windows, the typical location is:

```text
Documents/My Games/FarmingSimulator2025/log.txt
```

The log should be checked after each significant test.

Pay particular attention to:

- Lua errors.
- XML loading errors.
- Missing files.
- Invalid configuration values.
- Multiplayer synchronisation errors.
- Performance warnings.

---

## 9. Development Standards

All contributors should follow these standards:

- Use clear and descriptive file names.
- Keep Lua modules focused on individual responsibilities.
- Document important functions and configuration options.
- Avoid unnecessary dependencies.
- Do not commit temporary test files or personal configuration data.
- Test changes before marking them as complete.
- Keep release packages separate from development source code.

---

## 10. Technical References

Official and community resources:

| Resource | Link |
|---|---|
| GIANTS Developer Network | https://gdn.giants-software.com/ |
| FS25 Scripting API | https://gdn.giants-software.com/documentation.php |
| GIANTS Modding Tutorials | https://www.farming-simulator.com/dlc-detail.php?dlc_id=fs25mt60 |
| GIANTS VS Code Extension | https://marketplace.visualstudio.com/items?itemName=GIANTSSoftware.farmingsimulator-ide |

Official documentation should take priority when verifying game APIs and supported modding interfaces.

---

## 11. Status

**Current status:** Initial development environment defined.

Specific tool versions, game versions and testing procedures will be documented as development progresses.
