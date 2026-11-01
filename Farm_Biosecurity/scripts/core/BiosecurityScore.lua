AgriSystemsFarmBiosecurity = AgriSystemsFarmBiosecurity or {}
AgriSystemsFarmBiosecurity.BiosecurityScore = {}
local Score=AgriSystemsFarmBiosecurity.BiosecurityScore
local function clamp(v) if type(v)~="number" or v~=v or v==math.huge or v==-math.huge then return 0 end return math.max(0,math.min(1,v)) end
-- Components are normalized compliance values supplied by authoritative systems.
function Score.calculate(components,weights)
 components=type(components)=="table" and components or {}; weights=type(weights)=="table" and weights or {}
 local names={"quarantine","disease","barnHygiene","equipmentHygiene","visitorControl"}
 local sum,weightSum=0,0; local breakdown={}
 for _,name in ipairs(names) do
  local w=clamp(weights[name]); local v=clamp(components[name])
  breakdown[name]=v*100; sum=sum+v*w; weightSum=weightSum+w
 end
 if weightSum<=0 then return 0,breakdown end
 return math.floor(sum/weightSum*100+0.5),breakdown
end
