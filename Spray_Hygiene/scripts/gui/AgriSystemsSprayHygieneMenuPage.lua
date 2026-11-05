AgriSystemsSprayHygieneMenuPage = AgriSystemsSprayHygieneMenuPage or {}

local Page = AgriSystemsSprayHygieneMenuPage
Page.CLASS_NAME = "AgriSystemsSprayHygieneMenuPage"
Page.MENU_PAGE_NAME = "menuAgriSystemsSprayHygiene"
Page.SPRAYER_SPEC_TABLE = "spec_" .. (g_currentModName or "FS25_AgriSystems_SprayHygiene") .. ".agriSystemsSprayer"
Page._diagnosedVehicles = setmetatable({}, {__mode = "k"})
Page_mt = Class(Page, TabbedMenuFrameElement)

local WEAR_RATE_VALUES = {0.5, 1.0, 1.5, 2.0, 2.5, 3.0}

function Page.new()
    local self = Page:superClass().new(nil, Page_mt)
    self.name = Page.MENU_PAGE_NAME
    self.btnBack = {inputAction = InputAction.MENU_BACK}
    self:setMenuButtonInfo({self.btnBack})
    return self
end

function Page:initialize()
    Page:superClass().initialize(self)
    self:refresh()
    self:refreshSettings()
end

local function getConfig()
    return AgriSystemsSprayHygiene ~= nil and AgriSystemsSprayHygiene.CONFIG or nil
end

local function setBinaryOption(element, value)
    if element ~= nil and type(element.setState) == "function" then
        local state = value == true and BinaryOptionElement.STATE_RIGHT or BinaryOptionElement.STATE_LEFT
        -- In FS25 setIsChecked forwards its second argument as forceEvent.
        -- Set the state directly, skip the slider animation and do not fire callbacks.
        element:setState(state, false, true)
    end
end

local function getWearRateIndex(value)
    local bestIndex, bestDistance = 1, math.huge
    for index, rate in ipairs(WEAR_RATE_VALUES) do
        local distance = math.abs((tonumber(value) or 1) - rate)
        if distance < bestDistance then
            bestIndex, bestDistance = index, distance
        end
    end
    return bestIndex
end

function Page:refreshSettings()
    local c = getConfig()
    if c == nil then return end
    setBinaryOption(self.optModEnabled, c.enabled ~= false)
    setBinaryOption(self.optWearEnabled, c.wearEnabled ~= false)
    setBinaryOption(self.optCalibrationEnabled, c.calibrationEnabled ~= false)
    if self.optWearRate ~= nil then
        self.optWearRate:setState(getWearRateIndex(c.wearRateMultiplier or 1))
    end
end

function Page:changeSetting(key, element)
    if g_server == nil then
        if self.txtSettingsStatus ~= nil then self.txtSettingsStatus:setText(g_i18n:getText("ags_settings_host_only")) end
        self:refreshSettings()
        return
    end
    local c = getConfig()
    if c == nil then return end
    if element ~= nil then
        c[key] = element.state == BinaryOptionElement.STATE_RIGHT
    end
    self:refreshSettings()
    if self.txtSettingsStatus ~= nil then self.txtSettingsStatus:setText(g_i18n:getText("ags_settings_session_only")) end
end

function Page:onClickToggleMod()
    self:changeSetting("enabled", self.optModEnabled)
end

function Page:onClickToggleWear()
    self:changeSetting("wearEnabled", self.optWearEnabled)
end

function Page:onClickToggleCalibration()
    self:changeSetting("calibrationEnabled", self.optCalibrationEnabled)
end

function Page:onClickWearRate()
    if g_server == nil then
        if self.txtSettingsStatus ~= nil then self.txtSettingsStatus:setText(g_i18n:getText("ags_settings_host_only")) end
        self:refreshSettings()
        return
    end
    local c = getConfig()
    if c == nil or self.optWearRate == nil then return end
    c.wearRateMultiplier = WEAR_RATE_VALUES[self.optWearRate.state] or 1.0
    if self.txtSettingsStatus ~= nil then self.txtSettingsStatus:setText(g_i18n:getText("ags_settings_session_only")) end
end

local function formatPercent(value)
    if type(value) ~= "number" then return "-" end
    return string.format("%.1f %%", value):gsub("%.", ",")
end

local function formatAmount(value)
    if type(value) ~= "number" then return "-" end
    return string.format("%.3f", value):gsub("%.", ",")
end

