AgriSystemsFarmBiosecurity = AgriSystemsFarmBiosecurity or {}
local Mod=AgriSystemsFarmBiosecurity
Mod.MOD_NAME=g_currentModName or "FS25_AgriSystems_FarmBiosecurity"
Mod.VERSION="0.1.0.0"
Mod.CONFIG=nil
local function log(message) print(string.format("[%s] %s",Mod.MOD_NAME,message)) end
function Mod:loadMap()
 if self.Config==nil or self.DiseaseModel==nil or self.Quarantine==nil or self.Hygiene==nil or self.BiosecurityScore==nil then
  log("ERROR: model modules missing; gameplay remains inactive."); return
 end
 self.CONFIG=self.Config.validate(nil)
 log(string.format("Development foundation loaded (version %s). Pure gameplay models available; engine integration is inactive.",self.VERSION))
end
function Mod:deleteMap() self.CONFIG=nil end
if type(addModEventListener)=="function" then addModEventListener(Mod) else log("WARNING: addModEventListener unavailable.") end
