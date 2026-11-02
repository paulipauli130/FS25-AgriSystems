local modName = g_currentModName
local modDirectory = g_currentModDirectory
local specializationKey = "agriSystemsSprayer"

-- The specialization manager stores the exact key supplied here.
if g_specializationManager:getSpecializationByName(specializationKey) == nil then
    g_specializationManager:addSpecialization(
        specializationKey,
        "AgriSystemsSprayer",
        Utils.getFilename("scripts/vehicle/AgriSystemsSprayer.lua", modDirectory),
        nil
    )

    -- Verify registration through the manager instead of relying on a return
    -- value that may differ between game versions.
    if g_specializationManager:getSpecializationByName(specializationKey) == nil then
        Logging.error("[%s] Failed to register sprayer specialization '%s'", modName, specializationKey)
    end
end

local function injectIntoSprayerTypes(typeManager)
    if typeManager.typeName ~= "vehicle" then
        return
    end

    for typeName, typeEntry in pairs(typeManager:getTypes()) do
        if SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations)
            and typeEntry.specializationsByName[specializationKey] == nil
            and AgriSystemsSprayer.prerequisitesPresent(typeEntry.specializations) then
            typeManager:addSpecialization(typeName, specializationKey)
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
