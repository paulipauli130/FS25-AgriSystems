AgriSystemsFarmBiosecurity = AgriSystemsFarmBiosecurity or {}
AgriSystemsFarmBiosecurity.DiseaseModel = {}
local Disease=AgriSystemsFarmBiosecurity.DiseaseModel
local PROFILES={
 respiratory={incubationHours=24,infectiousHours=120,recoveryHours=72,infectiousness=0.65,severity=0.7},
 digestive={incubationHours=18,infectiousHours=96,recoveryHours=72,infectiousness=0.55,severity=0.6},
 generic={incubationHours=24,infectiousHours=96,recoveryHours=72,infectiousness=0.5,severity=0.5}
}
local function clamp(v,lo,hi,d)
 if type(v)~="number" or v~=v or v==math.huge or v==-math.huge then return d end
 return math.max(lo,math.min(hi,v))
end
function Disease.getProfile(id)
 local p=PROFILES[id] or PROFILES.generic
 return {incubationHours=p.incubationHours,infectiousHours=p.infectiousHours,recoveryHours=p.recoveryHours,infectiousness=p.infectiousness,severity=p.severity}
end
function Disease.createGroupState(id)
 if type(id)~="string" or id=="" or string.len(id)>128 then return nil end
 return {groupId=id,status="susceptible",diseaseId=nil,elapsedHours=0,exposureLoad=0,severity=0}
end
function Disease.validateGroupState(c)
 if type(c)~="table" then return nil end
 local s=Disease.createGroupState(c.groupId)
 if s==nil then return nil end
 local allowed={susceptible=true,incubating=true,infectious=true,recovering=true,recovered=true}
 s.status=allowed[c.status] and c.status or "susceptible"
 s.diseaseId=type(c.diseaseId)=="string" and c.diseaseId or nil
 s.elapsedHours=clamp(c.elapsedHours,0,1000000,0)
 s.exposureLoad=clamp(c.exposureLoad,0,1,0)
 s.severity=clamp(c.severity,0,1,0)
 if s.status=="susceptible" then s.diseaseId=nil end
 return s
end
-- Call only after a server-confirmed contact opportunity. No spontaneous infection.
function Disease.evaluateExposure(infectiousness,intensity,route,hygiene,susceptibility,baseRate,roll)
 local risk=clamp(baseRate,0,1,0)*clamp(infectiousness,0,1,0)*clamp(intensity,0,1,0)
  *clamp(route,0,1,0)*clamp(hygiene,0,1,1)*clamp(susceptibility,0,1,1)
 risk=clamp(risk,0,1,0)
 return risk,clamp(roll,0,1,1)<risk
end
function Disease.applyExposure(state,id,amount)
 local r=Disease.validateGroupState(state)
 if r==nil or r.status~="susceptible" or PROFILES[id]==nil then return r end
 r.exposureLoad=clamp(amount,0,1,0)
 if r.exposureLoad>0 then r.status="incubating"; r.diseaseId=id; r.elapsedHours=0 end
 return r
end
function Disease.advance(state,elapsed)
 local r=Disease.validateGroupState(state)
 if r==nil or r.status=="susceptible" or r.status=="recovered" then return r end
 local hours=clamp(elapsed,0,720,0)
 r.elapsedHours=r.elapsedHours+hours
 local p=Disease.getProfile(r.diseaseId)
 if r.status=="incubating" and r.elapsedHours>=p.incubationHours then r.status="infectious"; r.elapsedHours=r.elapsedHours-p.incubationHours end
 if r.status=="infectious" and r.elapsedHours>=p.infectiousHours then r.status="recovering"; r.elapsedHours=r.elapsedHours-p.infectiousHours end
 if r.status=="infectious" then r.severity=math.min(p.severity,r.severity+hours/p.infectiousHours*p.severity) end
 if r.status=="recovering" then
  r.severity=math.max(0,r.severity-hours/p.recoveryHours*p.severity)
  if r.elapsedHours>=p.recoveryHours then r.status="recovered"; r.elapsedHours=0; r.severity=0; r.exposureLoad=0 end
 end
 return r
end
function Disease.getProfileIds() return {"respiratory","digestive","generic"} end
