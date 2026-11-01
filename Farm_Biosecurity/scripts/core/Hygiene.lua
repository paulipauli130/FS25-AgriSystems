AgriSystemsFarmBiosecurity = AgriSystemsFarmBiosecurity or {}
AgriSystemsFarmBiosecurity.Hygiene = {}
local H=AgriSystemsFarmBiosecurity.Hygiene
local MAX_SURFACES=1024
local function clamp(v,a,b,d) if type(v)~="number" or v~=v or v==math.huge or v==-math.huge then return d end return math.max(a,math.min(b,v)) end
local function valid(id) return type(id)=="string" and id~="" and string.len(id)<=128 end
function H.createState() return {schemaVersion=1,surfaces={}} end
function H.validateState(c,maximum)
 local r=H.createState(); local limit=clamp(maximum,0.01,1,1)
 if type(c)~="table" or type(c.surfaces)~="table" then return r end
 local n=0
 for id,s in pairs(c.surfaces) do
  if valid(id) and type(s)=="table" and n<MAX_SURFACES then
   r.surfaces[id]={dirt=clamp(s.dirt,0,limit,0),contamination=clamp(s.contamination,0,limit,0),disinfectantUntilHours=clamp(s.disinfectantUntilHours,0,1e8,0)}
   n=n+1
  end
 end
 return r
end
function H.setLoad(c,id,dirt,contamination,maximum)
 local r=H.validateState(c,maximum); if not valid(id) then return r end
 if r.surfaces[id]==nil then local n=0; for _ in pairs(r.surfaces) do n=n+1 end; if n>=MAX_SURFACES then return r end end
 local limit=clamp(maximum,0.01,1,1)
 r.surfaces[id]={dirt=clamp(dirt,0,limit,0),contamination=clamp(contamination,0,limit,0),disinfectantUntilHours=r.surfaces[id] and r.surfaces[id].disinfectantUntilHours or 0}
 return r
end
function H.cleanDirt(c,id,effect,maximum)
 local r=H.validateState(c,maximum); local s=r.surfaces[id]; if s then s.dirt=s.dirt*(1-clamp(effect,0,1,0)) end; return r
end
-- Disinfection only works after the dirt-cleaning stage meets its threshold.
function H.disinfect(c,id,effect,threshold,now,contact,maximum)
 local r=H.validateState(c,maximum); local s=r.surfaces[id]; if not s then return r,false end
 if s.dirt>clamp(threshold,0,1,0.2) then return r,false end
 s.contamination=s.contamination*(1-clamp(effect,0,1,0))
 s.disinfectantUntilHours=clamp(now,0,1e8,0)+clamp(contact,0,24,0)
 return r,true
end
function H.getSurface(c,id,maximum)
 local r=H.validateState(c,maximum); local s=r.surfaces[id]
 if not s then return {dirt=0,contamination=0,disinfectantUntilHours=0} end
 return {dirt=s.dirt,contamination=s.contamination,disinfectantUntilHours=s.disinfectantUntilHours}
end
function H.getCleanliness(c,id,maximum) local s=H.getSurface(c,id,maximum); return 1-math.max(s.dirt,s.contamination) end
