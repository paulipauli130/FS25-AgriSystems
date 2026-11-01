AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}

local Mod = AgriSystemsSprayHygiene

Mod.MOD_NAME = g_currentModName or "FS25_AgriSystems_SprayHygiene"
Mod.MOD_DIRECTORY = g_currentModDirectory or ""
Mod.VERSION = "0.4.0.0"
Mod.CONFIG = nil

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
        or self.SprayDrift == nil or self.FieldContamination == nil then
        log("ERROR: one or more gameplay model modules are missing; gameplay remains inactive.")
        return
    end

    log(string.format(
        "Development foundation loaded (version %s). Condition, cleaning, drift and field contamination models are available; engine integration is inactive.",
        self.VERSION
    ))
end

function Mod:deleteMap()
    self.CONFIG = nil
end

function Mod:getConfiguration()
    return self.CONFIG
end

if type(addModEventListener) == "function" then
    addModEventListener(Mod)
else
    log("WARNING: addModEventListener is unavailable; bootstrap listener was not registered.")
end
