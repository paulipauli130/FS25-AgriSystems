# FS25 AgriSystems — Development Setup

## 1. Overview
This document describes the development workflow for both independent FS25 script mods. The repository is the source of truth; installable mod folders are built separately from repository documentation and tests.

## 2. Required software
- Farming Simulator 25 for runtime testing.
- Git and GitHub Desktop for version control and synchronization.
- Visual Studio Code or another Lua/XML-capable editor.
- A Lua language server/parser compatible with the Lua version used by FS25, where available.

## 3. GIANTS resources
Official resources:
- GIANTS Developer Network: https://gdn.giants-software.com/
- FS25 Scripting API: https://gdn.giants-software.com/documentation_scripting_fs25.php
- FS25 Modding Tutorials: https://www.farming-simulator.com/dlc-detail.php?country=us&dlc_id=fs25mt60&lang=en
- GIANTS VS Code extension: https://marketplace.visualstudio.com/items?itemName=GIANTSSoftware.farmingsimulator-ide

Use the API reference and the installed game's script source to verify contracts. Community templates are useful examples, not authoritative specifications.

## 4. Repository workflow
1. Pull the latest changes with GitHub Desktop.
2. Make changes on a focused branch for substantial features; small documentation updates may go directly to main.
3. Keep each mod's runtime source under its own mod directory.
4. Run available static checks and inspect the diff.
5. Test in FS25 and inspect `Documents/My Games/FarmingSimulator2025/log.txt`.
6. Commit with a descriptive message and push.
7. Keep release ZIPs out of the source tree; publish separate ZIP assets only after acceptance tests pass.

## 5. Runtime development folders
The installable development folder for Spray & Hygiene is `Spray_Hygiene/`; its `modDesc.xml` must be at the root of that folder. The repository itself is not a loadable mod. Farm Biosecurity will have its own independent root folder and manifest when its implementation starts.

For an unpacked mod, the game reads the mod directory directly. For a release ZIP, `modDesc.xml` must be at the ZIP root, not inside an extra enclosing folder. Do not include repository docs, .git metadata, test saves, logs or developer tools in a release ZIP.

## 6. Current first-mod foundation
Spray & Hygiene currently contains a minimal manifest, bootstrap, validated default configuration and English/German localization starter files. It intentionally does not register a vehicle specialization or alter gameplay yet. This foundation must first be loaded in the target game and checked in `log.txt` before additional runtime hooks are added.

## 7. Test strategy
Static checks can validate XML well-formedness, Lua syntax, file references and package layout, but they cannot prove engine callback order, multiplayer authority or gameplay correctness.

Required runtime coverage:
- Clean game and existing save.
- Each mod installed independently; both installed together.
- Single-player and dedicated-server host/client/late-join/reconnect.
- Save/load and mod disable/re-enable.
- Precision Farming on/off, AI, external fill sources and supported third-party mods.
- Large farms/herds and map transitions.

Run GIANTS TestRunner matching the installed game patch before release. Record the exact game/TestRunner versions and the tests actually performed; never describe source review as runtime certification.

## 8. Game logs
Typical Windows log path:
```text
Documents/My Games/FarmingSimulator2025/log.txt
```
Check Lua/XML errors, missing files, invalid configuration, network synchronization warnings and performance messages after every significant test.

## 9. Project conventions
- Use namespaced identifiers and separate save roots per mod.
- Keep configuration versioned, range-checked and server-authoritative.
- Do not trust client-submitted gameplay state.
- Do not override native sprayer processing or deduct native fill in v1.
- Do not persist runtime animal cluster IDs.
- Do not commit personal settings, test saves or logs.

## 10. Status
The first Spray & Hygiene source foundation is committed but not yet game-tested. Farm Biosecurity remains at specification stage. GIANTS TestRunner execution and all in-game validation are pending.
