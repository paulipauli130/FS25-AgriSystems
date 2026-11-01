AgriSystemsHusbandry = {}
local Spec=AgriSystemsHusbandry
local ROOT="agriSystemsHusbandry"
local MAX_GROUPS=512
local MAX_SURFACES=128

local function getStore()
 local mod=AgriSystemsFarmBiosecurity
 if mod.STATE_STORE==nil and mod.StateStore~=nil then
  local config=mod.CONFIG or mod.Config.validate(nil)
  mod.STATE_STORE=mod.StateStore.new(g_server~=nil,config.disease.maximumGroups)
 end
 return mod.STATE_STORE
end

function Spec.prerequisitesPresent(specializations)
 return SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals,specializations)
end

function Spec.registerSavegameXMLPaths(schema,basePath)
 local base=basePath
 schema:setXMLSpecializationType("AgriSystemsHusbandry")
 schema:register(XMLValueType.INT,base.."#schemaVersion","AgriSystems Biosecurity schema")
 schema:register(XMLValueType.FLOAT,base.."#clockHours","Elapsed in-game hours for Biosecurity state")
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
 schema:setXMLSpecializationType()
end

function Spec.registerOverwrittenFunctions(placeableType)
 SpecializationUtil.registerOverwrittenFunction(placeableType,"getNeedHourChanged",Spec.getNeedHourChanged)
end

function Spec:getNeedHourChanged(superFunc)
 return superFunc(self) or true
end

function Spec.registerEventListeners(placeableType)
 SpecializationUtil.registerEventListener(placeableType,"onLoad",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onFinalizePlacement",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onHusbandryAnimalsUpdate",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onHourChanged",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onWriteStream",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onReadStream",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onWriteStream",Spec)
 SpecializationUtil.registerEventListener(placeableType,"onReadStream",Spec)
end

local function makeCohortId(subType)
 if type(subType)~="table" or type(subType.type)~="string" or subType.type=="" then return nil end
 if type(subType.subTypeId)~="number" or subType.subTypeId<1 then return nil end
 return string.format("%s:%d",subType.type,math.floor(subType.subTypeId))
end

function Spec:onLoad(savegame)
 self.spec_agriSystemsBiosecurity={husbandryId=self:getUniqueId(),loaded=false,savegame=savegame,clockHours=0}
 local spec=self.spec_agriSystemsBiosecurity
 if not self.isServer then return end
 if type(spec.husbandryId)~="string" or spec.husbandryId=="" then
  -- PlaceableSystem may assign the persistent uniqueId after the first load callback.
  return
 end
 local store=getStore()
 if store==nil then return end
 store:ensureHusbandry(spec.husbandryId)
 if savegame==nil or savegame.resetVehicles then return end

 local xmlFile=savegame.xmlFile
 local base=savegame.key.."."..ROOT
 spec.clockHours=math.max(0,math.min(100000000,xmlFile:getValue(base.."#clockHours",0)))
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
function Spec:onFinalizePlacement()
 local spec=self.spec_agriSystemsBiosecurity
 if spec~=nil and (spec.husbandryId==nil or spec.husbandryId=="") then
  self:onLoad(spec.savegame)
 end
end

function Spec:onHusbandryAnimalsUpdate(clusters)
 if not self.isServer then return end
 local spec=self.spec_agriSystemsBiosecurity
 if spec~=nil and (spec.husbandryId==nil or spec.husbandryId=="") then
  self:onLoad(spec.savegame)
  spec=self.spec_agriSystemsBiosecurity
 end
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
   local quarantine=AgriSystemsFarmBiosecurity.Quarantine.createState(cohortId,spec.clockHours,config.quarantine.durationHours)
   store:setGroup(spec.husbandryId,cohortId,disease,quarantine)
  end
 end
end

function Spec:onHourChanged(hour)
 if not self.isServer then return end
 local spec=self.spec_agriSystemsBiosecurity
 if spec==nil or spec.husbandryId==nil then return end
 local store=getStore()
 if store==nil then return end
 spec.clockHours=math.min(100000000,(spec.clockHours or 0)+1)
 local data=store:getHusbandryState(spec.husbandryId)
 if data==nil then return end
 for groupId,record in pairs(data.groups or {}) do
  local disease=record.disease
  local quarantine=record.quarantine
  local changed=false
  if disease.status~="susceptible" and disease.status~="recovered" then
   disease=AgriSystemsFarmBiosecurity.DiseaseModel.advance(disease,1)
   changed=true
  end
  if quarantine~=nil and quarantine.active and quarantine.releaseRequested then
   quarantine=AgriSystemsFarmBiosecurity.Quarantine.advance(quarantine,spec.clockHours)
   changed=true
  end
  if changed then store:setGroup(spec.husbandryId,groupId,disease,quarantine) end
 end
end

