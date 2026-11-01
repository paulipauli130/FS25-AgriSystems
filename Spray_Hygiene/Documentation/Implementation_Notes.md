# Spray & Hygiene — Implementation Notes

## Development build 0.1.0.0

This folder now contains the first loadable-mod foundation files:
- `modDesc.xml` with a script entry point and multiplayer declaration.
- `scripts/core/Config.lua` with namespaced defaults, deep-copy creation and bounded validation.
- `scripts/AgriSystemsSprayHygiene.lua` with a minimal mod-event-listener bootstrap.
- English and German localization starter files.

## Explicit limitations
- No vehicle specialization is registered or injected yet.
- No Sprayer callbacks are overridden or observed.
- No native spray application, fill consumption, wind, contamination, cleaning or equipment condition behavior is changed.
- Configuration currently uses safe in-memory defaults only; savegame persistence and server distribution are not implemented.
- The mod has not yet been loaded in FS25 and has not been run through GIANTS TestRunner.

## Next implementation gate
Install the unpacked `Spray_Hygiene` folder as a development mod and inspect the game log. Confirm that the descriptor, source files and event listener load without XML/Lua errors before adding specialization registration. Record the exact FS25 patch and TestRunner version used.
