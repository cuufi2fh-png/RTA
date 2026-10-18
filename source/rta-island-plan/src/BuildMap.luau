-- Edit-time builder. Run once with the verified layout. No live economy or remote handlers.
local Build={}
local V=Vector3.new
local CF=CFrame.new
local C=Color3.fromRGB
local colors={asphalt=C(58,64,69),pavement=C(197,194,181),line=C(242,235,207),yellow=C(238,189,75),grass=C(103,139,77),sand=C(219,199,144),wood=C(129,97,68)}
local accents={Home=C(106,156,149),LargeHome=C(192,170,115),Business=C(196,140,79),Farm=C(133,158,71),Bank=C(75,117,160),Public=C(82,116,151),Shop=C(154,129,154),Dealer=C(79,143,164),Building=C(131,141,145),Activity=C(147,108,167),Reserved=C(143,143,133)}
function Build.run(D,job)
 local S=D.scale
 local origin=V(unpack(D.offset))
 local function pos(x,y,z)return origin+V((x-768)*S,y,(z-512)*S)end
 local root=workspace:FindFirstChild(D.name)
 assert(not root,'Map already exists. Inspect it instead of duplicating.')
 root=Instance.new('Model');root.Name=D.name;root:SetAttribute('Version',D.version);root:SetAttribute('MapOrigin',origin);root:SetAttribute('PixelScale',S);root.Parent=workspace
 local function folder(name,parent)local f=Instance.new('Folder');f.Name=name;f.Parent=parent or root;return f end
 local roads=folder('Roads');local plots=folder('Plots');local decor=folder('Landscape');local amenities=folder('Amenities');local points=folder('ActivityPoints')
 local count=0
 local function part(parent,name,size,cf,color,material,collide)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=collide~=false;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.CastShadow=collide~=false;p.Parent=parent;count+=1
  return p
 end
 local function box(parent,name,x,z,w,d,y,h,color,material,collide,yaw)
  return part(parent,name,V(w*S,h,d*S),CF(pos(x,y,z))*CFrame.Angles(0,math.rad(yaw or 0),0),color,material,collide)
 end
 local function sign(parent,name,text,position,color,width)
  local p=part(parent,name,V(width or 16,5,.45),CF(position),C(36,43,47),nil,false)
  local g=Instance.new('SurfaceGui');g.Name='Label';g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(600,180);g.AlwaysOnTop=false;g.LightInfluence=.1;g.Parent=p
  local l=Instance.new('TextLabel');l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=text;l.TextColor3=color or C(240,239,226);l.Font=Enum.Font.GothamBold;l.TextScaled=true;l.Parent=g
  return p
 end
 local function prompt(p,id,kind)
  p:SetAttribute('ContentPoint',id);p:SetAttribute('Menu',kind)
  local pp=Instance.new('ProximityPrompt');pp.Name='Interact';pp.ActionText='열기';pp.ObjectText=p.Name;pp.MaxActivationDistance=12;pp.RequiresLineOfSight=false;pp.Parent=p
 end
 -- Shore signed distance. Grass stops below the road slab, including Roblox decorative blades.
 local function edgeDistance(x,z,a,b)
  local dx,dz=b[1]-a[1],b[2]-a[2];local q=math.clamp(((x-a[1])*dx+(z-a[2])*dz)/(dx*dx+dz*dz),0,1)
  return math.sqrt((x-a[1]-q*dx)^2+(z-a[2]-q*dz)^2)
 end
 local function islandDistance(x,z,island)
  if island.ellipse then local e=island.ellipse;return (1-math.sqrt(((x-e[1])/e[3])^2+((z-e[2])/e[4])^2))*math.min(e[3],e[4])end
  local poly=island.polygon;local inside=false;local dist=1e6;local prev=poly[#poly]
  for _,p in poly do
   if (p[2]>z)~=(prev[2]>z) and x<(prev[1]-p[1])*(z-p[2])/(prev[2]-p[2])+p[1]then inside=not inside end
   dist=math.min(dist,edgeDistance(x,z,prev,p));prev=p
  end
  return inside and dist or -dist
 end
 local function shore(x,z)local d=-1e6;for _,i in D.islands do d=math.max(d,islandDistance(x,z,i))end return d end
 local yMin,yMax=-48,32;local nx=20;local tile=128
 local minX=math.floor((origin.X+(D.bounds[1]-768)*S-120)/tile)*tile
 local maxX=math.ceil((origin.X+(D.bounds[3]-768)*S+120)/tile)*tile
 local minZ=math.floor((origin.Z+(D.bounds[2]-512)*S-120)/tile)*tile
 local maxZ=math.ceil((origin.Z+(D.bounds[4]-512)*S+120)/tile)*tile
 root:SetAttribute('TerrainMin',V(minX,yMin,minZ));root:SetAttribute('TerrainMax',V(maxX,yMax,maxZ))
 job.stage='terrain';job.tiles=0;job.totalTiles=(maxX-minX)/tile*(maxZ-minZ)/tile
 for tx=minX,maxX-tile,tile do for tz=minZ,maxZ-tile,tile do
  local mats,occ={},{}
  for ix=1,32 do mats[ix]={};occ[ix]={};for iy=1,nx do mats[ix][iy]={};occ[ix][iy]={}end
   for iz=1,32 do
    local x=(tx+(ix-.5)*4-origin.X)/S+768;local z=(tz+(iz-.5)*4-origin.Z)/S+512
    local d=shore(x,z);local ripple=math.noise(x*.055,z*.055)*1.8;local h
    if d>15 then h=D.landHeight elseif d>0 then h=2+(d/15)*14 else h=math.max(-39,2+d*1.55+ripple)end
    local ground=(d>14)and Enum.Material.LeafyGrass or ((d>-15)and Enum.Material.Sand or Enum.Material.Sandstone)
    for iy=1,nx do local bottom=yMin+(iy-1)*4;local fill=math.clamp((h-bottom)/4,0,1)
     if fill>0 then mats[ix][iy][iz]=ground;occ[ix][iy][iz]=fill
     elseif bottom<0 then mats[ix][iy][iz]=Enum.Material.Water;occ[ix][iy][iz]=1
     else mats[ix][iy][iz]=Enum.Material.Air;occ[ix][iy][iz]=0 end
    end
   end
  end
  workspace.Terrain:WriteVoxels(Region3.new(V(tx,yMin,tz),V(tx+tile,yMax,tz+tile)),4,mats,occ)
  job.tiles+=1;task.wait()
 end end
 -- Roads and bridges: consistent elevation, accessible sidewalks, full-width junction surfaces.
 job.stage='roads';local segments={}
 local function pathPiece(parent,name,a,b,width,y,height,color,material)
  local va,vb=pos(a[1],y,a[2]),pos(b[1],y,b[2]);local len=(vb-va).Magnitude
  return part(parent,name,V(width*S,height,len+.22),CFrame.lookAt((va+vb)/2,vb),color,material)
 end
 for _,r in D.roads do
  local group=folder(r.id,roads)
  for i=1,#r.points-1 do
   local a,b=r.points[i],r.points[i+1];local dx,dz=b[1]-a[1],b[2]-a[2];local len=math.sqrt(dx*dx+dz*dz);local nx1,nz1=-dz/len,dx/len
   table.insert(segments,{a=a,b=b,width=r.width,bridge=r.bridge})
   pathPiece(group,'Base',a,b,r.width+5,D.roadTop-1.45,2.5,colors.pavement,Enum.Material.Concrete)
   pathPiece(group,'Asphalt',a,b,r.width,D.roadTop-.35,.7,colors.asphalt,Enum.Material.Asphalt)
   for _,side in {-1,1}do
    local off=(r.width/2-.8)*side
    pathPiece(group,'EdgeLine',{a[1]+nx1*off,a[2]+nz1*off},{b[1]+nx1*off,b[2]+nz1*off},.23,D.roadTop+.025,.05,colors.line,Enum.Material.SmoothPlastic)
   end
   for t=5,len-4,14 do
    local t1=math.min(t+6,len);local a1={a[1]+dx*t/len,a[2]+dz*t/len};local b1={a[1]+dx*t1/len,a[2]+dz*t1/len}
    if t1>t then pathPiece(group,'CentreDash',a1,b1,.36,D.roadTop+.04,.08,colors.yellow)end
   end
   if r.bridge then
    for _,side in {-1,1}do
     local off=side*(r.width/2+2)
     pathPiece(group,'BridgeRail',{a[1]+nx1*off,a[2]+nz1*off},{b[1]+nx1*off,b[2]+nz1*off},.55,D.roadTop+4.6,.65,C(224,221,208),Enum.Material.Metal)
     for t=5,len-4,12 do box(group,'RailPost',a[1]+dx*t/len+nx1*off,a[2]+dz*t/len+nz1*off,.5,.5,D.roadTop+2.2,4.4,C(224,221,208),Enum.Material.Metal)end
    end
    for t=16,len-12,36 do box(group,'BridgePier',a[1]+dx*t/len,a[2]+dz*t/len,r.width-2,4,-4,39,C(151,153,145),Enum.Material.Concrete)end
   end
  end
  task.wait()
 end
 local function roadDist(x,z,exclude)
  local d=1e6
  for _,r in segments do if r~=exclude then d=math.min(d,edgeDistance(x,z,r.a,r.b)-r.width/2)end end
  return d
 end
 -- Open numbered plots. No business sub-type icons, houses or permanent buildings.
 job.stage='plots'
 for _,p in D.plots do
  local m=Instance.new('Model');m.Name=p.id..'_'..p.label;m:SetAttribute('PlotId',p.id);m:SetAttribute('PlotType',p.kind);m:SetAttribute('OwnerUserId',0);m:SetAttribute('Label',p.label);m:SetAttribute('HouseSize',p.houseSize or'');m:SetAttribute('BusinessType',p.businessType or'');m.Parent=plots
  local cf=CF(pos(p.x,17.05,p.z))*CFrame.Angles(0,math.rad(p.yaw),0)
  local color=accents[p.kind]or accents.Reserved
  local mat=p.kind=='Farm'and Enum.Material.Ground or Enum.Material.Grass
  local pad=part(m,'BuildArea',V(p.width*S,.6,p.depth*S),cf,p.kind=='Farm'and C(115,88,56)or C(112,146,88),mat)
  m.PrimaryPart=pad;pad:SetAttribute('BuildWidth',p.width*S-8);pad:SetAttribute('BuildDepth',p.depth*S-8)
  for _,side in {-1,1}do
   part(m,'PlotBoundary',V(p.width*S,.25,.55),cf*CF(0,.45,side*p.depth*S/2),color,nil,false)
   part(m,'PlotBoundary',V(.55,.25,p.depth*S),cf*CF(side*p.width*S/2,.45,0),color,nil,false)
   for _,side2 in {-1,1}do part(m,'SurveyMarker',V(1,2,1),cf*CF(side*p.width*S/2,1,side2*p.depth*S/2),C(235,232,213),nil,false)end
  end
  local signPos=cf:PointToWorldSpace(V(0,5,p.depth*S/2-3));local board=sign(m,'PlotSign',p.label..'  |  '..p.id,signPos,color,math.min(35,p.width*S*.7));board.CFrame=cf*CF(0,5,p.depth*S/2-3)
  prompt(board,p.id,p.kind)
  local anchor=part(m,'PlacementAnchor',V(1,1,1),cf*CF(0,2,0),color,nil,false);anchor.Transparency=1;anchor.CanQuery=false
  local labelPlate=part(m,'PlanLabel',V(math.min(p.width*S-6,100),.05,18),cf*CF(0,.4,0),color,nil,false)
  local gui=Instance.new('SurfaceGui');gui.Name='PlanLabel';gui.Face=Enum.NormalId.Top;gui.CanvasSize=Vector2.new(600,120);gui.LightInfluence=.2;gui.Parent=labelPlate
  local txt=Instance.new('TextLabel');txt.Size=UDim2.fromScale(1,1);txt.BackgroundTransparency=1;txt.Text=p.label..' '..p.id;txt.TextColor3=C(250,249,236);txt.TextScaled=true;txt.Font=Enum.Font.GothamBold;txt.Parent=gui
  if p.kind=='Farm'then for n=1,8 do box(m,'SoilRow',p.x-p.width/2+4+(p.width-8)*n/9,p.z,1.5,p.depth-10,17.55,.5,C(103,76,48),Enum.Material.Ground)end end
  task.wait()
 end
 local function tree(x,z,h,parent)
  local model=Instance.new('Model');model.Name='CoastalTree';model.Parent=parent or decor
  box(model,'Trunk',x,z,1.4,1.4,16+h*.36,h*.72,C(111,88,61),Enum.Material.Wood)
  local canopy=part(model,'Canopy',V(h*.8,h*.72,h*.8),CF(pos(x,16+h*.86,z)),C(67+math.floor(h)%20,115+math.floor(h)%23,63),Enum.Material.Grass,false);canopy.Shape=Enum.PartType.Ball
  local tip=part(model,'Crown',V(h*.62,h*.61,h*.64),CF(pos(x+1,16+h*1.08,z)),C(81,132,66),Enum.Material.Grass,false);tip.Shape=Enum.PartType.Ball
 end
 local function inPlot(x,z,margin)
  for _,p in D.plots do local a=math.rad(p.yaw);local dx,dz=x-p.x,z-p.z;local lx=dx*math.cos(a)-dz*math.sin(a);local lz=dx*math.sin(a)+dz*math.cos(a)
   if math.abs(lx)<p.width/2+margin and math.abs(lz)<p.depth/2+margin then return true end
  end
  return false
 end
 -- Street furniture and landscape use deterministic spacing instead of dense random instance spam.
 job.stage='landscape';local rng=Random.new(16102026);local treeCount=0
 for x=80,1460,23 do for z=30,970,23 do
  local xx,zz=x+rng:NextNumber(-5,5),z+rng:NextNumber(-5,5);local d=shore(xx,zz)
  if d>14 and d<31 and roadDist(xx,zz)>10 and not inPlot(xx,zz,5)then tree(xx,zz,rng:NextNumber(16,26));treeCount+=1 end
 end;task.wait()end
 local function lamp(x,z)
  local m=folder('StreetLamp',decor);box(m,'Pole',x,z,.45,.45,24,16,C(54,62,64),Enum.Material.Metal)
  box(m,'Arm',x+.8,z,2,.35,31.8,.45,C(54,62,64),Enum.Material.Metal)
  box(m,'Lamp',x+1.5,z,1.25,.8,31.6,.4,C(242,226,183),Enum.Material.Neon,false)
 end
 for _,r in segments do
  local dx,dz=r.b[1]-r.a[1],r.b[2]-r.a[2];local len=math.sqrt(dx*dx+dz*dz)
  if len>45 and not r.bridge then for t=24,len-18,60 do
   local x=r.a[1]+dx*t/len-dz/len*(r.width/2+4);local z=r.a[2]+dz*t/len+dx/len*(r.width/2+4)
   if roadDist(x,z,r)>8 and not inPlot(x,z,1)then lamp(x,z)end
  end end
 end
 -- Parks and fountains are public-space details, buildings remain for the user.
 for _,p in D.parks do
  local g=folder(p.id,amenities);box(g,'Promenade',p.x,p.z,p.width,p.depth,16.6,1.2,colors.pavement,Enum.Material.Pavement)
  for _,side in {-1,1}do box(g,'Lawn',p.x+side*p.width*.29,p.z,p.width*.27,p.depth-12,17.3,.5,colors.grass,Enum.Material.Grass);tree(p.x+side*p.width*.3,p.z-12,19,g);tree(p.x+side*p.width*.3,p.z+12,21,g)end
  local fountain=part(g,'FountainBasin',V(23,2,23),CF(pos(p.x,18,p.z))*CFrame.Angles(0,0,math.pi/2),C(167,169,157),Enum.Material.Concrete);fountain.Shape=Enum.PartType.Cylinder;fountain.Size=V(2,23,23)
  local water=part(g,'FountainWater',V(.3,19,19),CF(pos(p.x,19.05,p.z))*CFrame.Angles(0,0,math.pi/2),C(83,158,169),Enum.Material.Glass,false);water.Shape=Enum.PartType.Cylinder
  for _,side in {-1,1}do local z=p.z+side*(p.depth/2-7);box(g,'Bench',p.x,z,10,2.1,18.2,1,colors.wood,Enum.Material.Wood);box(g,'BenchBack',p.x,z+side,10,.45,20.2,3.2,colors.wood,Enum.Material.Wood)end
 end
 local park=D.parks[1];local spawn=Instance.new('SpawnLocation');spawn.Name='IslandSpawn';spawn.Size=V(8,.6,8);spawn.CFrame=CF(pos(park.x-12,17.8,park.z));spawn.Anchored=true;spawn.Transparency=1;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root
 -- Parking, marina and a free three-hole putting course.
 local parking=D.parking;local pg=folder('Parking',amenities)
 box(pg,'ParkingAsphalt',parking.x,parking.z,parking.width,parking.depth,17,1,colors.asphalt,Enum.Material.Asphalt)
 for i=0,9 do for _,side in {-1,1}do box(pg,'BayLine',parking.x-parking.width/2+5+i*10,parking.z+side*19,.23,22,17.55,.08,colors.line)end end
 local dock=folder('Marina',amenities);box(dock,'MainPier',1283,327,21,137,3.2,2.5,colors.wood,Enum.Material.WoodPlanks)
 for i,z in {270,327,383}do box(dock,'Berth_'..i,1310,z,52,10,3.2,2.5,colors.wood,Enum.Material.WoodPlanks);for _,x in {1298,1332}do box(dock,'PierPile',x,z,2,2,-2,12,C(83,78,67),Enum.Material.Wood)end end
 local seaPoint=sign(points,'Fishing', '낚시터 / 물고기 판매',pos(1283,9,368),C(130,200,210),30);prompt(seaPoint,'Fishing','Fishing')
 local golf=D.golf;local gg=folder('Golf',amenities)
 box(gg,'GolfLawn',golf.x,golf.z,golf.width,golf.depth,16.8,1,colors.grass,Enum.Material.Grass)
 for i=1,3 do
  local x=golf.x-golf.width*.32+(i-1)*golf.width*.32
  box(gg,'Fairway_'..i,x,golf.z,85,66,17.5,.5,C(132,172,82),Enum.Material.Grass)
  local hole=part(gg,'Hole_'..i,V(.1,2.4,2.4),CF(pos(x+23,17.9,golf.z-15))*CFrame.Angles(0,0,math.pi/2),C(25,43,31),nil,false);hole.Shape=Enum.PartType.Cylinder;hole:SetAttribute('HoleIndex',i)
  box(gg,'FlagPole',x+23,golf.z-15,.2,.2,24,12,C(229,226,207),Enum.Material.Metal,false)
  box(gg,'Flag',x+25,golf.z-15,4,.15,28,4,C(224,116,77),Enum.Material.Fabric,false)
  local tee=sign(points,'Golf_'..i,'무료 골프 · '..i..'번 홀',pos(x-24,21,golf.z+15),C(170,209,121),25);prompt(tee,'Golf_'..i,'Golf')
  tee:SetAttribute('HolePosition',hole.Position)
 end
 root:SetAttribute('PlotCount',#D.plots);root:SetAttribute('TreeCount',treeCount);root:SetAttribute('PartCount',count)
 root:SetAttribute('Ready',true);job.stage='complete';job.status='complete';job.parts=count;job.plots=#D.plots
 return root
end
return Build