function Spec:saveToXMLFile(xmlFile,key,usedModNames)
 if not self.isServer then return end
 local spec=self.spec_agriSystemsBiosecurity
 if spec==nil or spec.husbandryId==nil then return end
 local store=getStore()
 local data=store~=nil and store:getHusbandryState(spec.husbandryId) or nil
 if data==nil then return end
 local base=key
 xmlFile:setValue(base.."#schemaVersion",1)
 xmlFile:setValue(base.."#clockHours",spec.clockHours or 0)
 local index=0
 for groupId,record in pairs(data.groups or {}) do
  if index>=MAX_GROUPS then break end
  local g=string.format("%s.group(%d)",base,index)
  local d=record.disease
  xmlFile:setValue(g.."#id",groupId)
  xmlFile:setValue(g.."#status",d.status)
  if d.diseaseId~=nil then xmlFile:setValue(g.."#diseaseId",d.diseaseId) end
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


function Spec:onWriteStream(streamId,connection)
 if not self.isServer then return end
 local spec=self.spec_agriSystemsBiosecurity
 local store=getStore()
 local data=spec~=nil and spec.husbandryId~=nil and store~=nil and store:getHusbandryState(spec.husbandryId) or nil
 streamWriteFloat32(streamId,spec~=nil and spec.clockHours or 0)
 local groupList={}
 for id,record in pairs((data~=nil and data.groups) or {}) do
  if #groupList<MAX_GROUPS then table.insert(groupList,{id=id,record=record}) end
 end
 streamWriteUInt16(streamId,#groupList)
 for _,entry in ipairs(groupList) do
  local d=entry.record.disease
  streamWriteString(streamId,entry.id)
  streamWriteString(streamId,d.status or "susceptible")
  streamWriteString(streamId,d.diseaseId or "")
  streamWriteFloat32(streamId,d.elapsedHours or 0)
  streamWriteFloat32(streamId,d.exposureLoad or 0)
  streamWriteFloat32(streamId,d.severity or 0)
  local q=entry.record.quarantine
  streamWriteBool(streamId,q~=nil)
  if q~=nil then
   streamWriteBool(streamId,q.active)
   streamWriteFloat32(streamId,q.startedAtHours)
   streamWriteFloat32(streamId,q.durationHours)
   streamWriteBool(streamId,q.hygieneCompliant)
   streamWriteBool(streamId,q.releaseRequested)
  end
 end
 local surfaces={}
 for id,surface in pairs((data~=nil and data.hygiene and data.hygiene.surfaces) or {}) do
  if #surfaces<MAX_SURFACES then table.insert(surfaces,{id=id,value=surface}) end
 end
 streamWriteUInt8(streamId,#surfaces)
 for _,entry in ipairs(surfaces) do
  streamWriteString(streamId,entry.id)
  streamWriteFloat32(streamId,entry.value.dirt)
  streamWriteFloat32(streamId,entry.value.contamination)
  streamWriteFloat32(streamId,entry.value.disinfectantUntilHours)
  streamWriteFloat32(streamId,entry.value.pendingDisinfectantEffectiveness)
 end
end

function Spec:onReadStream(streamId,connection)
 if self.isServer then return end
 local spec=self.spec_agriSystemsBiosecurity
 if spec==nil then return end
 local store=getStore()
 local husbandryId=spec.husbandryId
 spec.clockHours=math.max(0,math.min(100000000,streamReadFloat32(streamId)))
 local data={groups={},hygiene={surfaces={}}}
 local groupCount=math.min(streamReadUInt16(streamId),MAX_GROUPS)
 for _=1,groupCount do
  local id=streamReadString(streamId)
  local status=streamReadString(streamId)
  local diseaseId=streamReadString(streamId)
  local disease={groupId=id,status=status,diseaseId=diseaseId~="" and diseaseId or nil,
   elapsedHours=streamReadFloat32(streamId),exposureLoad=streamReadFloat32(streamId),severity=streamReadFloat32(streamId)}
  local quarantine=nil
  if streamReadBool(streamId) then
   quarantine={groupId=id,active=streamReadBool(streamId),startedAtHours=streamReadFloat32(streamId),
    durationHours=streamReadFloat32(streamId),hygieneCompliant=streamReadBool(streamId),
    releaseRequested=streamReadBool(streamId),reason="network"}
  end
  if type(id)=="string" and id~="" then data.groups[id]={disease=disease,quarantine=quarantine} end
 end
 local surfaceCount=math.min(streamReadUInt8(streamId),MAX_SURFACES)
 for _=1,surfaceCount do
  local id=streamReadString(streamId)
  local surface={dirt=streamReadFloat32(streamId),contamination=streamReadFloat32(streamId),
   disinfectantUntilHours=streamReadFloat32(streamId),pendingDisinfectantEffectiveness=streamReadFloat32(streamId)}
  if type(id)=="string" and id~="" then data.hygiene.surfaces[id]=surface end
 end
 if store~=nil and husbandryId~=nil then store:applyClientSnapshot(husbandryId,data) end
end

function Spec:onDelete()
 local spec=self.spec_agriSystemsBiosecurity
 if spec~=nil and spec.husbandryId~=nil then
  local store=getStore()
  if store~=nil then store:clearClusterBindings() end
 end
end
