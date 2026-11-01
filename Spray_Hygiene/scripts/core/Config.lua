AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}

AgriSystemsSprayHygiene.Config = {}

local Config = AgriSystemsSprayHygiene.Config

Config.SCHEMA_VERSION = 1

Config.DEFAULTS = {
    schemaVersion = Config.SCHEMA_VERSION,
    debug = false,
    modules = {
        sprayDrift = false,
        sprayerEngineering = false,
        sprayerCleaning = false,
        fieldContamination = false
    },
    drift = {
        windScale = 1.0,
        maxRisk = 1.0,
        updateIntervalMs = 1000
    },
    engineering = {
        conditionLossPerHectare = 0.02,
        minimumCoverage = 0.5
    },
    cleaning = {
        rinseEffectiveness = 0.5,
        flushEffectiveness = 0.75
    },
    contamination = {
        transferRate = 0.01,
        maximumLoad = 1.0
    }
}

local function isFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function clampNumber(value, minimum, maximum, fallback)
    if not isFiniteNumber(value) then
        return fallback
    end

    return math.max(minimum, math.min(maximum, value))
end

function Config.createDefaults()
    local defaults = Config.DEFAULTS

    return {
        schemaVersion = defaults.schemaVersion,
        debug = defaults.debug,
        modules = {
            sprayDrift = defaults.modules.sprayDrift,
            sprayerEngineering = defaults.modules.sprayerEngineering,
            sprayerCleaning = defaults.modules.sprayerCleaning,
            fieldContamination = defaults.modules.fieldContamination
        },
        drift = {
            windScale = defaults.drift.windScale,
            maxRisk = defaults.drift.maxRisk,
            updateIntervalMs = defaults.drift.updateIntervalMs
        },
        engineering = {
            conditionLossPerHectare = defaults.engineering.conditionLossPerHectare,
            minimumCoverage = defaults.engineering.minimumCoverage
        },
        cleaning = {
            rinseEffectiveness = defaults.cleaning.rinseEffectiveness,
            flushEffectiveness = defaults.cleaning.flushEffectiveness
        },
        contamination = {
            transferRate = defaults.contamination.transferRate,
            maximumLoad = defaults.contamination.maximumLoad
        }
    }
end

function Config.validate(candidate)
    local result = Config.createDefaults()

    if type(candidate) ~= "table" then
        return result
    end

    result.debug = candidate.debug == true

    if type(candidate.modules) == "table" then
        for moduleName, _ in pairs(result.modules) do
            result.modules[moduleName] = candidate.modules[moduleName] == true
        end
    end

    if type(candidate.drift) == "table" then
        result.drift.windScale = clampNumber(candidate.drift.windScale, 0, 5, result.drift.windScale)
        result.drift.maxRisk = clampNumber(candidate.drift.maxRisk, 0, 1, result.drift.maxRisk)
        result.drift.updateIntervalMs = math.floor(clampNumber(candidate.drift.updateIntervalMs, 250, 10000, result.drift.updateIntervalMs))
    end

    if type(candidate.engineering) == "table" then
        result.engineering.conditionLossPerHectare = clampNumber(candidate.engineering.conditionLossPerHectare, 0, 10, result.engineering.conditionLossPerHectare)
        result.engineering.minimumCoverage = clampNumber(candidate.engineering.minimumCoverage, 0, 1, result.engineering.minimumCoverage)
    end

    if type(candidate.cleaning) == "table" then
        result.cleaning.rinseEffectiveness = clampNumber(candidate.cleaning.rinseEffectiveness, 0, 1, result.cleaning.rinseEffectiveness)
        result.cleaning.flushEffectiveness = clampNumber(candidate.cleaning.flushEffectiveness, 0, 1, result.cleaning.flushEffectiveness)
    end

    if type(candidate.contamination) == "table" then
        result.contamination.transferRate = clampNumber(candidate.contamination.transferRate, 0, 1, result.contamination.transferRate)
        result.contamination.maximumLoad = clampNumber(candidate.contamination.maximumLoad, 0, 1, result.contamination.maximumLoad)
    end

    result.schemaVersion = Config.SCHEMA_VERSION
    return result
end
