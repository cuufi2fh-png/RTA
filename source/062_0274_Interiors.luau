local Players=game:GetService('Players')
local singleton
local I={}
function I.start()
 if singleton then return singleton end
 local world=workspace.RTAWorld local rooms=world:WaitForChild('Interiors') local entries=world:WaitForChild('Entrances')
 local active,busy,last={},{},{}
 local function root(p)
  local c=p.Character local h=c and c:FindFirstChildOfClass('Humanoid') local r=c and c:FindFirstChild('HumanoidRootPart')
  if not h or h.Health<=0 or h.Sit or not r or p:GetAttribute('RTAInCustody') then return end
  return r,c
 end
 local function transfer(p,id,leaving)
  if busy[p] or os.clock()-(last[p] or -10)<1 then return false end
  local room=type(id)=='string' and rooms:FindFirstChild(id) local entry=type(id)=='string' and entries:FindFirstChild(id)
  local r,c=root(p) if not room or not entry or not r then return false end
  local from=leaving and room.Exit or entry
  if (r.Position-from.Position).Magnitude>14 or (leaving and active[p]~=id) then return false end
  local target=leaving and CFrame.new(entry.Position+Vector3.new(0,1,5)) or room.Arrival.CFrame
  busy[p]=true last[p]=os.clock()
  pcall(function() p:RequestStreamAroundAsync(target.Position,3) end)
  local current= root(p)
  if current~=r or not p.Parent or (r.Position-from.Position).Magnitude>14 then busy[p]=nil return false end
  c:PivotTo(target) r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
  if leaving then active[p]=nil else active[p]=id end p:SetAttribute('RTAInterior',active[p]) busy[p]=nil return true
 end
 singleton={enter=function(p,id) return transfer(p,id,false) end,leave=function(p,id) return transfer(p,id,true) end}
 for _,room in ipairs(rooms:GetChildren()) do
  local id=room.Name local entry=entries:FindFirstChild(id)
  if entry and entry:FindFirstChild('Enter') then entry.Enter.Triggered:Connect(function(p) singleton.enter(p,id) end) end
  room.Exit.Leave.Triggered:Connect(function(p) singleton.leave(p,id) end)
 end
 local function added(p) p.CharacterAdded:Connect(function() active[p]=nil p:SetAttribute('RTAInterior',nil) end) end
 for _,p in ipairs(Players:GetPlayers()) do added(p) end Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(p) active[p]=nil busy[p]=nil last[p]=nil end)
 return singleton
end
return I
