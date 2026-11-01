-- Run from repository root with Lua 5.1+:
-- lua Testing/Model_Tests/Run_Spray_Hygiene.lua

dofile("Spray_Hygiene/scripts/core/SprayerCondition.lua")
dofile("Spray_Hygiene/scripts/core/SprayerCleaning.lua")
dofile("Spray_Hygiene/scripts/core/SprayDrift.lua")
dofile("Spray_Hygiene/scripts/core/FieldContamination.lua")
dofile("Spray_Hygiene/scripts/core/StateStore.lua")

local root=AgriSystemsSprayHygiene
local function near(a,b) assert(math.abs(a-b)<0.0001,string.format("expected %.4f, got %.4f",b,a)) end

local condition=root.SprayerCondition.createState()
condition=root.SprayerCondition.applyWork(condition,2,0.5)
near(condition.condition,99)
near(condition.wear,1)
near(condition.calibration,99.5)
assert(root.SprayerCondition.getCoverageFactor(condition,0.5)<1)

local cleaning=root.SprayerCleaning.createState()
cleaning=root.SprayerCleaning.addResidue(cleaning,"tank","herbicide",0.8)
cleaning=root.SprayerCleaning.cleanCompartment(cleaning,"tank",0.5)
near(cleaning.residues.tank.herbicide,0.4)
near(root.SprayerCleaning.getCarryOver(cleaning,"fertilizer",{herbicide={fertilizer=0.5}}),0.2)

local drift=root.SprayDrift.evaluate({windSpeedMps=8,dropletSizeMicron=100,boomHeightM=2,windToDirectionX=1,windToDirectionZ=0})
near(drift.risk,1)
near(drift.transportDirectionX,1)
assert(root.SprayDrift.getRiskBand(drift.risk)=="high")

local field=root.FieldContamination.createState()
local transferred
field,transferred=root.FieldContamination.transferToField(field,7,"weedSeed",0.5,0.2,0.5,1)
near(transferred,0.05)
near(root.FieldContamination.getLoad(field,7,"weedSeed",1),0.05)
field=root.FieldContamination.washField(field,7,0.5,1)
near(root.FieldContamination.getLoad(field,7,"weedSeed",1),0.025)

local store=root.StateStore.new(true,1)
local record=store:ensureVehicleState("sprayer-A")
assert(record~=nil and store:isDirty())
record.condition.condition=75
assert(store:setVehicleState("sprayer-A",record.condition,record.cleaning))
local exported=store:exportState()
exported.vehicles["sprayer-A"].condition.condition=1
near(store:getVehicleState("sprayer-A").condition.condition,75)
for index=2,root.StateStore.MAX_VEHICLES do
    assert(store:ensureVehicleState("sprayer-" .. tostring(index))~=nil)
end
assert(store:ensureVehicleState("sprayer-overflow")==nil)
assert(root.StateStore.new(false,1):ensureVehicleState("client-write")==nil)

print("Spray & Hygiene model tests: PASS")
