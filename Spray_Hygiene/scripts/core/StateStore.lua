AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}
AgriSystemsSprayHygiene.StateStore = {}

local Store = AgriSystemsSprayHygiene.StateStore

Store.SCHEMA_VERSION = 1
Store.MAX_VEHICLES = 512

local function isValidKey(value)
    return type(value) == "string" and value ~= "" and string.len(value) <= 128
end

local function countEntries(values)
    local count = 0
    for _ in pairs(values) do count = count + 1 end
    return count
end

local function copyTable(source)
    local result = {}
    if type(source) == "table" then
        for key, value in pairs(source) do
            if type(value) == "table" then
                result[key] = copyTable(value)
            elseif type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
                result[key] = value
            end
        end
    end
    return result
end

function Store.createState()
    return {
        schemaVersion = Store.SCHEMA_VERSION,
        vehicles = {},
        fieldContamination = AgriSystemsSprayHygiene.FieldContamination.createState()
    }
end

function Store.validateState(candidate, maximumFieldLoad)
    local state = Store.createState()
    if type(candidate) ~= "table" then return state end

    if type(candidate.vehicles) == "table" then
        for vehicleKey, record in pairs(candidate.vehicles) do
            if isValidKey(vehicleKey) and type(record) == "table"
                and countEntries(state.vehicles) < Store.MAX_VEHICLES then
                state.vehicles[vehicleKey] = {
                    condition = AgriSystemsSprayHygiene.SprayerCondition.validateState(record.condition),
                    cleaning = AgriSystemsSprayHygiene.SprayerCleaning.validateState(record.cleaning)
                }
            end
        end
    end

    state.fieldContamination = AgriSystemsSprayHygiene.FieldContamination.validateState(
        candidate.fieldContamination, maximumFieldLoad
    )
    return state
end

function Store.new(isServer, maximumFieldLoad)
    return setmetatable({
        isServer = isServer == true,
        maximumFieldLoad = maximumFieldLoad or 1,
        state = Store.createState(),
        dirty = false
    }, {__index = Store})
end

function Store:load(serializedState)
    if not self.isServer then return false end
    self.state = Store.validateState(serializedState, self.maximumFieldLoad)
    self.dirty = false
    return true
end

function Store:getVehicleState(vehicleKey)
    if not isValidKey(vehicleKey) then return nil end
    local record = self.state.vehicles[vehicleKey]
    return record ~= nil and copyTable(record) or nil
end

function Store:ensureVehicleState(vehicleKey)
    if not self.isServer or not isValidKey(vehicleKey) then return nil end
    local record = self.state.vehicles[vehicleKey]
    if record == nil then
        if countEntries(self.state.vehicles) >= Store.MAX_VEHICLES then return nil end
        record = {
            condition = AgriSystemsSprayHygiene.SprayerCondition.createState(),
            cleaning = AgriSystemsSprayHygiene.SprayerCleaning.createState()
        }
        self.state.vehicles[vehicleKey] = record
        self.dirty = true
    end
    return copyTable(record)
end

function Store:setVehicleState(vehicleKey, conditionState, cleaningState)
    if not self.isServer or not isValidKey(vehicleKey) then return false end
    if self.state.vehicles[vehicleKey] == nil
        and countEntries(self.state.vehicles) >= Store.MAX_VEHICLES then return false end

    self.state.vehicles[vehicleKey] = {
        condition = AgriSystemsSprayHygiene.SprayerCondition.validateState(conditionState),
        cleaning = AgriSystemsSprayHygiene.SprayerCleaning.validateState(cleaningState)
    }
    self.dirty = true
    return true
end

function Store:removeVehicleState(vehicleKey)
    if not self.isServer or not isValidKey(vehicleKey) then return false end
    if self.state.vehicles[vehicleKey] == nil then return false end
    self.state.vehicles[vehicleKey] = nil
    self.dirty = true
    return true
end

function Store:setFieldContamination(fieldState)
    if not self.isServer then return false end
    self.state.fieldContamination = AgriSystemsSprayHygiene.FieldContamination.validateState(
        fieldState, self.maximumFieldLoad
    )
    self.dirty = true
    return true
end

function Store:exportState()
    return copyTable(self.state)
end

function Store:isDirty()
    return self.dirty
end

function Store:markSaved()
    self.dirty = false
end
