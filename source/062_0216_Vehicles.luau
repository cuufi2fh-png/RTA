-- Server-owned unanchored chassis. Client sends only bounded driver intent.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local V={}
function V.start(P,C,net)
 local cars={} local cooldown={} local world=workspace:WaitForChild('RTAWorld')
 local folder=world:FindFirstChild('Vehicles') or Instance.new('Folder') folder.Name='Vehicles' folder.Parent=world
 local function remove(p)
  local c=cars[p] if c then c.connection:Disconnect() c.model:Destroy() cars[p]=nil end
 end
 local function part(name,size,cf,parent,color)
  local b=Instance.new('Part') b.Name=name b.Size=size b.CFrame=cf b.Color=color or Color3.fromRGB(44,80,124) b.Material=Enum.Material.Metal b.Parent=parent return b
 end
 local self={}
 function self.spawn(p,id)
  local d=P.get(p) local def=C.Vehicles[id] local ch=p.Character local h=ch and ch:FindFirstChildOfClass('Humanoid') local root=ch and ch:FindFirstChild('HumanoidRootPart')
  local point=world.Points:FindFirstChild('CarShop')
  if not d or not def or not d.rta.ownedVehicles[id] or not h or h.Health<=0 or not root or not point or (root.Position-point.Position).Magnitude>18 then return false,'소유한 차량을 차량 상점에서 출고하세요.' end
  if os.clock()-(cooldown[p] or -100)<5 then return false,'차량 출고는 5초마다 가능합니다.' end cooldown[p]=os.clock()
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={ch,world}
  local desired=point.Position+Vector3.new(0,20,-22) local hit=workspace:Raycast(desired,Vector3.new(0,-80,0),params)
  if not hit or hit.Normal.Y<.65 then return false,'출고 위치의 지면을 확인하세요.' end
  local cf=CFrame.new(hit.Position+Vector3.new(0,2.5,0))
  local overlap=OverlapParams.new() overlap.FilterType=Enum.RaycastFilterType.Exclude overlap.FilterDescendantsInstances={ch,world.NPCs,world.Points,cars[p] and cars[p].model or ch}
  for _,b in ipairs(workspace:GetPartBoundsInBox(cf,Vector3.new(7,3,12),overlap)) do if b.CanCollide then return false,'출고 공간이 막혀 있습니다.' end end
  remove(p)
  local m=Instance.new('Model') m.Name=id..'_'..p.UserId m:SetAttribute('OwnerUserId',p.UserId) m:SetAttribute('VehicleId',id)
  local body=part('Chassis',Vector3.new(6,1.3,10),cf,m) m.PrimaryPart=body body.CustomPhysicalProperties=PhysicalProperties.new(.7,.005,0,100,1)
  local function weld(b)
   b.Massless=true local w=Instance.new('WeldConstraint') w.Part0=body w.Part1=b w.Parent=b
  end
  local cabin=part('Cabin',Vector3.new(5,1.7,4.7),cf*CFrame.new(0,1.4,.4),m,Color3.fromRGB(39,51,61)) cabin.CanCollide=false cabin.Transparency=.35 weld(cabin)
  local seat=Instance.new('VehicleSeat') seat.Name='DriverSeat' seat.Size=Vector3.new(2,.7,2) seat.CFrame=cf*CFrame.new(0,1.1,.7) seat.MaxSpeed=0 seat.Torque=0 seat.CanCollide=false seat.Parent=m weld(seat)
  for _,x in ipairs({-3,3}) do for _,z in ipairs({-3.1,3.1}) do local wheel=part('Wheel',Vector3.new(.7,2.3,2.3),cf*CFrame.new(x,-.35,z),m,Color3.fromRGB(20,21,24)) wheel.Shape=Enum.PartType.Cylinder wheel.CanCollide=false weld(wheel) end end
  local a=Instance.new('Attachment') a.Name='DriveAttachment' a.Parent=body
  local force=Instance.new('VectorForce') force.Attachment0=a force.RelativeTo=Enum.ActuatorRelativeTo.World force.ApplyAtCenterOfMass=true force.Parent=body
  local yaw=Instance.new('AngularVelocity') yaw.Attachment0=a yaw.RelativeTo=Enum.ActuatorRelativeTo.World yaw.MaxTorque=1000000 yaw.Parent=body
  m.Parent=folder body:SetNetworkOwner(nil)
  local groundParams=RaycastParams.new() groundParams.FilterType=Enum.RaycastFilterType.Exclude groundParams.FilterDescendantsInstances={m,ch}
  local c={groundParams=groundParams,model=m,body=body,seat=seat,force=force,yaw=yaw,def=def,throttle=0,steer=0,last=0,inputAt=0}
  c.connection=seat:GetPropertyChangedSignal('Occupant'):Connect(function()
   groundParams.FilterDescendantsInstances={m,p.Character}
   local occupant=seat.Occupant
   if occupant and Players:GetPlayerFromCharacter(occupant.Parent)~=p then occupant.Sit=false end
   c.throttle=0 c.steer=0 c.last=0 body:SetNetworkOwner(nil)
  end)
  cars[p]=c return true,def.name..' 출고 완료'
 end
 function self.despawn(p) remove(p) return true,'차량 반납 완료' end
 net.VehicleInput.OnServerEvent:Connect(function(p,throttle,steer)
  local c=cars[p] if not c then return end local now=os.clock() if now-c.inputAt<.04 then return end c.inputAt=now
  if type(throttle)~='number' or type(steer)~='number' or throttle~=throttle or steer~=steer or math.abs(throttle)>1 or math.abs(steer)>1 then return end
  local h=c.seat.Occupant if not h or h.Health<=0 or Players:GetPlayerFromCharacter(h.Parent)~=p then return end
  c.throttle=throttle c.steer=steer c.last=now
 end)
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<1/30 then return end elapsed=0
  for p,c in pairs(cars) do
   if not c.model.Parent then remove(p) continue end
   local b=c.body local velocity=b.AssemblyLinearVelocity local mass=b.AssemblyMass
   local active=c.seat.Occupant and c.seat.Occupant.Health>0 and Players:GetPlayerFromCharacter(c.seat.Occupant.Parent)==p and os.clock()-c.last<.4
   local throttle=active and c.throttle or 0 local steer=active and c.steer or 0
   local forward=Vector3.new(b.CFrame.LookVector.X,0,b.CFrame.LookVector.Z)
   if forward.Magnitude<.1 then c.force.Force=Vector3.zero c.yaw.AngularVelocity=Vector3.zero continue end forward=forward.Unit
   local horizontal=Vector3.new(velocity.X,0,velocity.Z) local speed=horizontal:Dot(forward)
   local side=horizontal-forward*speed
   local accel=throttle*c.def.acceleration-speed*.35
   if math.abs(speed)>c.def.speed and throttle*speed>0 then accel=-speed*.5 end
   if throttle==0 then accel=-speed*3 end
   local ground=workspace:Raycast(b.Position,Vector3.new(0,-4,0),c.groundParams)
   c.force.Force=ground and (forward*accel-side*9)*mass or Vector3.zero
   c.yaw.AngularVelocity=Vector3.new(0,-steer*c.def.turnRate*math.clamp(speed/20,-1,1),0)
   -- Roll/pitch damping retains gravity and slope response rather than teleporting the car.
   local omega=b.AssemblyAngularVelocity c.yaw.AngularVelocity+=Vector3.new(-omega.X*.5,0,-omega.Z*.5)
   c.model:SetAttribute('Speed',math.floor(horizontal.Magnitude))
   if b.Position.Y<workspace.FallenPartsDestroyHeight+15 then remove(p) end
  end
 end)
 Players.PlayerRemoving:Connect(function(p) remove(p) cooldown[p]=nil end)
 return self
end
return V
