# Build scripts

## Build both FS25 mods locally

Requirements: Python 3.10 or newer.

From the repository root in PowerShell:

    .\tools\Build-Mods.ps1 -Clean

Or run Python directly:

    python tools/build_mods.py --clean

The build validates:
- XML syntax in each modDesc.xml and declared English/German localization files.
- Every extraSourceFiles entry.
- Dynamically registered specialization scripts referenced by scripts/register.lua.
- ZIP integrity and the required root-level modDesc.xml.

It creates:
- Releases/FS25_AgriSystems_SprayHygiene.zip
- Releases/FS25_AgriSystems_FarmBiosecurity.zip

Only runtime directories are included. Documentation, tests, Git metadata and development files are excluded. Both packages are independent.

GitHub Actions runs the same build after Lua syntax and model tests pass, then uploads both ZIPs as a 30-day workflow artifact. This is a development build, not GIANTS TestRunner certification or proof of in-game compatibility.
