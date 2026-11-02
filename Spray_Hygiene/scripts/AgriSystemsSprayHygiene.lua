AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}

local Mod = AgriSystemsSprayHygiene

Mod.MOD_NAME = g_currentModName or "FS25_AgriSystems_SprayHygiene"
Mod.MOD_DIRECTORY = g_currentModDirectory or ""
Mod.VERSION = "0.8.2.0"
Mod.CONFIG = nil
Mod.STATE_STORE = nil

local function log(message)
    print(string.format("[%s] %s", Mod.MOD_NAME, message))
end

function Mod:loadMap()
    if self.Config == nil then
        log("ERROR: configuration module was not loaded; using an empty safe configuration.")
        self.CONFIG = {}
        return
    end

    self.CONFIG = self.Config.validate(nil)

    if self.SprayerCondition == nil or self.SprayerCleaning == nil
        or self.SprayDrift == nil or self.FieldContamination == nil
        or self.StateStore == nil then
        log("ERROR: one or more gameplay modules are missing; gameplay remains inactive.")
        return
    end

    self.STATE_STORE = self.StateStore.new(
        g_server ~= nil,
        self.CONFIG.contamination.maximumLoad
    )

    log(string.format(
        "Development foundation loaded (version %s). In-game menu registration uses the native TabbedMenu page lifecycle; automatic gameplay effects and savegame persistence remain inactive.",
        self.VERSION
    ))
end

function Mod:deleteMap()
    self.STATE_STORE = nil
    self.CONFIG = nil
end

function Mod:getConfiguration()
    return self.CONFIG
end

function Mod:getStateStore()
    return self.STATE_STORE
end

addModEventListener(Mod)
