-- Run from repository root with Lua 5.1+:
-- lua Testing/Model_Tests/Run_Farm_Biosecurity.lua

dofile("Farm_Biosecurity/scripts/core/Config.lua")
dofile("Farm_Biosecurity/scripts/core/DiseaseModel.lua")
dofile("Farm_Biosecurity/scripts/core/Quarantine.lua")
dofile("Farm_Biosecurity/scripts/core/Hygiene.lua")
dofile("Farm_Biosecurity/scripts/core/BiosecurityScore.lua")
dofile("Farm_Biosecurity/scripts/core/StateStore.lua")

local root=AgriSystemsFarmBiosecurity
local function near(a,b) assert(math.abs(a-b)<0.0001,string.format("expected %.4f, got %.4f",b,a)) end

local config=root.Config.validate({scoreWeights={quarantine=2,disease=1,barnHygiene=1,equipmentHygiene=0,visitorControl=0}})
local weightTotal=0
for _,v in pairs(config.scoreWeights) do weightTotal=weightTotal+v end
near(weightTotal,1)

local risk,accepted=root.DiseaseModel.evaluateExposure(1,1,1,1,1,0.5,0.25)
near(risk,0.5)
assert(accepted)
local disease=root.DiseaseModel.applyExposure(root.DiseaseModel.createGroupState("group-A"),"respiratory",risk)
assert(disease.status=="incubating")
disease=root.DiseaseModel.advance(disease,24)
assert(disease.status=="infectious")
disease=root.DiseaseModel.advance(disease,120)
assert(disease.status=="recovering")
disease=root.DiseaseModel.advance(disease,72)
assert(disease.status=="recovered")

local quarantine=root.Quarantine.createState("group-A",0,48)
quarantine=root.Quarantine.setHygieneCompliance(quarantine,true)
quarantine=root.Quarantine.requestRelease(quarantine)
assert(root.Quarantine.advance(quarantine,24).active)
assert(not root.Quarantine.advance(quarantine,48).active)

local hygiene=root.Hygiene.createState()
hygiene=root.Hygiene.setLoad(hygiene,"barn-door",0.5,0.8,1)
local disinfected
hygiene,disinfected=root.Hygiene.disinfect(hygiene,"barn-door",0.75,0.2,10,0.25,1)
assert(not disinfected)
hygiene=root.Hygiene.cleanDirt(hygiene,"barn-door",0.8,1)
hygiene,disinfected=root.Hygiene.disinfect(hygiene,"barn-door",0.75,0.2,10,0.25,1)
assert(disinfected)
near(root.Hygiene.getSurface(hygiene,"barn-door",1).contamination,0.8)
local completed
hygiene,completed=root.Hygiene.completeDisinfection(hygiene,"barn-door",10.24,1)
assert(not completed)
hygiene,completed=root.Hygiene.completeDisinfection(hygiene,"barn-door",10.25,1)
assert(completed)
near(root.Hygiene.getSurface(hygiene,"barn-door",1).contamination,0.2)

local score=root.BiosecurityScore.calculate({quarantine=1,disease=1,barnHygiene=1,equipmentHygiene=1,visitorControl=1},config.scoreWeights)
assert(score==100)

local store=root.StateStore.new(true,10)
local group=root.DiseaseModel.createGroupState("group-A")
group=root.DiseaseModel.applyExposure(group,"respiratory",0.4)
assert(store:setGroup("husbandry-A","group-A",group,quarantine))
assert(store:splitGroup("husbandry-A","group-A",{"group-B","group-C"}))
assert(store:getGroup("husbandry-A","group-B").disease.status=="incubating")
assert(store:mergeGroups("husbandry-A",{"group-B","group-C"},"group-D"))
assert(store:getGroup("husbandry-A","group-D").disease.status=="incubating")
assert(store:bindCluster(42,"group-D"))
assert(store:getGroupIdForCluster(42)=="group-D")
store:clearClusterBindings()
assert(store:getGroupIdForCluster(42)==nil)
assert(root.StateStore.new(false,10):ensureHusbandry("client-write")==false)

print("Farm Biosecurity model tests: PASS")
