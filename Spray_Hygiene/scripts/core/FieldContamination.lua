AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}
AgriSystemsSprayHygiene.FieldContamination = {}

local Contamination = AgriSystemsSprayHygiene.FieldContamination
local DEFAULT_MAX_LOAD = 1
local MAX_FARMLAND_RECORDS = 256

local function clamp(value, minimum, maximum, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return math.max(minimum, math.min(maximum, value))
end

local function normalizeFarmlandId(farmlandId)
    if type(farmlandId) ~= "number" or farmlandId ~= farmlandId
        or farmlandId == math.huge or farmlandId == -math.huge then
        return nil
    end

    local normalized = math.floor(farmlandId)
    if normalized <= 0 or normalized ~= farmlandId then
        return nil
    end
    return normalized
end

local function copyLoads(source, maximumLoad)
    local result = {}
    if type(source) ~= "table" then
        return result
    end

    for contaminationClass, amount in pairs(source) do
        if type(contaminationClass) == "string" and contaminationClass ~= "" then
            result[contaminationClass] = clamp(amount, 0, maximumLoad, 0)
        end
    end
    return result
end

function Contamination.createState()
    return {
        schemaVersion = 1,
        farmlands = {}
    }
end

function Contamination.validateState(candidate, maximumLoad)
    local state = Contamination.createState()
    local limit = clamp(maximumLoad, 0, 1, DEFAULT_MAX_LOAD)

    if type(candidate) ~= "table" or type(candidate.farmlands) ~= "table" then
        return state
    end

    local recordCount = 0
    for farmlandId, record in pairs(candidate.farmlands) do
        local normalizedId = normalizeFarmlandId(tonumber(farmlandId))
        if normalizedId ~= nil and type(record) == "table"
            and recordCount < MAX_FARMLAND_RECORDS then
            state.farmlands[normalizedId] = {
                loads = copyLoads(record.loads, limit)
            }
            recordCount = recordCount + 1
        end
    end

    return state
end

function Contamination.addLoad(state, farmlandId, contaminationClass, amount, maximumLoad)
    local result = Contamination.validateState(state, maximumLoad)
    local id = normalizeFarmlandId(farmlandId)
    if id == nil or type(contaminationClass) ~= "string" or contaminationClass == "" then
        return result
    end

    local record = result.farmlands[id]
    if record == nil then
        local count = 0
        for _ in pairs(result.farmlands) do
            count = count + 1
        end
        if count >= MAX_FARMLAND_RECORDS then
            return result
        end
        record = {loads = {}}
        result.farmlands[id] = record
    end

    local limit = clamp(maximumLoad, 0, 1, DEFAULT_MAX_LOAD)
    local addition = clamp(amount, 0, limit, 0)
    record.loads[contaminationClass] = math.min(
        limit,
        (record.loads[contaminationClass] or 0) + addition
    )
    return result
end

-- equipmentLoad and contactFactor are normalized 0..1 gameplay values.
-- The caller must obtain a validated farmland ID and invoke this only after
-- a server-confirmed machinery/field contact event.
function Contamination.transferToField(state, farmlandId, contaminationClass,
    equipmentLoad, transferRate, contactFactor, maximumLoad)
    local load = clamp(equipmentLoad, 0, 1, 0)
    local rate = clamp(transferRate, 0, 1, 0)
    local contact = clamp(contactFactor, 0, 1, 0)
    local transferred = load * rate * contact

    return Contamination.addLoad(
        state,
        farmlandId,
        contaminationClass,
        transferred,
        maximumLoad
    ), transferred
end

function Contamination.washField(state, farmlandId, reduction, maximumLoad)
    local result = Contamination.validateState(state, maximumLoad)
    local id = normalizeFarmlandId(farmlandId)
    if id == nil or result.farmlands[id] == nil then
        return result
    end

    local factor = clamp(reduction, 0, 1, 0)
    local loads = result.farmlands[id].loads
    for contaminationClass, amount in pairs(loads) do
        local remaining = amount * (1 - factor)
        loads[contaminationClass] = remaining < 0.0001 and 0 or remaining
    end

    return result
end

function Contamination.getLoad(state, farmlandId, contaminationClass, maximumLoad)
    local result = Contamination.validateState(state, maximumLoad)
    local id = normalizeFarmlandId(farmlandId)
    if id == nil or type(contaminationClass) ~= "string" then
        return 0
    end

    local record = result.farmlands[id]
    return record ~= nil and (record.loads[contaminationClass] or 0) or 0
end

function Contamination.getTotalLoad(state, farmlandId, maximumLoad)
    local result = Contamination.validateState(state, maximumLoad)
    local id = normalizeFarmlandId(farmlandId)
    if id == nil or result.farmlands[id] == nil then
        return 0
    end

    local total = 0
    for _, amount in pairs(result.farmlands[id].loads) do
        total = total + amount
    end
    return total
end

function Contamination.getFarmlandCount(state, maximumLoad)
    local result = Contamination.validateState(state, maximumLoad)
    local count = 0
    for _ in pairs(result.farmlands) do
        count = count + 1
    end
    return count
end
