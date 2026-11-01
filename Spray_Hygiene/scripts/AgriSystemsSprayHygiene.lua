AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}

local Mod = AgriSystemsSprayHygiene

Mod.MOD_NAME = g_currentModName or "FS25_AgriSystems_SprayHygiene"
Mod.MOD_DIRECTORY = g_currentModDirectory or ""
Mod.VERSION = "0.1.0.0"
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
    log(string.format("Development bootstrap loaded (version %s). No gameplay hooks are active.", self.VERSION))
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
