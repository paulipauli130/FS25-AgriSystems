local modName = g_currentModName
local modDirectory = g_currentModDirectory
local specializationKey = "agriSystemsHusbandry"
local specializationName = modName .. "." .. specializationKey

-- Placeable specializations belong to the dedicated placeable manager.
-- As with vehicle specializations, the manager stores the short key while
-- placeable types use the mod-qualified name.
if g_placeableSpecializationManager:getSpecializationByName(specializationKey) == nil then
    local success = g_placeableSpecializationManager:addSpecialization(
        specializationKey,
        "AgriSystemsHusbandry",
        Utils.getFilename("scripts/placeable/AgriSystemsHusbandry.lua", modDirectory),
        nil
    )

    if not success then
        Logging.error("[%s] Failed to register husbandry specialization '%s'", modName, specializationKey)
    end
end

local function injectIntoHusbandryTypes(typeManager)
    if typeManager.typeName ~= "placeable" then
        return
    end

    for typeName, typeEntry in pairs(typeManager:getTypes()) do
        if SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, typeEntry.specializations)
            and typeEntry.specializationsByName[specializationName] == nil
            and AgriSystemsHusbandry.prerequisitesPresent(typeEntry.specializations) then
            typeManager:addSpecialization(typeName, specializationName)
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
