AgriSystemsSprayHygiene = AgriSystemsSprayHygiene or {}
AgriSystemsSprayHygiene.SprayDrift = {}

local Drift = AgriSystemsSprayHygiene.SprayDrift

local function clamp(value, minimum, maximum, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return math.max(minimum, math.min(maximum, value))
end

-- Gameplay risk estimator only; not a calibrated physical deposition simulator.
-- Direction is returned only from the explicit wind-to vector supplied by the caller.
-- Do not pass WindUpdater direction components until their sign convention is verified in-game.
function Drift.evaluate(parameters)
    parameters = type(parameters) == "table" and parameters or {}

    local windSpeed = clamp(parameters.windSpeedMps, 0, 60, 0)
    local dropletSize = clamp(parameters.dropletSizeMicron, 50, 2000, 400)
    local boomHeight = clamp(parameters.boomHeightM, 0.1, 5, 0.5)
    local windScale = clamp(parameters.windScale, 0, 5, 1)
    local maxRisk = clamp(parameters.maxRisk, 0, 1, 1)

    local windFactor = clamp(windSpeed / 8, 0, 1, 0)
    local dropletFactor = clamp((600 - dropletSize) / 500, 0, 1, 0)
    local heightFactor = clamp((boomHeight - 0.3) / 1.7, 0, 1, 0)

    local rawRisk = windFactor * dropletFactor * heightFactor * windScale
    local risk = math.min(maxRisk, clamp(rawRisk, 0, 1, 0))

    local directionX = clamp(parameters.windToDirectionX, -1, 1, 0)
    local directionZ = clamp(parameters.windToDirectionZ, -1, 1, 0)
    local directionLength = math.sqrt(directionX * directionX + directionZ * directionZ)

    if directionLength > 0.000001 then
        directionX = directionX / directionLength
        directionZ = directionZ / directionLength
    else
        directionX = 0
        directionZ = 0
    end

    return {
        risk = risk,
        windFactor = windFactor,
        dropletFactor = dropletFactor,
        heightFactor = heightFactor,
        transportDirectionX = directionX,
        transportDirectionZ = directionZ
    }
end

function Drift.getRiskBand(risk)
    local value = clamp(risk, 0, 1, 0)
    if value < 0.25 then
        return "low"
    elseif value < 0.6 then
        return "moderate"
    end
    return "high"
end
