AgriSystemsFarmBiosecurity = AgriSystemsFarmBiosecurity or {}
AgriSystemsFarmBiosecurity.StateStore = {}
local Store=AgriSystemsFarmBiosecurity.StateStore
Store.SCHEMA_VERSION=1
Store.MAX_HUSBANDRIES=128
local function validId(v) return type(v)=="string" and v~="" and string.len(v)<=128 end
local function count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
local function copy(t)
 local r={}; if type(t)=="table" then
  for k,v in pairs(t) do if type(v)=="table" then r[k]=copy(v) elseif type(v)=="string" or type(v)=="number" or type(v)=="boolean" then r[k]=v end end
 end
 return r
end
function Store.createState() return {schemaVersion=1,husbandries={}} end
function Store.new(isServer,maximumGroups)
 local limit=type(maximumGroups)=="number" and math.floor(maximumGroups) or 512
 limit=math.max(1,math.min(2048,limit))
 return setmetatable({isServer=isServer==true,maximumGroups=limit,state=Store.createState(),clusterToGroup={},dirty=false},{__index=Store})
end
function Store:ensureHusbandry(husbandryId)
 if not self.isServer or not validId(husbandryId) then return false end
 if self.state.husbandries[husbandryId]==nil then
  if count(self.state.husbandries)>=Store.MAX_HUSBANDRIES then return false end
  self.state.husbandries[husbandryId]={groups={},hygiene={surfaces={}}}; self.dirty=true
 end
 return true
end
function Store:ensureGroup(husbandryId,groupId)
 if not self:ensureHusbandry(husbandryId) or not validId(groupId) then return nil end
 local h=self.state.husbandries[husbandryId]
 if h.groups[groupId]==nil then
  if count(h.groups)>=self.maximumGroups then return nil end
  h.groups[groupId]={disease=AgriSystemsFarmBiosecurity.DiseaseModel.createGroupState(groupId),quarantine=nil}
  self.dirty=true
 end
 return copy(h.groups[groupId])
end
function Store:getGroup(husbandryId,groupId)
 local h=self.state.husbandries[husbandryId]; if h==nil or h.groups[groupId]==nil then return nil end
 return copy(h.groups[groupId])
end
function Store:setGroup(husbandryId,groupId,diseaseState,quarantineState)
 if not self.isServer or not validId(husbandryId) or not validId(groupId) then return false end
 if not self:ensureHusbandry(husbandryId) then return false end
 local h=self.state.husbandries[husbandryId]
 if h.groups[groupId]==nil and count(h.groups)>=self.maximumGroups then return false end
 local disease=AgriSystemsFarmBiosecurity.DiseaseModel.validateGroupState(diseaseState)
 if disease==nil then return false end
 disease.groupId=groupId
 local quarantine=quarantineState and AgriSystemsFarmBiosecurity.Quarantine.validateState(quarantineState) or nil
 h.groups[groupId]={disease=disease,quarantine=quarantine}
 self.dirty=true
 return true
end
function Store:bindCluster(engineClusterId,groupId)
 if not self.isServer or engineClusterId==nil or not validId(groupId) then return false end
 self.clusterToGroup[tostring(engineClusterId)]=groupId
 return true
end
function Store:getGroupIdForCluster(engineClusterId)
 return engineClusterId~=nil and self.clusterToGroup[tostring(engineClusterId)] or nil
end
function Store:clearClusterBindings() self.clusterToGroup={} end
function Store:splitGroup(husbandryId,parentGroupId,childGroupIds)
 if not self.isServer then return false end
 local parent=self:getGroup(husbandryId,parentGroupId)
 if parent==nil or type(childGroupIds)~="table" then return false end
 local children=AgriSystemsFarmBiosecurity.DiseaseModel.splitState(parent.disease,childGroupIds)
 local target=self.state.husbandries[husbandryId]
 local needed,seen=0,{}
 for _,child in ipairs(children) do
  if seen[child.groupId] then return false end
  seen[child.groupId]=true
  if child.groupId~=parentGroupId and target.groups[child.groupId]==nil then needed=needed+1 end
 end
 if count(target.groups)+needed>self.maximumGroups then return false end
 for i,child in ipairs(children) do
  local q=parent.quarantine and AgriSystemsFarmBiosecurity.Quarantine.validateState(parent.quarantine) or nil
  if q~=nil then q.groupId=child.groupId end
  if not self:setGroup(husbandryId,child.groupId,child,q) then return false end
 end
 return true
