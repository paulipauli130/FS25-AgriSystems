# Build scripts

## Build both FS25 mods

Run PowerShell from the repository root:

    .\tools\Build-Mods.ps1

The script validates each modDesc.xml and every extraSourceFiles reference, stages only runtime directories, and creates two ZIP files under Releases:

- FS25_AgriSystems_SprayHygiene.zip
- FS25_AgriSystems_FarmBiosecurity.zip

The ZIP root contains modDesc.xml directly. Repository documentation, tests, research, Git metadata and development files are not included.

Use -Clean to remove the previous staging directory before building:

    .\tools\Build-Mods.ps1 -Clean

This packaging script does not run GIANTS TestRunner or certify the mods in-game.
