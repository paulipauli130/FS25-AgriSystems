AgriSystemsFarmBiosecurity = AgriSystemsFarmBiosecurity or {}
AgriSystemsFarmBiosecurity.Quarantine = {}
local Q=AgriSystemsFarmBiosecurity.Quarantine
local function clamp(v,a,b,d) if type(v)~="number" or v~=v or v==math.huge or v==-math.huge then return d end return math.max(a,math.min(b,v)) end
function Q.createState(id,now,duration)
 if type(id)~="string" or id=="" then return nil end
 return {groupId=id,active=true,startedAtHours=clamp(now,0,1e8,0),durationHours=clamp(duration,1,720,48),hygieneCompliant=false,releaseRequested=false,reason="new_or_returning_group"}
end
function Q.validateState(c)
 if type(c)~="table" or type(c.groupId)~="string" or c.groupId=="" then return nil end
 return {groupId=c.groupId,active=c.active~=false,startedAtHours=clamp(c.startedAtHours,0,1e8,0),durationHours=clamp(c.durationHours,1,720,48),hygieneCompliant=c.hygieneCompliant==true,releaseRequested=c.releaseRequested==true,reason=type(c.reason)=="string" and c.reason or "unspecified"}
end
function Q.setHygieneCompliance(s,v) local r=Q.validateState(s); if r then r.hygieneCompliant=v==true end return r end
function Q.requestRelease(s) local r=Q.validateState(s); if r and r.active then r.releaseRequested=true end return r end
function Q.advance(s,now)
 local r=Q.validateState(s); if r==nil or not r.active then return r end
 local t=clamp(now,r.startedAtHours,1e8,r.startedAtHours)
 r.active=not (r.releaseRequested and r.hygieneCompliant and t-r.startedAtHours>=r.durationHours)
 return r
end
function Q.getRemainingHours(s,now)
 local r=Q.validateState(s); if r==nil or not r.active then return 0 end
 local t=clamp(now,r.startedAtHours,1e8,r.startedAtHours)
 return math.max(0,r.durationHours-(t-r.startedAtHours))
end
