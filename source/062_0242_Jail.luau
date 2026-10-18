-- Server-owned detention survives character replacement within this server session.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local service
local Jail={}
function Jail.start()
 if service then return service end
 local prisoners={}
 service={}
 local function restore(entry)
  local h,r=entry.humanoid,entry.root
  if h and h.Parent then
   h.WalkSpeed=entry.speed h.JumpPower=entry.jumpPower h.JumpHeight=entry.jumpHeight
  end
  if r and r.Parent then r.Anchored=entry.anchored end
  entry.humanoid=nil entry.root=nil
 end
 function service.release(p)
  local entry=prisoners[p] if entry then restore(entry) prisoners[p]=nil end
  if p.Parent==Players then p:SetAttribute('RTAJailedUntil',nil) p:SetAttribute('RTAInCustody',nil) end
 end
 local function enforce(p,entry)
  local ch=p.Character local h=ch and ch:FindFirstChildOfClass('Humanoid') local r=ch and ch:FindFirstChild('HumanoidRootPart')
  if not h or not r or h.Health<=0 then return end
  if entry.humanoid~=h then
   restore(entry)
   entry.humanoid=h entry.root=r entry.speed=h.WalkSpeed entry.jumpPower=h.JumpPower entry.jumpHeight=h.JumpHeight entry.anchored=r.Anchored
  end
  h:UnequipTools() h.WalkSpeed=0 h.JumpPower=0 h.JumpHeight=0
  r.Anchored=true r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
  ch:PivotTo(entry.spawn*CFrame.new(0,3,0))
 end
 function service.detain(p,spawnCFrame,seconds)
  service.release(p)
  local entry={spawn=spawnCFrame,expires=os.clock()+seconds}
  prisoners[p]=entry p:SetAttribute('RTAInCustody',true) p:SetAttribute('RTAJailedUntil',os.time()+seconds)
  enforce(p,entry)
 end
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  for p,entry in pairs(prisoners) do
   if p.Parent~=Players or os.clock()>=entry.expires then service.release(p) else enforce(p,entry) end
  end
 end)
 Players.PlayerRemoving:Connect(service.release)
 return service
end
return Jail
