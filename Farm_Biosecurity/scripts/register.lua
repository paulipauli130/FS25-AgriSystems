local modName=g_currentModName
local modDirectory=g_currentModDirectory
local specializationName=modName..".agriSystemsHusbandry"

if g_specializationManager:getSpecializationByName(specializationName)==nil then
 local success=g_specializationManager:addSpecialization(
  "agriSystemsHusbandry","AgriSystemsHusbandry",
  Utils.getFilename("scripts/placeable/AgriSystemsHusbandry.lua",modDirectory),nil
 )
 if not success then Logging.error("[%s] Failed to register husbandry specialization",modName) end
end

local function injectIntoHusbandryTypes(typeManager)
 if typeManager.typeName~="placeable" then return end
 for typeName,typeEntry in pairs(typeManager:getTypes()) do
  if SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals,typeEntry.specializations)
   and typeEntry.specializationsByName[specializationName]==nil
   and AgriSystemsHusbandry.prerequisitesPresent(typeEntry.specializations) then
   typeManager:addSpecialization(typeName,specializationName)
  end
 end
end

if not AgriSystemsFarmBiosecurity.registrationHookInstalled then
 TypeManager.validateTypes=Utils.appendedFunction(TypeManager.validateTypes,injectIntoHusbandryTypes)
 AgriSystemsFarmBiosecurity.registrationHookInstalled=true
end
