AgriSystemsSprayHygieneMenuPage = AgriSystemsSprayHygieneMenuPage or {}

local Page = AgriSystemsSprayHygieneMenuPage
Page.CLASS_NAME = "AgriSystemsSprayHygieneMenuPage"
Page.MENU_PAGE_NAME = "menuAgriSystemsSprayHygiene"
Page.SPRAYER_SPEC_TABLE = "spec_" .. (g_currentModName or "FS25_AgriSystems_SprayHygiene") .. ".agriSystemsSprayer"
Page._diagnosedVehicles = setmetatable({}, {__mode = "k"})
Page_mt = Class(Page, TabbedMenuFrameElement)

function Page.new()
    local self = Page:superClass().new(nil, Page_mt)
    self.name = Page.MENU_PAGE_NAME
    self.btnBack = {
        inputAction = InputAction.MENU_BACK
    }
    self:setMenuButtonInfo({self.btnBack})
    return self
end

function Page:initialize()
    Page:superClass().initialize(self)
    self:refresh()
end

local function formatPercent(value)
    if type(value) ~= "number" then
        return "-"
    end
    return string.format("%.1f %%", value):gsub("%.", ",")
end

local function formatAmount(value)
    if type(value) ~= "number" then
        return "-"
    end
    return string.format("%.3f", value):gsub("%.", ",")
end

local function getControlledVehicle()
    local mission = g_currentMission
    if mission == nil then
        return nil
    end

    if mission.controlledVehicle ~= nil then
        return mission.controlledVehicle
    end

    local player = mission.player
    if player ~= nil and type(player.getCurrentVehicle) == "function" then
        local ok, vehicle = pcall(player.getCurrentVehicle, player)
        if ok then
            return vehicle
        end
    end

    return nil
end

-- Search the controlled vehicle and its attached implements. A player normally
-- controls the tractor, while the sprayer is one or more attachment levels below.
local function getAttachedImplements(vehicle)
    if vehicle == nil then
        return {}
    end

    if type(vehicle.getAttachedImplements) == "function" then
        local ok, implements = pcall(vehicle.getAttachedImplements, vehicle)
        if ok and type(implements) == "table" then
            return implements
        end
    end

    if type(vehicle.attachedImplements) == "table" then
        return vehicle.attachedImplements
    end

    return {}
end

local function findAgriSystemsSprayer(vehicle, visited, depth)
    if vehicle == nil or depth > 8 or visited[vehicle] then
        return nil, nil
    end
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
            tostring(vehicle.typeName or "unknown"),
            tostring(spec ~= nil),
            tostring(vehicle.spec_sprayer ~= nil),
            attachmentCount
        ))
    end
    if spec ~= nil then
        return vehicle, spec
    end

    for _, attachment in pairs(attachments) do
        local implement = attachment ~= nil and (attachment.object or attachment) or nil
        if type(implement) == "table" or type(implement) == "userdata" then
            local foundVehicle, foundSpec = findAgriSystemsSprayer(implement, visited, depth + 1)
            if foundSpec ~= nil then
                return foundVehicle, foundSpec
            end
        end
    end

    return nil, nil
end

-- Some FS25 menu states do not expose the currently controlled vehicle through
-- mission.controlledVehicle (and some implement chains are not traversable from
-- the tractor). Fall back to the mission vehicle registry so an attached or
-- independently controlled sprayer can still be found.
local function findMissionSprayer(mission, visited)
    if mission == nil then
        return nil, nil
    end

    local vehicleCollections = {
        mission.vehicles,
        mission.vehicleSystem ~= nil and mission.vehicleSystem.vehicles or nil
    }
    for _, vehicles in pairs(vehicleCollections) do
        if type(vehicles) == "table" then
            for _, vehicle in pairs(vehicles) do
                local foundVehicle, foundSpec = findAgriSystemsSprayer(vehicle, visited, 0)
                if foundSpec ~= nil then
                    return foundVehicle, foundSpec
                end
            end
        end
    end

    return nil, nil
end

