AgriSystemsHusbandry = {}
local Spec=AgriSystemsHusbandry
local ROOT="agriSystemsBiosecurity"
local MAX_GROUPS=512
local MAX_SURFACES=128

local function getStore()
 local mod=AgriSystemsFarmBiosecurity
 if mod.STATE_STORE==nil and g_server~=nil and mod.StateStore~=nil then
  local config=mod.CONFIG or mod.Config.validate(nil)
  mod.STATE_STORE=mod.StateStore.new(true,config.disease.maximumGroups)
 end
 return mod.STATE_STORE
end

function Spec.prerequisitesPresent(specializations)
 return SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals,specializations)
end

function Spec.registerSavegameXMLPaths(schema,basePath)
 local base=basePath.."."..ROOT
 schema:register(XMLValueType.INT,base.."#schemaVersion","AgriSystems Biosecurity schema")
 schema:register(XMLValueType.STRING,base..".group(?)#id","Mod-owned animal cohort ID")
 schema:register(XMLValueType.STRING,base..".group(?)#status","Disease progression state")
 schema:register(XMLValueType.STRING,base..".group(?)#diseaseId","Disease profile ID")
 schema:register(XMLValueType.FLOAT,base..".group(?)#elapsedHours","Disease progression hours")
 schema:register(XMLValueType.FLOAT,base..".group(?)#exposureLoad","Accumulated exposure load")
 schema:register(XMLValueType.FLOAT,base..".group(?)#severity","Disease severity")
 schema:register(XMLValueType.BOOL,base..".group(?)#quarantineActive","Quarantine active")
 schema:register(XMLValueType.FLOAT,base..".group(?)#quarantineStart","Quarantine start time")
 schema:register(XMLValueType.FLOAT,base..".group(?)#quarantineDuration","Quarantine duration")
 schema:register(XMLValueType.BOOL,base..".group(?)#hygieneCompliant","Quarantine hygiene compliance")
 schema:register(XMLValueType.BOOL,base..".group(?)#releaseRequested","Quarantine release requested")
 schema:register(XMLValueType.STRING,base..".surface(?)#id","Hygiene surface ID")
 schema:register(XMLValueType.FLOAT,base..".surface(?)#dirt","Surface dirt load")
 schema:register(XMLValueType.FLOAT,base..".surface(?)#contamination","Surface contamination")
 schema:register(XMLValueType.FLOAT,base..".surface(?)#disinfectantUntil","Disinfection contact-time end")
 schema:register(XMLValueType.FLOAT,base..".surface(?)#pendingEffectiveness","Pending disinfection effectiveness")
end

function Spec.registerEventListeners(placeableType)
 SpecializationUtil.registerEventListener(placeableType,"onLoad",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onDelete",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onHusbandryAnimalsUpdate",Spec)
end

local function makeCohortId(subType)
 if type(subType)~="table" or type(subType.type)~="string" or subType.type=="" then return nil end
 if type(subType.subTypeId)~="number" or subType.subTypeId<1 then return nil end
 return string.format("%s:%d",subType.type,math.floor(subType.subTypeId))
end

function Spec:onLoad(savegame)
 self.spec_agriSystemsBiosecurity={husbandryId=self:getUniqueId(),loaded=false}
 local spec=self.spec_agriSystemsBiosecurity
 if not self.isServer then return end
 if type(spec.husbandryId)~="string" or spec.husbandryId=="" then
  Logging.warning("[AgriSystems Farm Biosecurity] Placeable has no persistent uniqueId; this husbandry is inactive")
  return
 end
 local store=getStore()
 if store==nil then return end
 store:ensureHusbandry(spec.husbandryId)
 if savegame==nil or savegame.resetVehicles then return end

 local xmlFile=savegame.xmlFile
 local base=savegame.key.."."..ROOT
 if not xmlFile:hasProperty(base) then return end
 local schemaVersion=xmlFile:getValue(base.."#schemaVersion",1)
 if schemaVersion~=1 then
  Logging.xmlWarning(xmlFile,"Unsupported AgriSystems Biosecurity schema %s; defaults used",tostring(schemaVersion))
  return
 end

 local data={groups={},hygiene={surfaces={}}}
 local groupCount=0
 for _,key in xmlFile:iterator(base..".group") do
  groupCount=groupCount+1
  if groupCount>MAX_GROUPS then break end
  local id=xmlFile:getValue(key.."#id")
  if type(id)=="string" and id~="" then
   local disease={
    groupId=id,status=xmlFile:getValue(key.."#status","susceptible"),
    diseaseId=xmlFile:getValue(key.."#diseaseId"),
    elapsedHours=xmlFile:getValue(key.."#elapsedHours",0),
    exposureLoad=xmlFile:getValue(key.."#exposureLoad",0),
    severity=xmlFile:getValue(key.."#severity",0)
   }
   local quarantine=nil
   if xmlFile:getValue(key.."#quarantineActive",false) then
    quarantine={
     groupId=id,active=true,startedAtHours=xmlFile:getValue(key.."#quarantineStart",0),
     durationHours=xmlFile:getValue(key.."#quarantineDuration",48),
     hygieneCompliant=xmlFile:getValue(key.."#hygieneCompliant",false),
     releaseRequested=xmlFile:getValue(key.."#releaseRequested",false),
     reason="savegame"
    }
   end
   data.groups[id]={disease=disease,quarantine=quarantine}
  end
 end

 local surfaceCount=0
 for _,key in xmlFile:iterator(base..".surface") do
  surfaceCount=surfaceCount+1
  if surfaceCount>MAX_SURFACES then break end
  local id=xmlFile:getValue(key.."#id")
  if type(id)=="string" and id~="" then
   data.hygiene.surfaces[id]={
    dirt=xmlFile:getValue(key.."#dirt",0),
    contamination=xmlFile:getValue(key.."#contamination",0),
    disinfectantUntilHours=xmlFile:getValue(key.."#disinfectantUntil",0),
    pendingDisinfectantEffectiveness=xmlFile:getValue(key.."#pendingEffectiveness",0)
   }
  end
 end
 store:loadHusbandryState(spec.husbandryId,data)
 spec.loaded=true
