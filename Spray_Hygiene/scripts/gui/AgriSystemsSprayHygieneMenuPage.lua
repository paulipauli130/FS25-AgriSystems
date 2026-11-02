AgriSystemsSprayHygieneMenuPage = AgriSystemsSprayHygieneMenuPage or {}

local Page = AgriSystemsSprayHygieneMenuPage
Page.CLASS_NAME = "AgriSystemsSprayHygieneMenuPage"
Page.MENU_PAGE_NAME = "menuAgriSystemsSprayHygiene"
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
    local vehicle = getControlledVehicle()
    local spec = vehicle ~= nil and vehicle.spec_agriSystemsSprayer or nil

    if self.txtVehicleName ~= nil then
        self.txtVehicleName:setText(getVehicleName(vehicle))
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