end
function Store:mergeGroups(husbandryId,sourceGroupIds,newGroupId)
 if not self.isServer or type(sourceGroupIds)~="table" or not validId(newGroupId) then return false end
 local h=self.state.husbandries[husbandryId]; if h==nil then return false end
 if h.groups[newGroupId]~=nil then return false end
 local diseaseStates,quarantines={},{}
 local seen={}
 for _,id in ipairs(sourceGroupIds) do
  if not validId(id) or id==newGroupId or seen[id] then return false end
  seen[id]=true
  local record=h.groups[id]
  if record~=nil then table.insert(diseaseStates,record.disease); if record.quarantine~=nil then table.insert(quarantines,record.quarantine) end end
 end
 if #diseaseStates==0 then return false end
 local mergedDisease=AgriSystemsFarmBiosecurity.DiseaseModel.mergeStates(diseaseStates,newGroupId)
 local mergedQuarantine=nil
 if #quarantines>0 then
  mergedQuarantine=AgriSystemsFarmBiosecurity.Quarantine.validateState(quarantines[1])
  mergedQuarantine.groupId=newGroupId
  for i=2,#quarantines do
   local q=AgriSystemsFarmBiosecurity.Quarantine.validateState(quarantines[i])
   mergedQuarantine.startedAtHours=math.min(mergedQuarantine.startedAtHours,q.startedAtHours)
   mergedQuarantine.durationHours=math.max(mergedQuarantine.durationHours,q.durationHours)
   mergedQuarantine.active=mergedQuarantine.active or q.active
   mergedQuarantine.hygieneCompliant=mergedQuarantine.hygieneCompliant and q.hygieneCompliant
   mergedQuarantine.releaseRequested=mergedQuarantine.releaseRequested and q.releaseRequested
  end
 end
 if not self:setGroup(husbandryId,newGroupId,mergedDisease,mergedQuarantine) then return false end
 for _,id in ipairs(sourceGroupIds) do h.groups[id]=nil end
 h.groups[newGroupId]={disease=mergedDisease,quarantine=mergedQuarantine}
 self.dirty=true
 return true
end
function Store:exportState() return copy(self.state) end
function Store:loadState(candidate)
 if not self.isServer then return false end
 local state=Store.createState()
 if type(candidate)=="table" and type(candidate.husbandries)=="table" then
  for husbandryId,h in pairs(candidate.husbandries) do
   if count(state.husbandries)>=Store.MAX_HUSBANDRIES then break end
   if validId(husbandryId) and type(h)=="table" then
    local target={groups={},hygiene=AgriSystemsFarmBiosecurity.Hygiene.validateState(h.hygiene)}
    if type(h.groups)=="table" then
     for groupId,record in pairs(h.groups) do
      if validId(groupId) and type(record)=="table" and count(target.groups)<self.maximumGroups then
       local disease=AgriSystemsFarmBiosecurity.DiseaseModel.validateGroupState(record.disease)
       if disease~=nil then
        disease.groupId=groupId
        local q=record.quarantine and AgriSystemsFarmBiosecurity.Quarantine.validateState(record.quarantine) or nil
        target.groups[groupId]={disease=disease,quarantine=q}
       end
      end
     end
    end
    state.husbandries[husbandryId]=target
   end
  end
 end
 self.state=state; self.clusterToGroup={}; self.dirty=false
 return true
end
function Store:isDirty() return self.dirty end
function Store:markSaved() self.dirty=false end

function Store:getHusbandryState(husbandryId)
 local record=self.state.husbandries[husbandryId]
 return record~=nil and copy(record) or nil
end

function Store:loadHusbandryState(husbandryId,candidate)
 if not self.isServer or not validId(husbandryId) or type(candidate)~="table" then return false end
 if not self:ensureHusbandry(husbandryId) then return false end
 local target={groups={},hygiene=AgriSystemsFarmBiosecurity.Hygiene.validateState(candidate.hygiene)}
 if type(candidate.groups)=="table" then
  for groupId,record in pairs(candidate.groups) do
   if count(target.groups)>=self.maximumGroups then break end
   if validId(groupId) and type(record)=="table" then
    local disease=AgriSystemsFarmBiosecurity.DiseaseModel.validateGroupState(record.disease)
    if disease~=nil then
     disease.groupId=groupId
     local quarantine=record.quarantine and AgriSystemsFarmBiosecurity.Quarantine.validateState(record.quarantine) or nil
     if quarantine~=nil then quarantine.groupId=groupId end
     target.groups[groupId]={disease=disease,quarantine=quarantine}
    end
   end
  end
 end
 self.state.husbandries[husbandryId]=target
 self.dirty=true
 return true
end

function Store:applyClientSnapshot(husbandryId,candidate)
 if self.isServer or not validId(husbandryId) or type(candidate)~="table" then return false end
 local target={groups={},hygiene=AgriSystemsFarmBiosecurity.Hygiene.validateState(candidate.hygiene)}
 if type(candidate.groups)=="table" then
  for groupId,record in pairs(candidate.groups) do
   if count(target.groups)>=self.maximumGroups then break end
   if validId(groupId) and type(record)=="table" then
    local disease=AgriSystemsFarmBiosecurity.DiseaseModel.validateGroupState(record.disease)
    if disease~=nil then
     disease.groupId=groupId
     local quarantine=record.quarantine and AgriSystemsFarmBiosecurity.Quarantine.validateState(record.quarantine) or nil
     if quarantine~=nil then quarantine.groupId=groupId end
     target.groups[groupId]={disease=disease,quarantine=quarantine}
    end
   end
  end
 end
 self.state.husbandries[husbandryId]=target
 self.dirty=false
 return true
end