local function getControlledVehicle()
    local localPlayer = g_localPlayer
    if localPlayer ~= nil and type(localPlayer.getCurrentVehicle) == "function" then
        local ok, vehicle = pcall(localPlayer.getCurrentVehicle, localPlayer)
        if ok and vehicle ~= nil then return vehicle, "g_localPlayer:getCurrentVehicle" end
    end
    local mission = g_currentMission
    if mission ~= nil then
        if mission.controlledVehicle ~= nil then return mission.controlledVehicle, "mission.controlledVehicle" end
        local player = mission.player
        if player ~= nil then
            if player.currentVehicle ~= nil then return player.currentVehicle, "mission.player.currentVehicle" end
            if type(player.getCurrentVehicle) == "function" then
                local ok, vehicle = pcall(player.getCurrentVehicle, player)
                if ok and vehicle ~= nil then return vehicle, "mission.player:getCurrentVehicle" end
            end
        end
    end
    return nil, "none"
end

local function getAttachedImplements(vehicle)
    if vehicle == nil then return {} end
    if type(vehicle.getAttachedImplements) == "function" then
        local ok, implements = pcall(vehicle.getAttachedImplements, vehicle)
        if ok and type(implements) == "table" then return implements end
    end
    if type(vehicle.attachedImplements) == "table" then return vehicle.attachedImplements end
    return {}
end

local function findAgriSystemsSprayer(vehicle, visited, depth)
    if vehicle == nil or depth > 8 or visited[vehicle] then return nil, nil end
    visited[vehicle] = true
    local spec = vehicle[Page.SPRAYER_SPEC_TABLE]
    local attachments = getAttachedImplements(vehicle)
    if not Page._diagnosedVehicles[vehicle] then
        Page._diagnosedVehicles[vehicle] = true
        local attachmentCount = 0
        for _ in pairs(attachments) do attachmentCount = attachmentCount + 1 end
        Logging.info(string.format(
            "[AgriSystems Spray & Hygiene][DIAG] menu scan: vehicle=%s typeName=%s agriSpec=%s nativeSprayerSpec=%s attachments=%d",
            tostring(vehicle.configFileName or vehicle.typeName or "unknown"),
            tostring(vehicle.typeName or "unknown"), tostring(spec ~= nil),
            tostring(vehicle.spec_sprayer ~= nil), attachmentCount
        ))
    end
    if spec ~= nil then return vehicle, spec end
    for _, attachment in pairs(attachments) do
        local implement = attachment ~= nil and (attachment.object or attachment) or nil
        if type(implement) == "table" or type(implement) == "userdata" then
            local foundVehicle, foundSpec = findAgriSystemsSprayer(implement, visited, depth + 1)
            if foundSpec ~= nil then return foundVehicle, foundSpec end
        end
    end
    return nil, nil
end

local function getVehicleName(vehicle)
    if vehicle == nil then return g_i18n:getText("ags_menu_no_vehicle") end
    if type(vehicle.getName) == "function" then
        local ok, name = pcall(vehicle.getName, vehicle)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return vehicle.typeName or g_i18n:getText("ags_menu_unknown_vehicle")
end

function Page:onFrameOpen()
    Page:superClass().onFrameOpen(self)
    self._refreshTimer = 0
    self:refresh()
end

function Page:onFrameClose()
    Page:superClass().onFrameClose(self)
end

function Page:update(dt)
    Page:superClass().update(self, dt)
    self._refreshTimer = (self._refreshTimer or 0) + (dt or 0)
    if self._refreshTimer >= 500 then
        self._refreshTimer = 0
        self:refresh()
    end
end

