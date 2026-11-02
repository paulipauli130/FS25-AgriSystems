-- Register AgriSystems on vehicle types before FS25 validates their prerequisites.
-- This replaces the passive modDesc vehicleTypeExtensions route.
local modName = g_currentModName or "FS25_AgriSystems_SprayHygiene"
local specializationName = modName .. ".agriSystemsSprayer"

local registered = g_specializationManager:addSpecialization(
    "agriSystemsSprayer",
    "AgriSystemsSprayer",
    Utils.getFilename("scripts/vehicle/AgriSystemsSprayer.lua", g_currentModDirectory),
    nil
)

if not registered then
    Logging.error("[AgriSystems Spray & Hygiene] Failed to register sprayer specialization '%s'.", specializationName)
end

local function injectIntoVehicleTypes(typeManager)
    if typeManager.typeName ~= "vehicle" then
        return
    end

    local specialization = typeManager.specializationManager:getSpecializationObjectByName(specializationName)
    if specialization == nil then
        Logging.error("[AgriSystems Spray & Hygiene] Specialization '%s' is unavailable during vehicle type validation.", specializationName)
        return
    end

    local added = 0
    local alreadyPresent = 0
    local eligible = 0

    for typeName, typeEntry in pairs(typeManager.types) do
        if SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations) then
            eligible = eligible + 1
            if typeEntry.specializationsByName[specializationName] ~= nil then
                alreadyPresent = alreadyPresent + 1
            elseif typeManager:addSpecialization(typeName, specializationName) then
                added = added + 1
            end
        end
    end

    Logging.info(
        "[AgriSystems Spray & Hygiene][DIAG] vehicle type registration: eligible=%d added=%d alreadyPresent=%d",
        eligible, added, alreadyPresent
    )
end

-- Inject before validation because FS25 removes vehicle types with missing prerequisites.
TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, injectIntoVehicleTypes)
