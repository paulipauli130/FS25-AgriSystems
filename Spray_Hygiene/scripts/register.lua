local modName = g_currentModName
local modDirectory = g_currentModDirectory
local specializationName = modName .. ".agriSystemsSprayer"

if g_specializationManager:getSpecializationByName(specializationName) == nil then
    local success = g_specializationManager:addSpecialization(
        specializationName,
        "AgriSystemsSprayer",
        Utils.getFilename("scripts/vehicle/AgriSystemsSprayer.lua", modDirectory),
        nil
    )

    if not success then
        Logging.error("[%s] Failed to register sprayer specialization '%s'", modName, specializationName)
    end
end

local function injectIntoSprayerTypes(typeManager)
    if typeManager.typeName ~= "vehicle" then
        return
    end

    for typeName, typeEntry in pairs(typeManager:getTypes()) do
        if SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations)
            and typeEntry.specializationsByName[specializationName] == nil
            and AgriSystemsSprayer.prerequisitesPresent(typeEntry.specializations) then
            typeManager:addSpecialization(typeName, specializationName)
        end
    end
end

-- Inject before TypeManager's queued validation tasks execute.
if not AgriSystemsSprayHygiene.registrationHookInstalled then
    TypeManager.validateTypes = Utils.appendedFunction(
        TypeManager.validateTypes,
        injectIntoSprayerTypes
    )
    AgriSystemsSprayHygiene.registrationHookInstalled = true
end