local function getVehicleName(vehicle)
    if vehicle == nil then
        return g_i18n:getText("ags_menu_no_vehicle")
    end

    if type(vehicle.getName) == "function" then
        local ok, name = pcall(vehicle.getName, vehicle)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
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
    local mission = g_currentMission
    local controlledVehicle = getControlledVehicle()
    local visited = {}
    local vehicle, spec = findAgriSystemsSprayer(controlledVehicle, visited, 0)
    local discoverySource = "controlledVehicle"

    if spec == nil then
        vehicle, spec = findMissionSprayer(mission, visited)
        discoverySource = "missionVehicleRegistry"
    end

    if spec == nil and not self._loggedEmptyScan then
        self._loggedEmptyScan = true
        local vehicleCount = 0
        if mission ~= nil and type(mission.vehicles) == "table" then
            for _ in pairs(mission.vehicles) do vehicleCount = vehicleCount + 1 end
        end
        Logging.info(string.format(
            "[AgriSystems Spray & Hygiene][DIAG] menu scan found no sprayer: controlledVehicle=%s missionVehicles=%d specKey=%s",
            tostring(controlledVehicle ~= nil), vehicleCount, Page.SPRAYER_SPEC_TABLE
        ))
    elseif spec ~= nil then
        self._loggedEmptyScan = false
        if not self._loggedFoundSprayer then
            self._loggedFoundSprayer = true
            Logging.info(string.format(
                "[AgriSystems Spray & Hygiene][DIAG] menu scan found sprayer: vehicle=%s source=%s",
                tostring(vehicle.configFileName or vehicle.typeName or "unknown"), discoverySource
            ))
        end
    end

    local displayVehicle = vehicle or controlledVehicle

    if self.txtVehicleName ~= nil then
        self.txtVehicleName:setText(getVehicleName(displayVehicle))
    end

    local unavailable = g_i18n:getText("ags_menu_unavailable")
    if spec == nil then
        if self.txtCondition ~= nil then self.txtCondition:setText(unavailable) end
        if self.txtWear ~= nil then self.txtWear:setText(unavailable) end
        if self.txtCalibration ~= nil then self.txtCalibration:setText(unavailable) end
        if self.txtBlockage ~= nil then self.txtBlockage:setText(unavailable) end
        if self.txtResidues ~= nil then self.txtResidues:setText(unavailable) end
        if self.txtStatus ~= nil then
            self.txtStatus:setText(g_i18n:getText("ags_menu_select_sprayer"))
        end
        return
    end

    local condition = spec.condition or {}
    local cleaning = spec.cleaning or {}

    if self.txtCondition ~= nil then
        self.txtCondition:setText(formatPercent(condition.condition))
    end
    if self.txtWear ~= nil then
        self.txtWear:setText(formatPercent(condition.wear))
    end
    if self.txtCalibration ~= nil then
        self.txtCalibration:setText(formatPercent(condition.calibration))
    end

    local blockageTotal = 0
    local blockageCount = 0
    for _, blockage in pairs(condition.nozzleBlockage or {}) do
        if type(blockage) == "number" then
            blockageTotal = blockageTotal + blockage
            blockageCount = blockageCount + 1
        end
    end
    if self.txtBlockage ~= nil then
        if blockageCount > 0 then
            self.txtBlockage:setText(formatPercent(blockageTotal / blockageCount))
        else
            self.txtBlockage:setText(g_i18n:getText("ags_menu_no_nozzle_data"))
        end
    end

    local residueTotal = 0
    if AgriSystemsSprayHygiene ~= nil
        and AgriSystemsSprayHygiene.SprayerCleaning ~= nil then
        residueTotal = AgriSystemsSprayHygiene.SprayerCleaning.getTotalResidue(cleaning)
    end
    if self.txtResidues ~= nil then
        self.txtResidues:setText(formatAmount(residueTotal))
    end

    if self.txtStatus ~= nil then
        self.txtStatus:setText(g_i18n:getText("ags_menu_status_model_only"))
    end
end