end

-- Cohort identity is stable within a husbandry: animal type + configured subtype ID.
-- Engine cluster IDs are deliberately not persisted; clusters of the same subtype
-- are aggregated into one logical cohort so split/merge cannot lose its state.
function Spec:onHusbandryAnimalsUpdate(clusters)
 if not self.isServer then return end
 local spec=self.spec_agriSystemsBiosecurity
 if spec==nil or spec.husbandryId==nil then return end
 local store=getStore()
 if store==nil then return end
 local cohorts={}
 for _,cluster in ipairs(clusters or {}) do
  local subTypeIndex=cluster:getSubTypeIndex()
  local subType=subTypeIndex~=nil and g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex) or nil
  local cohortId=makeCohortId(subType)
  if cohortId~=nil then
   cohorts[cohortId]=(cohorts[cohortId] or 0)+(cluster.getNumAnimals~=nil and cluster:getNumAnimals() or cluster.numAnimals or 0)
  end
 end

 for cohortId,_ in pairs(cohorts) do
  if store:getGroup(spec.husbandryId,cohortId)==nil then
   local disease=AgriSystemsFarmBiosecurity.DiseaseModel.createGroupState(cohortId)
   local config=AgriSystemsFarmBiosecurity.CONFIG or AgriSystemsFarmBiosecurity.Config.validate(nil)
   local quarantine=AgriSystemsFarmBiosecurity.Quarantine.createState(cohortId,0,config.quarantine.durationHours)
   store:setGroup(spec.husbandryId,cohortId,disease,quarantine)
  end
 end
end

function Spec:saveToXMLFile(xmlFile,key,usedModNames)
 if not self.isServer then return end
 local spec=self.spec_agriSystemsBiosecurity
 if spec==nil or spec.husbandryId==nil then return end
 local store=getStore()
 local data=store~=nil and store:getHusbandryState(spec.husbandryId) or nil
 if data==nil then return end
 local base=key.."."..ROOT
 xmlFile:setValue(base.."#schemaVersion",1)
 local index=0
 for groupId,record in pairs(data.groups or {}) do
  if index>=MAX_GROUPS then break end
  local g=string.format("%s.group(%d)",base,index)
  local d=record.disease
  xmlFile:setValue(g.."#id",groupId)
  xmlFile:setValue(g.."#status",d.status)
  xmlFile:setValue(g.."#diseaseId",d.diseaseId)
  xmlFile:setValue(g.."#elapsedHours",d.elapsedHours)
  xmlFile:setValue(g.."#exposureLoad",d.exposureLoad)
  xmlFile:setValue(g.."#severity",d.severity)
  local q=record.quarantine
  if q~=nil then
   xmlFile:setValue(g.."#quarantineActive",q.active)
   xmlFile:setValue(g.."#quarantineStart",q.startedAtHours)
   xmlFile:setValue(g.."#quarantineDuration",q.durationHours)
   xmlFile:setValue(g.."#hygieneCompliant",q.hygieneCompliant)
   xmlFile:setValue(g.."#releaseRequested",q.releaseRequested)
  end
  index=index+1
 end

 index=0
 for surfaceId,surface in pairs((data.hygiene and data.hygiene.surfaces) or {}) do
  if index>=MAX_SURFACES then break end
  local s=string.format("%s.surface(%d)",base,index)
  xmlFile:setValue(s.."#id",surfaceId)
  xmlFile:setValue(s.."#dirt",surface.dirt)
  xmlFile:setValue(s.."#contamination",surface.contamination)
  xmlFile:setValue(s.."#disinfectantUntil",surface.disinfectantUntilHours)
  xmlFile:setValue(s.."#pendingEffectiveness",surface.pendingDisinfectantEffectiveness)
  index=index+1
 end
end

function Spec:onDelete()
 local spec=self.spec_agriSystemsBiosecurity
 if spec~=nil and spec.husbandryId~=nil then
  local store=getStore()
  if store~=nil then store:clearClusterBindings() end
 end
end
