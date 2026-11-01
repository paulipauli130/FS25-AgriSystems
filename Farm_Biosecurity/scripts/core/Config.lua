AgriSystemsFarmBiosecurity = AgriSystemsFarmBiosecurity or {}
AgriSystemsFarmBiosecurity.Config = {}
local Config = AgriSystemsFarmBiosecurity.Config
Config.SCHEMA_VERSION = 1
Config.DEFAULTS = {
 debug=false, modules={quarantine=true,disease=true,hygiene=true,score=true},
 quarantine={durationHours=48,hygieneThreshold=0.7},
 disease={progressionIntervalMinutes=60,maximumGroups=512},
 hygiene={maximumLoad=1,dirtRemoval=0.6,disinfectionEffectiveness=0.75,requiredDirtThreshold=0.2},
 scoreWeights={quarantine=0.3,disease=0.3,barnHygiene=0.2,equipmentHygiene=0.15,visitorControl=0.05}
}
local function clamp(v,lo,hi,default)
 if type(v)~="number" or v~=v or v==math.huge or v==-math.huge then return default end
 return math.max(lo,math.min(hi,v))
end
function Config.createDefaults()
 local d=Config.DEFAULTS
 return {schemaVersion=1,debug=false,
  modules={quarantine=true,disease=true,hygiene=true,score=true},
  quarantine={durationHours=d.quarantine.durationHours,hygieneThreshold=d.quarantine.hygieneThreshold},
  disease={progressionIntervalMinutes=d.disease.progressionIntervalMinutes,maximumGroups=d.disease.maximumGroups},
  hygiene={maximumLoad=d.hygiene.maximumLoad,dirtRemoval=d.hygiene.dirtRemoval,disinfectionEffectiveness=d.hygiene.disinfectionEffectiveness,requiredDirtThreshold=d.hygiene.requiredDirtThreshold},
  scoreWeights={quarantine=d.scoreWeights.quarantine,disease=d.scoreWeights.disease,barnHygiene=d.scoreWeights.barnHygiene,equipmentHygiene=d.scoreWeights.equipmentHygiene,visitorControl=d.scoreWeights.visitorControl}}
end
function Config.validate(candidate)
 local r=Config.createDefaults()
 if type(candidate)~="table" then return r end
 r.debug=candidate.debug==true
 if type(candidate.modules)=="table" then for k in pairs(r.modules) do r.modules[k]=candidate.modules[k]==true end end
 if type(candidate.quarantine)=="table" then
  r.quarantine.durationHours=clamp(candidate.quarantine.durationHours,1,720,r.quarantine.durationHours)
  r.quarantine.hygieneThreshold=clamp(candidate.quarantine.hygieneThreshold,0,1,r.quarantine.hygieneThreshold)
 end
 if type(candidate.disease)=="table" then
  r.disease.progressionIntervalMinutes=math.floor(clamp(candidate.disease.progressionIntervalMinutes,5,1440,r.disease.progressionIntervalMinutes))
  r.disease.maximumGroups=math.floor(clamp(candidate.disease.maximumGroups,1,2048,r.disease.maximumGroups))
 end
 if type(candidate.hygiene)=="table" then
  for _,k in ipairs({"maximumLoad","dirtRemoval","disinfectionEffectiveness","requiredDirtThreshold"}) do
   r.hygiene[k]=clamp(candidate.hygiene[k],0,1,r.hygiene[k])
  end
  r.hygiene.maximumLoad=math.max(0.01,r.hygiene.maximumLoad)
 end
 if type(candidate.scoreWeights)=="table" then
  local total=0
  for k in pairs(r.scoreWeights) do r.scoreWeights[k]=clamp(candidate.scoreWeights[k],0,1,r.scoreWeights[k]); total=total+r.scoreWeights[k] end
  if total>0 then for k,v in pairs(r.scoreWeights) do r.scoreWeights[k]=v/total end end
 end
 return r
end
