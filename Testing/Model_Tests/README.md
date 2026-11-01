# Pure Lua model tests

These test scripts run without GIANTS Engine and do not certify FS25 integration.

From the repository root, with Lua 5.1 or a compatible Lua interpreter:

    lua Testing/Model_Tests/Run_Spray_Hygiene.lua
    lua Testing/Model_Tests/Run_Farm_Biosecurity.lua

The scripts load the pure model files directly and use Lua assertions. They do not test modDesc loading, XMLFile behavior, network streams, specialization registration, dedicated servers or savegame reloads.
