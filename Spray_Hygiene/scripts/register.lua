local modName = g_currentModName
local modDirectory = g_currentModDirectory
local specializationName = modName .. ".agriSystemsSprayer"

if g_specializationManager:getSpecializationByName(specializationName) == nil then
    local success = g_specializationManager:addSpecialization(
        "agriSystemsSprayer",
        "AgriSystemsSprayer",
        Utils.getFilename("scripts/vehicle/AgriSystemsSprayer.lua", modDirectory),
        nil
    )

    if not success then
        Logging.error("[%s] Failed to register sprayer specialization", modName)
    end
end

local function injectIntoSprayerTypes(typeManager)
    if typeManager.typeName ~= "vehicle" then
        return
    end

    for typeName, typeEntry in pairs(typeManager:getTypes()) do
        if SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations)
            and typeEntry.specializationsByName[specializationName] == nil then
            if AgriSystemsSprayer.prerequisitesPresent(typeEntry.specializations) then
                typeManager:addSpecialization(typeName, specializationName)
            end
        end
    end
end

-- Type validation schedules its checks as async tasks. The appended injection
-- runs before those tasks execute and before finalizeTypes registers listeners.
if not AgriSystemsSprayHygiene.registrationHookInstalled then
    TypeManager.validateTypes = Utils.appendedFunction(
        TypeManager.validateTypes,
        injectIntoSprayerTypes
    )
    AgriSystemsSprayHygiene.registrationHookInstalled = true
end
