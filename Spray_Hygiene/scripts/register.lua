local modName = g_currentModName
local modDirectory = g_currentModDirectory
local specializationKey = "agriSystemsSprayer"
local specializationName = modName .. "." .. specializationKey

-- SpecializationManager stores the short key. The mod-qualified name is used
-- only when adding the specialization to vehicle types.
if g_specializationManager:getSpecializationByName(specializationKey) == nil then
    local success = g_specializationManager:addSpecialization(
        specializationKey,
        "AgriSystemsSprayer",
        Utils.getFilename("scripts/vehicle/AgriSystemsSprayer.lua", modDirectory),
        nil
    )

    if not success then
        Logging.error("[%s] Failed to register sprayer specialization '%s'", modName, specializationKey)
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
