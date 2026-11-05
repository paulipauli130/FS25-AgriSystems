AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}

local Mod = AgriSystemsSprayHygiene

Mod.MOD_NAME = g_currentModName or "FS25_AgriSystems_SprayHygiene"
Mod.MOD_DIRECTORY = g_currentModDirectory or ""
Mod.VERSION = "0.8.9.0"
Mod.CONFIG = nil
Mod.STATE_STORE = nil

local function log(message)
    print(string.format("[%s] %s", Mod.MOD_NAME, message))
end

local SETTINGS_ROOT = "agriSystemsSprayHygiene"
local SETTINGS_FILENAME = "AgriSystemsSprayHygiene.xml"

function Mod:loadSettingsFromSavegame()
    if g_server == nil or self.CONFIG == nil then
        return
    end

    local mission = g_currentMission
    local missionInfo = mission ~= nil and mission.missionInfo or nil
    local savegameDirectory = missionInfo ~= nil and missionInfo.savegameDirectory or nil
    if savegameDirectory == nil or savegameDirectory == "" then
        log("Savegame settings load skipped: savegame directory is not available yet.")
        return
    end

    local path = savegameDirectory .. "/" .. SETTINGS_FILENAME
    if fileExists == nil or not fileExists(path) then
        log("No saved settings found; defaults are active.")
        return
    end

    local xmlFile = XMLFile.load("AgriSystemsSprayHygieneSettings", path)
    if xmlFile == nil then
        log("WARNING: saved settings XML could not be opened; defaults are active.")
        return
    end

    local key = SETTINGS_ROOT .. ".settings"
    local candidate = {
        enabled = xmlFile:getValue(key .. "#enabled", self.CONFIG.enabled),
        wearEnabled = xmlFile:getValue(key .. "#wearEnabled", self.CONFIG.wearEnabled),
        calibrationEnabled = xmlFile:getValue(key .. "#calibrationEnabled", self.CONFIG.calibrationEnabled),
        wearRateMultiplier = xmlFile:getValue(key .. "#wearRateMultiplier", self.CONFIG.wearRateMultiplier)
    }
    xmlFile:delete()

    self.CONFIG = self.Config.validate(candidate)
    log(string.format(
        "Loaded savegame settings: enabled=%s wear=%s calibration=%s wearRate=%.1fx",
        tostring(self.CONFIG.enabled), tostring(self.CONFIG.wearEnabled),
        tostring(self.CONFIG.calibrationEnabled), self.CONFIG.wearRateMultiplier
    ))
end

function Mod:saveSettingsToSavegame(missionInfo)
    if g_server == nil or self.CONFIG == nil or missionInfo == nil then
        return
    end

    local savegameDirectory = missionInfo.savegameDirectory
    if savegameDirectory == nil or savegameDirectory == "" then
        log("WARNING: savegame settings not written because the savegame directory is unavailable.")
        return
    end

    local path = savegameDirectory .. "/" .. SETTINGS_FILENAME
    local xmlFile = XMLFile.create("AgriSystemsSprayHygieneSettings", path, SETTINGS_ROOT)
    if xmlFile == nil then
        log("ERROR: could not create savegame settings XML.")
        return
    end

    local key = SETTINGS_ROOT .. ".settings"
    xmlFile:setValue(key .. "#enabled", self.CONFIG.enabled ~= false)
    xmlFile:setValue(key .. "#wearEnabled", self.CONFIG.wearEnabled ~= false)
    xmlFile:setValue(key .. "#calibrationEnabled", self.CONFIG.calibrationEnabled ~= false)
    xmlFile:setValue(key .. "#wearRateMultiplier", self.CONFIG.wearRateMultiplier or 1.0)
    local saved = xmlFile:save()
    xmlFile:delete()

    if saved == false then
        log("ERROR: failed to write savegame settings.")
    else
        log("Saved mod settings to the current savegame.")
    end
end

function Mod:installSavegameSettingsHook()
    if self._savegameSettingsHookInstalled then
        return
    end

    if FSCareerMissionInfo == nil or type(FSCareerMissionInfo.saveToXMLFile) ~= "function" then
        log("WARNING: FSCareerMissionInfo.saveToXMLFile is unavailable; savegame settings persistence is disabled.")
        return
    end

    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(
        FSCareerMissionInfo.saveToXMLFile,
        function(missionInfo)
            Mod:saveSettingsToSavegame(missionInfo)
        end
    )
    self._savegameSettingsHookInstalled = true
    log("Savegame settings hook installed.")
end

function Mod:loadMap()
    if self.Config == nil then
        log("ERROR: configuration module was not loaded; using an empty safe configuration.")
        self.CONFIG = {}
        return
    end

    self.CONFIG = self.Config.validate(nil)
    self:installSavegameSettingsHook()

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
        "Development foundation loaded (version %s). Server-side wear tracking and host-side session settings are active; other engine integrations remain gated.",
        self.VERSION
    ))
end

function Mod:loadMapFinished()
    -- The savegame directory is finalized when the current mission starts.
    -- Loading earlier can silently miss existing settings on newer FS25 builds.
    if g_messageCenter ~= nil and MessageType ~= nil and MessageType.CURRENT_MISSION_START ~= nil then
        g_messageCenter:subscribeOneshot(
            MessageType.CURRENT_MISSION_START,
            function()
                Mod:loadSettingsFromSavegame()
            end
        )
    else
        log("WARNING: mission-start message unavailable; savegame settings could not be scheduled for loading.")
    end
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
