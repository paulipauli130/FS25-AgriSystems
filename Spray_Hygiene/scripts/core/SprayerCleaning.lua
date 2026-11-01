AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}
AgriSystemsSprayHygiene.SprayerCleaning = {}

local Cleaning = AgriSystemsSprayHygiene.SprayerCleaning
local COMPARTMENTS = {"tank", "lines", "filters"}

local function clamp(value, minimum, maximum, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end

    return math.max(minimum, math.min(maximum, value))
end

local function copyResidues(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end

    for productClass, amount in pairs(source) do
        if type(productClass) == "string" and productClass ~= "" then
            result[productClass] = clamp(amount, 0, 1, 0)
        end
    end

    return result
end

function Cleaning.createState()
    return {
        residues = {
            tank = {},
            lines = {},
            filters = {}
        }
    }
end

function Cleaning.validateState(candidate)
    local state = Cleaning.createState()
    if type(candidate) ~= "table" or type(candidate.residues) ~= "table" then
        return state
    end

    for _, compartment in ipairs(COMPARTMENTS) do
        state.residues[compartment] = copyResidues(candidate.residues[compartment])
    end

    return state
end

function Cleaning.addResidue(state, compartment, productClass, amount)
    local result = Cleaning.validateState(state)
    if result.residues[compartment] == nil or type(productClass) ~= "string" or productClass == "" then
        return result
    end

    local addition = clamp(amount, 0, 1, 0)
    local previous = result.residues[compartment][productClass] or 0
    result.residues[compartment][productClass] = math.min(1, previous + addition)
    return result
end

function Cleaning.cleanCompartment(state, compartment, effectiveness)
    local result = Cleaning.validateState(state)
    local residues = result.residues[compartment]
    if residues == nil then
        return result
    end

    local factor = clamp(effectiveness, 0, 1, 0)
    for productClass, amount in pairs(residues) do
        local remaining = amount * (1 - factor)
        residues[productClass] = remaining < 0.0001 and 0 or remaining
    end

    return result
end

function Cleaning.getCarryOver(state, targetClass, compatibility)
    local result = Cleaning.validateState(state)
    if type(targetClass) ~= "string" or type(compatibility) ~= "table" then
        return 0
    end

    local total = 0
    for _, compartment in ipairs(COMPARTMENTS) do
        for sourceClass, residue in pairs(result.residues[compartment]) do
            local sourceRules = compatibility[sourceClass]
            local coefficient = type(sourceRules) == "table" and sourceRules[targetClass] or nil
            total = total + residue * clamp(coefficient, 0, 1, 0)
        end
    end

    return math.min(1, total)
end

function Cleaning.getTotalResidue(state)
    local result = Cleaning.validateState(state)
    local total = 0

    for _, compartment in ipairs(COMPARTMENTS) do
        for _, amount in pairs(result.residues[compartment]) do
            total = total + amount
        end
    end

    return total
end
