# Build scripts

## Build both FS25 mods

Run PowerShell from the repository root:

    .\tools\Build-Mods.ps1

The script validates each modDesc.xml, every extraSourceFiles entry, the declared English/German localization files, and specialization scripts referenced from scripts/register.lua. It stages runtime directories only and creates:

- FS25_AgriSystems_SprayHygiene.zip
- FS25_AgriSystems_FarmBiosecurity.zip

The ZIP root contains modDesc.xml directly. Documentation, tests, research, Git metadata and development files are excluded.

Use -Clean to remove the previous staging directory before building:

    .\tools\Build-Mods.ps1 -Clean

This script packages the development builds. It does not run GIANTS TestRunner or certify the mods in-game.
