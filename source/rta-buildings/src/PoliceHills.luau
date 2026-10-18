-- Edit-time only. Preserve buildings, surveyed player plots and existing streets.
local V=Vector3.new
local C=Color3.fromRGB
local T=workspace.Terrain
local map=workspace:FindFirstChild('RTA_IslandMap')
assert(game.PlaceId==99252064112998 and map and not game:GetService('RunService'):IsRunning())
assert(not map:FindFirstChild('PoliceHills'),'Police hills already installed; inspect before rebuilding')
local sites={
 {id='POLICE_01',rise=32,route={{5084,326},{5053,326},{5025,334},{4986,330},{4948,315},{4915,300},{4894,283},{4894,266}}},
 {id='POLICE_02',rise=40,route={{5082,510},{5048,510},{5009,499},{4970,497},{4934,516},{4884,539},{4837,539},{4814,523},{4814,494}}},
}
local lo,hi=V(4600,12,40),V(5136,84,648)
local existing=game.ServerStorage:FindFirstChild('RTA_BeforePoliceHills_20261018');if existing then assert(#existing:GetChildren()==0,'Existing hill backup must be inspected');existing:Destroy()end
local backup=Instance.new('Folder');backup.Name='RTA_BeforePoliceHills_20261018';backup.Parent=game.ServerStorage
backup:SetAttribute('TerrainMinCell',lo/4);backup:SetAttribute('TerrainMaxCell',hi/4-Vector3.one)
backup:SetAttribute('OldTerrainMax',map:GetAttribute('TerrainMax'))
local terrainBackup=T:CopyRegion(Region3int16.new(Vector3int16.new(lo.X/4,lo.Y/4,lo.Z/4),Vector3int16.new(hi.X/4-1,hi.Y/4-1,hi.Z/4-1)))
terrainBackup.Name='BeforeHillTerrain';terrainBackup.Parent=backup
local config=game.StarterGui.RTA_UI.Config;config:Clone().Parent=backup
local marker=workspace.RTAPoints:FindFirstChild('Police');if marker then marker:Clone().Parent=backup end
for _,s in sites do
 s.building=map.Architecture:FindFirstChild(s.id);assert(s.building,'Missing '..s.id)
 for _,p in map.Plots:GetChildren()do if p:GetAttribute('PlotId')==s.id then s.plot=p;break end end
 assert(s.plot);s.building:Clone().Parent=backup;task.wait();s.plot:Clone().Parent=backup
 local fore=s.building:FindFirstChild('PoliceForecourt',true);s.center=fore.Position;s.hx=fore.Size.X/2+2;s.hz=fore.Size.Z/2+2
 s.ground=fore.Position.Y-fore.Size.Y/2+s.rise-2.6
 s.roadTop=fore.Position.Y+fore.Size.Y/2+s.rise
end
local streets={};for _,p in map.Roads:GetDescendants()do
 if p:IsA('BasePart')and p.Name=='Base'and p.Position.X<5300 and p.Position.Z<1000 and p.Position.Z> -200 then table.insert(streets,p)end
end
local protected={};for _,p in map.Plots:GetChildren()do if p:GetAttribute('PlotId')~='POLICE_01'and p:GetAttribute('PlotId')~='POLICE_02'then table.insert(protected,p.BuildArea)end end
local function rectDistance(x,z,part,margin)
 local q=part.CFrame:PointToObjectSpace(V(x,part.Position.Y,z));local dx=math.abs(q.X)-part.Size.X/2-(margin or 0);local dz=math.abs(q.Z)-part.Size.Z/2-(margin or 0)
 return math.sqrt(math.max(0,dx)^2+math.max(0,dz)^2)+math.min(0,math.max(dx,dz))
end
local function smooth(t)t=math.clamp(t,0,1);return t*t*(3-2*t)end
local function cat(a,b,c,d,t)return .5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)end
local maxGrade=0
for _,s in sites do
 local raw={};for _,p in s.route do table.insert(raw,V(p[1],0,p[2]))end
 local pts={};local lengths={};local total=0
 for i=1,#raw-1 do
  for j=0,9 do local t=j/10;local q=cat(raw[math.max(1,i-1)],raw[i],raw[i+1],raw[math.min(#raw,i+2)],t)
   if #pts>0 then total+=(q-pts[#pts]).Magnitude end
   table.insert(pts,q);table.insert(lengths,total)
  end
 end
 total+=(raw[#raw]-pts[#pts]).Magnitude;table.insert(pts,raw[#raw]);table.insert(lengths,total)
 s.path={}
 for i,p in pts do local progress=(lengths[i]-22)/(total-40);table.insert(s.path,V(p.X,18.23+(s.roadTop-18.23)*smooth(progress),p.Z))end
 for i=1,#s.path-1 do local d=s.path[i+1]-s.path[i];maxGrade=math.max(maxGrade,math.abs(d.Y)/Vector3.new(d.X,0,d.Z).Magnitude)end
 s.length=total
end
assert(maxGrade<.29,'Driveway grade exceeds design limit')
local function distancePath(x,z,s)
 local q=V(x,0,z);local best=math.huge;local height=18
 for i=1,#s.path-1 do
  local a,b=s.path[i],s.path[i+1];local aa=V(a.X,0,a.Z);local delta=V(b.X-a.X,0,b.Z-a.Z)
  local t=math.clamp((q-aa):Dot(delta)/delta:Dot(delta),0,1);local d=(q-aa-delta*t).Magnitude
  if d<best then best=d;height=a.Y+(b.Y-a.Y)*t end
 end
 return best,height
end
local function surface(x,z)
 local target=0
 for _,s in sites do
  local dx=math.max(0,math.abs(x-s.center.X)-s.hx);local dz=math.max(0,math.abs(z-s.center.Z)-s.hz)
  local dist=math.sqrt(dx*dx+dz*dz);local falloff=95+math.noise(x*.009,z*.009)*15
  target=math.max(target,18+(s.ground-18)*(1-smooth(dist/falloff)))
 end
 for _,s in sites do
  local d,h=distancePath(x,z,s)
  if d<44 then
   local support=18+(h-4-18)*(1-smooth((d-17)/27));target=math.max(target,support)
   if d<19 then target=math.min(target,h-4)end
  end
 end
 for _,p in streets do local d=rectDistance(x,z,p,3);if d<18 then target=math.min(target,18+math.max(0,d)*1.3)end end
 for _,p in protected do local d=rectDistance(x,z,p,5);if d<24 then target=math.min(target,18+math.max(0,d)*.8)end end
 return target
end
local root=Instance.new('Folder');root.Name='PoliceHills';root:SetAttribute('MaxDrivewayGrade',maxGrade);root.Parent=map
local changed=0;local tiles=0
for x=lo.X,hi.X-4,64 do for z=lo.Z,hi.Z-4,64 do
 local xmax,zmax=math.min(x+64,hi.X),math.min(z+64,hi.Z)
 local region=Region3.new(V(x,lo.Y,z),V(xmax,hi.Y,zmax));local mats,occ=T:ReadVoxels(region,4)
 for ix=1,#mats do for iz=1,#mats[ix][1]do
  local target=surface(x+(ix-.5)*4,z+(iz-.5)*4)
  if target>18.05 then for iy=1,#mats[ix]do
   local bottom=lo.Y+(iy-1)*4;local fill=math.clamp((target-bottom)/4,0,1)
   if fill>occ[ix][iy][iz]then occ[ix][iy][iz]=fill;mats[ix][iy][iz]=bottom>target-5 and Enum.Material.Grass or Enum.Material.Rock;changed+=1 end
  end end
 end end
 T:WriteVoxels(region,4,mats,occ);tiles+=1;task.wait()
end end
local partCount=0
local function part(parent,name,size,cf,color,material,collide)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.Concrete;p.Anchored=true;p.CanCollide=collide~=false;p.CanTouch=false;p.CastShadow=collide~=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;partCount+=1;return p
end
local function strip(parent,name,a,b,width,thickness,offset,color,material,side)
 local d=b-a;local cf=CFrame.lookAt((a+b)/2,b);return part(parent,name,V(width,thickness,d.Magnitude+.12),cf*CFrame.new(side or 0,offset,0),color,material)
end
for _,s in sites do
 local delta=V(0,s.rise,0)
 s.building:PivotTo(s.building:GetPivot()+delta);s.plot:PivotTo(s.plot:GetPivot()+delta)
 local nodes=s.building:GetDescendants();table.insert(nodes,s.building)
 for _,v in nodes do for key,value in v:GetAttributes()do
  if typeof(value)=='CFrame'then v:SetAttribute(key,value+delta)
  elseif typeof(value)=='Vector3'and(key=='Entrance'or key=='ServicePosition'or key=='VaultPoint'or key=='AircraftSpawn')then v:SetAttribute(key,value+delta)end
 end end
 s.building:SetAttribute('HillRise',s.rise);s.plot:SetAttribute('HillRise',s.rise)
 local folder=Instance.new('Folder');folder.Name=s.id;folder.Parent=root
 folder:SetAttribute('RoadStart',s.path[1]);folder:SetAttribute('RoadEnd',s.path[#s.path]);folder:SetAttribute('Rise',s.rise)
 local paths=Instance.new('Folder');paths.Name='RouteNodes';paths.Parent=folder
 for i,p in s.path do local node=Instance.new('Vector3Value');node.Name=string.format('%03d',i);node.Value=p;node.Parent=paths end
 for i=1,#s.path-1 do
  local a,b=s.path[i],s.path[i+1]
  strip(folder,'DrivewayBase',a,b,31,2.4,-1.55,C(158,163,157),Enum.Material.Concrete)
  strip(folder,'DrivewayAsphalt',a,b,25,.65,-.325,C(54,61,64),Enum.Material.Asphalt)
  for _,side in {-1,1}do
   strip(folder,'Sidewalk',a,b,3,.35,.12,C(185,186,172),Enum.Material.Pavement,side*14)
   strip(folder,'EdgeLine',a,b,.18,.04,.035,C(235,231,204),Enum.Material.SmoothPlastic,side*11.5)
   if i>9 and i<#s.path-8 then strip(folder,'Guardrail',a,b,.25,.45,2.6,C(151,162,161),Enum.Material.Metal,side*15.3)end
  end
  if i%4<2 then strip(folder,'CenterLine',a,b,.24,.045,.04,C(234,184,65),Enum.Material.SmoothPlastic)end
  if i%7==0 and i>9 and i<#s.path-8 then
   local cf=CFrame.lookAt(a,b)
   for _,side in {-1,1}do part(folder,'RailPost',V(.3,3,.3),cf*CFrame.new(side*15.3,1.4,0),C(113,124,125),Enum.Material.Metal)end
  end
  if i%18==0 then task.wait()end
 end
 -- Narrow retaining walls where the raised northern campus faces the existing street.
 if s.id=='POLICE_01'then
  local z=s.center.Z-s.hz
  for xx=s.center.X-s.hx,s.center.X+s.hx-4,8 do
   part(folder,'NorthRetainingStone',V(8,s.rise+.4,1.5),CFrame.new(xx+4,18+s.rise/2,z-1),C(128,134,124),Enum.Material.Cobblestone)
  end
 end
end
-- Existing landscape is lifted only where new terrain rises beneath its base.
local landscapeBackup=Instance.new('Folder');landscapeBackup.Name='AdjustedLandscape';landscapeBackup.Parent=backup
for _,item in map.Landscape:GetChildren()do
 local base
 for _,p in item:GetDescendants()do if p:IsA('BasePart')and(p.Name=='Trunk'or p.Name=='Pole')then base=p;break end end
 if base and base.Position.X>=lo.X and base.Position.X<=hi.X and base.Position.Z>=lo.Z and base.Position.Z<=hi.Z then
  local h=surface(base.Position.X,base.Position.Z);local old=base.Position.Y-base.Size.Y/2
  if h-old>3 then
   item:Clone().Parent=landscapeBackup
   local delta=V(0,h-old,0);for _,p in item:GetDescendants()do if p:IsA('BasePart')then p.CFrame+=delta end end
  end
 end
end
-- A small amount of planting on the grass shoulders, clear of routes and building pads.
local rng=Random.new(18102026);local trees=0
for i=1,70 do
 local x=rng:NextNumber(4660,5025);local z=rng:NextNumber(145,565);local h=surface(x,z);local valid=h>21
 for _,s in sites do if rectDistance(x,z,s.plot.BuildArea,9)<0 then valid=false end;local d=distancePath(x,z,s);if d<25 then valid=false end end
 for _,p in protected do if rectDistance(x,z,p,8)<0 then valid=false end end
 if valid and trees<18 then
  local f=Instance.new('Model');f.Name='HillTree';f.Parent=root;local height=rng:NextNumber(12,19)
  part(f,'Trunk',V(1.1,height*.65,1.1),CFrame.new(x,h+height*.325,z),C(103,83,59),Enum.Material.Wood)
  local crown=part(f,'Canopy',V(height*.65,height*.7,height*.65),CFrame.new(x,h+height*.8,z),C(69+rng:NextInteger(0,16),108+rng:NextInteger(0,20),62),Enum.Material.Grass,false);crown.Shape=Enum.PartType.Ball;trees+=1
 end
end
local main=sites[1].building:GetAttribute('Entrance')+V(0,-1,12)
if marker then marker.Position=main end
local oldSource=config.Source
config.Source=oldSource:gsub('(id="Police"[^\n]-position=)Vector3.new%([^%)]+%)',function(prefix)return prefix..string.format('Vector3.new(%.6f,%.6f,%.6f)',main.X,main.Y,main.Z)end)
local max=map:GetAttribute('TerrainMax');map:SetAttribute('TerrainMax',V(max.X,math.max(max.Y,hi.Y),max.Z))
map:SetAttribute('PoliceHillVersion',1)
root:SetAttribute('TerrainVoxelsAdded',changed);root:SetAttribute('NewParts',partCount);root:SetAttribute('Ready',true)
game:GetService('ChangeHistoryService'):SetWaypoint('Police stations on hills')
return game:GetService('HttpService'):JSONEncode({status='complete',stations=2,terrainTiles=tiles,voxelsAdded=changed,parts=partCount,trees=trees,maxGrade=maxGrade,backup=backup:GetFullName()})
