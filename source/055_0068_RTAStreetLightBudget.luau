-- Local lighting budget; no server gameplay state changes.
local Run=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local Lighting=game:GetService('Lighting')
local lamps=workspace:WaitForChild('Pacific Hills'):WaitForChild('11_Lamps')
local mobile=Input.TouchEnabled and not Input.KeyboardEnabled
local limit=mobile and 16 or 24
local shadowLimit=mobile and 0 or 4
local radius=mobile and 180 or 240
local records,connections={},{}
local candidates={}
local active,elapsed=0,0
local function add(v)
 if v:IsA('Light') and not records[v] then records[v]={light=v,distance=math.huge,enabled=v.Enabled,shadows=v.Shadows};v.Enabled=false;v.Shadows=false end
end
local function position(l)
 local p=l.Parent
 if p and p:IsA('Attachment') then return p.WorldPosition end
 if p and p:IsA('BasePart') then return p.Position end
end
local function update()
 local camera=workspace.CurrentCamera;if not camera then return end
 local night=Lighting.ClockTime<=6.3 or Lighting.ClockTime>=17.7
 table.clear(candidates)
 if night then
  local origin=camera.CFrame.Position
  for l,r in pairs(records)do
   local pos=position(l)
   if pos then local delta=pos-origin;r.distance=delta:Dot(delta);if r.distance<=radius*radius then table.insert(candidates,r) end end
  end
  table.sort(candidates,function(a,b)return a.distance<b.distance end)
 end
 local enabled={};local shadows={}
 active=math.min(#candidates,limit)
 for i=1,active do local l=candidates[i].light;enabled[l]=true;if i<=shadowLimit then shadows[l]=true end end
 for l in pairs(records)do if l.Parent then
 local on=enabled[l]==true;local shadow=shadows[l]==true
 if l.Enabled~=on then l.Enabled=on end;if l.Shadows~=shadow then l.Shadows=shadow end
 end end
 script:SetAttribute('ActiveStreetLights',active);script:SetAttribute('ShadowBudget',shadowLimit)
end
for _,v in ipairs(lamps:GetDescendants())do add(v)end
connections[#connections+1]=lamps.DescendantAdded:Connect(add)
connections[#connections+1]=lamps.DescendantRemoving:Connect(function(v)records[v]=nil end)
connections[#connections+1]=Run.Heartbeat:Connect(function(dt)elapsed+=dt;if elapsed<.35 then return end;elapsed=0;update()end)
script.Destroying:Connect(function()
 for _,c in ipairs(connections)do c:Disconnect()end
 for l,r in pairs(records)do if l.Parent then l.Enabled=r.enabled;l.Shadows=r.shadows end end
 table.clear(records)
end)
update()
