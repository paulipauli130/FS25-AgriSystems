AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}
AgriSystemsSprayHygiene.SprayerCondition = {}

local Condition = AgriSystemsSprayHygiene.SprayerCondition

local function clamp(value, minimum, maximum, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end

    return math.max(minimum, math.min(maximum, value))
end

local function copyGroups(groups)
    local result = {}
    if type(groups) ~= "table" then
        return result
    end

    for groupId, blockage in pairs(groups) do
        if type(groupId) == "string" or type(groupId) == "number" then
            result[tostring(groupId)] = clamp(blockage, 0, 100, 0)
        end
    end

    return result
end

function Condition.createState()
    return {
        condition = 100,
        wear = 0,
        calibration = 100,
        nozzleBlockage = {}
    }
end

function Condition.validateState(candidate)
    local state = Condition.createState()
    if type(candidate) ~= "table" then
        return state
    end

    state.condition = clamp(candidate.condition, 0, 100, 100)
    state.wear = clamp(candidate.wear, 0, 100, 0)
    state.calibration = clamp(candidate.calibration, 0, 100, 100)
    state.nozzleBlockage = copyGroups(candidate.nozzleBlockage)
    return state
end

-- Called by a future server-side observer after successful native spraying.
-- This model never reads or changes native fill levels or spray usage.
function Condition.applyOperatingTime(state, elapsedMs, wearPerHour, calibrationFactor)
    local result = Condition.validateState(state)
    local elapsedHours = clamp(elapsedMs, 0, 3600000, 0) / 3600000
    local loss = clamp(wearPerHour, 0, 10, 0) * elapsedHours
    local calibrationLoss = clamp(calibrationFactor, 0, 10, 0.5) * loss
    result.condition = math.max(0, result.condition - loss)
    result.wear = math.min(100, result.wear + loss)
    result.calibration = math.max(0, result.calibration - calibrationLoss)
    return result
end

function Condition.applyWork(state, workedAreaHa, lossPerHectare)
    local result = Condition.validateState(state)
    local area = clamp(workedAreaHa, 0, 1000000, 0)
    local loss = clamp(lossPerHectare, 0, 10, 0)
    local degradation = math.min(100, area * loss)

    result.condition = math.max(0, result.condition - degradation)
    result.wear = math.min(100, result.wear + degradation)
    result.calibration = math.max(0, result.calibration - degradation * 0.5)

    return result
end

function Condition.setNozzleBlockage(state, groupId, blockage)
    local result = Condition.validateState(state)
    if groupId == nil then
        return result
    end

    result.nozzleBlockage[tostring(groupId)] = clamp(blockage, 0, 100, 0)
    return result
end

function Condition.cleanNozzleGroup(state, groupId)
    local result = Condition.validateState(state)
    if groupId == nil then
        return result
    end

    result.nozzleBlockage[tostring(groupId)] = 0
    return result
end

function Condition.service(state, restoredCondition, restoredCalibration)
    local result = Condition.validateState(state)
    result.condition = clamp(restoredCondition, result.condition, 100, result.condition)
    result.calibration = clamp(restoredCalibration, result.calibration, 100, result.calibration)
    result.wear = 100 - result.condition
    return result
end

function Condition.getCoverageFactor(state, minimumCoverage)
    local result = Condition.validateState(state)
    local minimum = clamp(minimumCoverage, 0, 1, 0.5)
    local conditionFactor = 0.65 + 0.35 * (result.condition / 100)
    local calibrationFactor = 0.8 + 0.2 * (result.calibration / 100)
    local totalBlockage = 0
    local groupCount = 0

    for _, blockage in pairs(result.nozzleBlockage) do
        totalBlockage = totalBlockage + blockage
        groupCount = groupCount + 1
    end

    local averageBlockage = groupCount > 0 and totalBlockage / groupCount or 0
    local blockageFactor = 1 - (averageBlockage / 100) * 0.5
    local rawFactor = conditionFactor * calibrationFactor * blockageFactor

    return math.max(minimum, math.min(1, rawFactor))
end
