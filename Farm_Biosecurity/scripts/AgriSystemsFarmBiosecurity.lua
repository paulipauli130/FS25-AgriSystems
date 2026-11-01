AgriSystemsFarmBiosecurity = AgriSystemsFarmBiosecurity or {}
local Mod=AgriSystemsFarmBiosecurity
Mod.MOD_NAME=g_currentModName or "FS25_AgriSystems_FarmBiosecurity"
Mod.VERSION="0.4.0.0"
Mod.CONFIG=nil
Mod.STATE_STORE=nil
local function log(message) print(string.format("[%s] %s",Mod.MOD_NAME,message)) end
function Mod:loadMap()
 if self.Config==nil or self.DiseaseModel==nil or self.Quarantine==nil
  or self.Hygiene==nil or self.BiosecurityScore==nil or self.StateStore==nil then
  log("ERROR: model modules missing; gameplay remains inactive."); return
 end
 self.CONFIG=self.Config.validate(nil)
 if self.STATE_STORE==nil then
  self.STATE_STORE=self.StateStore.new(g_server~=nil,self.CONFIG.disease.maximumGroups)
 end
 log(string.format("Development foundation loaded (version %s). Pure gameplay models and server-gated state store available; engine integration is inactive.",self.VERSION))
end
function Mod:deleteMap()
 self.STATE_STORE=nil
 self.CONFIG=nil
end
function Mod:getConfiguration() return self.CONFIG end
function Mod:getStateStore() return self.STATE_STORE end
if type(addModEventListener)=="function" then addModEventListener(Mod) else log("WARNING: addModEventListener unavailable.") end
