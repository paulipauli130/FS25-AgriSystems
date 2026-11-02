local modName = g_currentModName
local modDirectory = g_currentModDirectory
local specializationKey = "agriSystemsHusbandry"

-- Placeable specializations use their dedicated manager. The manager stores
-- the exact key supplied here, which must also be used by placeable types.
if g_placeableSpecializationManager:getSpecializationByName(specializationKey) == nil then
    g_placeableSpecializationManager:addSpecialization(
        specializationKey,
        "AgriSystemsHusbandry",
        Utils.getFilename("scripts/placeable/AgriSystemsHusbandry.lua", modDirectory),
        nil
    )

    if g_placeableSpecializationManager:getSpecializationByName(specializationKey) == nil then
        Logging.error("[%s] Failed to register husbandry specialization '%s'", modName, specializationKey)
    end
end

local function injectIntoHusbandryTypes(typeManager)
    if typeManager.typeName ~= "placeable" then
        return
    end

    for typeName, typeEntry in pairs(typeManager:getTypes()) do
        if SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, typeEntry.specializations)
            and typeEntry.specializationsByName[specializationKey] == nil
            and AgriSystemsHusbandry.prerequisitesPresent(typeEntry.specializations) then
            typeManager:addSpecialization(typeName, specializationKey)
        end
    end
end

-- Inject before TypeManager's queued validation tasks execute.
if not AgriSystemsFarmBiosecurity.registrationHookInstalled then
    TypeManager.validateTypes = Utils.appendedFunction(
        TypeManager.validateTypes,
        injectIntoHusbandryTypes
    )
    AgriSystemsFarmBiosecurity.registrationHookInstalled = true
end
