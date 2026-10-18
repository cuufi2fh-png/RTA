-- Anchored, swept server simulation. Clients submit throttle/steer/lift only.
local Players=game:GetService('Players');local Run=game:GetService('RunService')
local V=Vector3.new;local C=Color3.fromRGB;local Service={}
function Service.start(Catalog,world,net)
 local active,lastSpawn={},{};local folder=Instance.new('Folder');folder.Name='Vehicles';folder.Parent=world.dynamic
 local self={};local origin=world.map:GetAttribute('MapOrigin')or Vector3.zero
 local function part(m,n,size,cf,col,mat)
  local p=Instance.new('Part');p.Name=n;p.Size=size;p.CFrame=cf;p.Color=col;p.Material=mat or Enum.Material.Metal;p.Anchored=true;p.CanCollide=n=='Chassis'or n=='Deck'or n=='HullSide';p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
 end
 function self.remove(p)local s=active[p];if s then if s.occupantConnection then s.occupantConnection:Disconnect()end;if s.enterConnection then s.enterConnection:Disconnect()end;s.model:Destroy();active[p]=nil end end
 function self.state(p)return active[p]end
 function self.spawn(p,category,id,spawnPosition)
  local def=Catalog[category]and Catalog[category][id];if not def then return false,'없는 차량입니다.'end
  local now=os.clock();if now-(lastSpawn[p]or-100)<4 then return false,'출고는 4초마다 가능합니다.'end
  lastSpawn[p]=now
  local styles={Compact=V(6,3.5,10.5),Sedan=V(7,4,13),Taxi=V(7,4,14),Sport=V(7.4,3.2,14),Van=V(8,5.5,17),SUV=V(8,5,15)}
  local size=category=='Boats'and V(def.width,8,def.length)or category=='Aircraft'and(id=='Helicarrier'and V(45,15,60)or V(12,8,24))or styles[def.style or'Sedan']or V(7,4,13)
  if category=='Boats'then spawnPosition+=V(0,0,def.length/2)end
  local cf=CFrame.new(spawnPosition+V(0,size.Y/2+1,0))
  local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude;local exclude={};if p.Character then table.insert(exclude,p.Character)end;if active[p]then table.insert(exclude,active[p].model)end;overlap.FilterDescendantsInstances=exclude
  for _,v in workspace:GetPartBoundsInBox(cf,size,overlap)do if v.CanCollide then return false,'출고 공간에 다른 물체가 있습니다.'end end
  self.remove(p)
  local model=Instance.new('Model');model.Name=def.name..'_'..p.UserId;model:SetAttribute('OwnerUserId',p.UserId);model:SetAttribute('VehicleId',id);model:SetAttribute('VehicleCategory',category);model:SetAttribute('Taxi',def.taxi==true)
  local hash=0;for i=1,#id do hash=(hash*31+id:byte(i))%100000 end
  local color=def.taxi and C(239,184,55)or C(65+(hash*29)%145,89+(hash*37)%121,104+(hash*17)%110)
  local body=part(model,'Chassis',V(size.X,1.3,size.Z),cf,color);model.PrimaryPart=body
  local seatOffset=V(-1.2,1.7,0)
  local rotor
  if category=='Vehicles'then
   local w,l,h=size.X,size.Z,size.Y;model:SetAttribute('Style',def.style)
   part(model,'Hood',V(w*.91,.9,l*.3),cf*CFrame.new(0,.8,-l*.29),color)
   part(model,'Cabin',V(w*.8,h*.56,l*.4),cf*CFrame.new(0,h*.4,1),C(58,79,89),Enum.Material.Glass).Transparency=.28
   part(model,'Roof',V(w*.83,.3,l*.31),cf*CFrame.new(0,h*.72,1.2),color)
   for _,x in {-w*.5,w*.5}do for _,z in {-l*.31,l*.31}do local w=part(model,'Wheel',V(.9,2.5,2.5),cf*CFrame.new(x,-.5,z),C(25,27,29),Enum.Material.Rubber);w.Shape=Enum.PartType.Cylinder end end
   for _,x in {-w*.36,w*.36}do part(model,'Headlight',V(1.1,.45,.12),cf*CFrame.new(x,.4,-l*.505),C(241,237,196),Enum.Material.Neon);part(model,'Taillight',V(1.1,.4,.12),cf*CFrame.new(x,.4,l*.505),C(208,64,55),Enum.Material.Neon)end
   if def.style=='Sport'then part(model,'RearSpoiler',V(w*.98,.3,1.2),cf*CFrame.new(0,2,l*.42),C(37,42,46))end
   if def.taxi then part(model,'TaxiSign',V(2.7,.8,1),cf*CFrame.new(0,3.5,1),C(252,215,85))end
  elseif category=='Boats'then
   part(model,'Deck',V(size.X*.9,.7,size.Z*.94),cf*CFrame.new(0,1,0),C(218,212,187),Enum.Material.WoodPlanks)
   part(model,'Cabin',V(size.X*.6,6,size.Z*.3),cf*CFrame.new(0,4,size.Z*.12),C(230,231,222))
   for _,side in {-1,1}do part(model,'HullSide',V(.8,3,size.Z),cf*CFrame.new(side*size.X/2,1,0),color)end
   part(model,'Windscreen',V(size.X*.57,3,.3),cf*CFrame.new(0,4,-size.Z*.05),C(84,145,162),Enum.Material.Glass).Transparency=.4
   seatOffset=V(0,2,-size.Z*.17)
  else
   part(model,'Cockpit',V(size.X*.65,5,size.Z*.35),cf*CFrame.new(0,3,-size.Z*.2),C(74,129,145),Enum.Material.Glass).Transparency=.35
   part(model,'Tail',V(2,2,size.Z*.65),cf*CFrame.new(0,2,size.Z*.55),color)
   part(model,'LandingLeft',V(1,1,size.Z*.7),cf*CFrame.new(-size.X*.45,-2,0),C(50,55,57))
   part(model,'LandingRight',V(1,1,size.Z*.7),cf*CFrame.new(size.X*.45,-2,0),C(50,55,57))
   if id=='Blackbird'then
    part(model,'MainWings',V(33,.65,9),cf*CFrame.new(0,1,2),color);part(model,'TailWing',V(15,.6,4),cf*CFrame.new(0,3,size.Z*.6),color)
    for _,x in {-9,9}do part(model,'JetEngine',V(3,3,14),cf*CFrame.new(x,1,3),C(52,59,65))end
   else
   rotor=part(model,'Rotor',V(size.X*2.8,.3,1.2),cf*CFrame.new(0,6,0),C(52,58,60));rotor.CanCollide=false
   end
   seatOffset=V(0,2.5,-size.Z*.2)
  end
  local engine=Instance.new('Sound');engine.Name='Engine';engine.SoundId=Catalog.VehicleAudio.Engine;engine.Volume=0;engine.Looped=true;engine.RollOffMinDistance=10;engine.RollOffMaxDistance=100;engine.Parent=body;engine:Play()
  local seat=Instance.new('VehicleSeat');seat.Name='DriverSeat';seat.Size=V(2,.6,2);seat.CFrame=cf*CFrame.new(seatOffset);seat.Anchored=true;seat.Transparency=.5;seat.MaxSpeed=0;seat.Torque=0;seat.Parent=model
  local prompt=Instance.new('ProximityPrompt');prompt.Name='EnterVehicle';prompt.ActionText='운전';prompt.ObjectText=def.name;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Parent=seat
  local s={model=model,seat=seat,cf=cf,size=size,speed=0,throttle=0,steer=0,lift=0,last=0,inputAt=0,def=def,kind=category,engine=engine,rotor=rotor,angle=0}
  s.occupantConnection=seat:GetPropertyChangedSignal('Occupant'):Connect(function()local h=seat.Occupant;if h and Players:GetPlayerFromCharacter(h.Parent)~=p then h.Sit=false end;s.throttle=0;s.steer=0;s.lift=0 end)
  s.enterConnection=prompt.Triggered:Connect(function(who)if who~=p then return end;local ch=p.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local r=ch and ch:FindFirstChild('HumanoidRootPart');if h and h.Health>0 and r and(r.Position-seat.Position).Magnitude<14 and not seat.Occupant then seat:Sit(h)end end)
  model.Parent=folder;active[p]=s;return true,def.name..' 출고 완료'
 end
 net.Drive.OnServerEvent:Connect(function(p,throttle,steer,lift)
  local s=active[p];if not s or os.clock()-s.inputAt<.045 then return end;s.inputAt=os.clock()
  for _,v in {throttle,steer,lift}do if type(v)~='number'or v~=v or math.abs(v)>1 then return end end
  local h=s.seat.Occupant;if not h or h.Health<=0 or Players:GetPlayerFromCharacter(h.Parent)~=p then return end
  s.throttle=throttle;s.steer=steer;s.lift=lift;s.last=os.clock()
 end)
 local timer=0
 Run.Heartbeat:Connect(function(dt)
  timer+=dt;if timer<1/30 then return end;dt=math.min(timer,.07);timer=0
  for p,s in active do
   if not s.model.Parent then self.remove(p);continue end
   local h=s.seat.Occupant;local driving=h and h.Health>0 and Players:GetPlayerFromCharacter(h.Parent)==p and os.clock()-s.last<.4
   local throttle=driving and s.throttle or 0;local steer=driving and s.steer or 0;local lift=driving and s.lift or 0
   local max=s.def.speed;local target=throttle*max*(throttle<0 and .32 or 1);s.speed+=(target-s.speed)*math.min(1,dt*(throttle==0 and 3 or .8))
   local turn=s.kind=='Aircraft'and 1 or math.clamp(s.speed/22,-1,1)
   local cf=s.cf*CFrame.Angles(0,-steer*dt*(s.def.turnRate or .9)*turn,0);local delta=cf.LookVector*s.speed*dt
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={s.model,p.Character};params.IgnoreWater=s.kind=='Vehicles'
   if s.kind=='Aircraft'then delta+=V(0,lift*42*dt,0)end
   local checkSize=V(s.size.X*.85,math.max(2,s.size.Y*.5),s.size.Z*.9)
   local hit=delta.Magnitude>.001 and workspace:Blockcast(s.cf+V(0,1.7,0),checkSize,delta,params)
   if hit then delta=V(0,0,0);s.speed=0 end
   local position=cf.Position+delta
   if s.kind=='Vehicles'then
    local ground=workspace:Raycast(position+V(0,12,0),V(0,-35,0),params)
    if ground and ground.Normal.Y>.5 then position=V(position.X,ground.Position.Y+2,position.Z)else position=s.cf.Position;s.speed=0 end
   elseif s.kind=='Boats'then
    local ground=workspace:Raycast(position+V(0,8,0),V(0,-30,0),params)
    if ground and ground.Material~=Enum.Material.Water and ground.Position.Y>-.5 then position=s.cf.Position;s.speed=0 end
    position=V(position.X,1.2,position.Z)
   else
    local ground=workspace:Raycast(position+V(0,2,0),V(0,-1200,0),params)
    local minimum=ground and ground.Position.Y+5 or 6
    position=V(position.X,math.clamp(position.Y,minimum,600),position.Z)
   end
   if math.abs(position.X-origin.X)>2000 or math.abs(position.Z-origin.Z)>1500 then position=s.cf.Position;s.speed=0 end
   s.cf=CFrame.new(position)*cf.Rotation;s.model:PivotTo(s.cf);s.model:SetAttribute('Speed',math.floor(math.abs(s.speed)))
   if s.engine then s.engine.Volume=driving and .2+math.min(1,math.abs(s.speed)/max)*.25 or 0;s.engine.PlaybackSpeed=math.floor((.7+math.abs(s.speed)/max)*10)/10 end
   if s.rotor then s.angle+=dt*23;s.rotor.CFrame=s.cf*CFrame.new(0,6,0)*CFrame.Angles(0,s.angle,0)end
  end
 end)
 Players.PlayerRemoving:Connect(function(p)self.remove(p);lastSpawn[p]=nil end)
 return self
end
return Service