function Page:refresh()
    self:refreshSettings()
    local controlledVehicle, vehicleSource = getControlledVehicle()
    if not self._loggedInitialVehicleState then
        self._loggedInitialVehicleState = true
        local localPlayer = g_localPlayer
        local isInVehicle = "unavailable"
        if localPlayer ~= nil and type(localPlayer.getIsInVehicle) == "function" then
            local ok, value = pcall(localPlayer.getIsInVehicle, localPlayer)
            if ok then isInVehicle = tostring(value) end
        end
        Logging.info(string.format(
            "[AgriSystems Spray & Hygiene][DIAG] initial vehicle state: localPlayer=%s isInVehicle=%s controlledVehicle=%s source=%s missionControlledVehicle=%s missionPlayer=%s",
            tostring(localPlayer ~= nil), isInVehicle,
            tostring(controlledVehicle ~= nil and (controlledVehicle.configFileName or controlledVehicle.typeName or "unknown") or "none"),
            tostring(vehicleSource), tostring(g_currentMission ~= nil and g_currentMission.controlledVehicle ~= nil),
            tostring(g_currentMission ~= nil and g_currentMission.player ~= nil)
        ))
    end
    local vehicle, spec = findAgriSystemsSprayer(controlledVehicle, {}, 0)
    if self._lastControlledVehicle ~= controlledVehicle then
        self._lastControlledVehicle = controlledVehicle
        self._lastSelectedSprayer = vehicle
        Logging.info(string.format(
            "[AgriSystems Spray & Hygiene][DIAG] controlled vehicle changed: vehicle=%s source=%s sprayer=%s",
            tostring(controlledVehicle ~= nil and (controlledVehicle.configFileName or controlledVehicle.typeName or "unknown") or "none"),
            tostring(vehicleSource), tostring(vehicle ~= nil and (vehicle.configFileName or vehicle.typeName or "unknown") or "none")
        ))
    elseif self._lastSelectedSprayer ~= vehicle then
        self._lastSelectedSprayer = vehicle
        Logging.info(string.format("[AgriSystems Spray & Hygiene][DIAG] selected sprayer changed: vehicle=%s",
            tostring(vehicle ~= nil and (vehicle.configFileName or vehicle.typeName or "unknown") or "none")))
    end
    if spec == nil and controlledVehicle ~= nil and not self._loggedEmptyScan then
        self._loggedEmptyScan = true
        Logging.info(string.format(
            "[AgriSystems Spray & Hygiene][DIAG] no AgriSystems sprayer on currently controlled vehicle: vehicle=%s specKey=%s",
            tostring(controlledVehicle.configFileName or controlledVehicle.typeName or "unknown"), Page.SPRAYER_SPEC_TABLE
        ))
    elseif spec ~= nil then
        self._loggedEmptyScan = false
        if self._lastLoggedFoundSprayer ~= vehicle then
            self._lastLoggedFoundSprayer = vehicle
            Logging.info(string.format("[AgriSystems Spray & Hygiene][DIAG] menu selected current sprayer: vehicle=%s",
                tostring(vehicle.configFileName or vehicle.typeName or "unknown")))
        end
    else
        self._loggedEmptyScan = false
        self._lastLoggedFoundSprayer = nil
    end

    local displayVehicle = vehicle or controlledVehicle
    if self.txtVehicleName ~= nil then self.txtVehicleName:setText(getVehicleName(displayVehicle)) end
    local unavailable = g_i18n:getText("ags_menu_unavailable")
    if spec == nil then
        if self.txtCondition ~= nil then self.txtCondition:setText(unavailable) end
        if self.txtWear ~= nil then self.txtWear:setText(unavailable) end
        if self.txtCalibration ~= nil then self.txtCalibration:setText(unavailable) end
        if self.txtBlockage ~= nil then self.txtBlockage:setText(unavailable) end
        if self.txtResidues ~= nil then self.txtResidues:setText(unavailable) end
        if self.txtStatus ~= nil then self.txtStatus:setText(g_i18n:getText("ags_menu_select_sprayer")) end
        return
    end

    local condition = spec.condition or {}
    local cleaning = spec.cleaning or {}
    if self.txtCondition ~= nil then self.txtCondition:setText(formatPercent(condition.condition)) end
    if self.txtWear ~= nil then self.txtWear:setText(formatPercent(condition.wear)) end
    if self.txtCalibration ~= nil then self.txtCalibration:setText(formatPercent(condition.calibration)) end
    local blockageTotal, blockageCount = 0, 0
    for _, blockage in pairs(condition.nozzleBlockage or {}) do
        if type(blockage) == "number" then
            blockageTotal = blockageTotal + blockage
            blockageCount = blockageCount + 1
        end
    end
    if self.txtBlockage ~= nil then
        self.txtBlockage:setText(blockageCount > 0 and formatPercent(blockageTotal / blockageCount) or g_i18n:getText("ags_menu_no_nozzle_data"))
    end
    local residueTotal = 0
    if AgriSystemsSprayHygiene ~= nil and AgriSystemsSprayHygiene.SprayerCleaning ~= nil then
        residueTotal = AgriSystemsSprayHygiene.SprayerCleaning.getTotalResidue(cleaning)
    end
    if self.txtResidues ~= nil then self.txtResidues:setText(formatAmount(residueTotal)) end
    if self.txtStatus ~= nil then self.txtStatus:setText(g_i18n:getText("ags_menu_status_live_wear")) end
end
