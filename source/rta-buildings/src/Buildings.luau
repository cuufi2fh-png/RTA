local A=require(script.Parent.Architecture)
local V=Vector3.new
local CF=CFrame.new
local c=A.colors
local C=Color3.fromRGB
local B={}
local function shell(b,w,d,levels,h,wall,sign)
 b:b('Foundation',0,1,0,w+3,2,d+3,c.stone)
 b:b('GroundFloor',0,2.2,0,w,.5,d,c.floor,Enum.Material.Concrete)
 local sx=w/2-13;local sz=-d/2+7
 for level=0,levels-1 do
  local y=2.5+level*h
  if level>0 then b:slabHole(y-.3,w,d,sx,sz+11,22,30,c.floor)end
  for _,side in {-1,1}do
   b:b('FloorBand',0,y+h-1,side*d/2,w+2,2,1.7,wall)
   b:b('SideFloorBand',side*w/2,y+h-1,0,1.7,2,d+2,wall)
   local n=math.floor(w/14);local bay=w/n
   for i=1,n do local x=-w/2+(i-.5)*bay
    if level>0 or side<0 or math.abs(x)>14 then b:window(x,y+h/2,side*d/2,bay-2,h-3)end
   end
   local nd=math.floor(d/15);local bd=d/nd
   for i=1,nd do local z=-d/2+(i-.5)*bd;b:window(side*w/2,y+h/2,z,bd-2,h-3,90)end
   for i=0,n do local x=-w/2+i*bay;if level>0 or math.abs(x)>14 then b:b('FacadePier',x,y+h/2,side*d/2,2,h,2,wall)end end
   for i=0,nd do b:b('FacadePier',side*w/2,y+h/2,-d/2+i*bd,2,h,2,wall)end
  end
  if level<levels-1 then b:stairs(sx,y,sz,h,20)end
  for _,x in {-w*.25,w*.18}do for _,z in {-d*.2,d*.24}do b:light(x,y+h-.7,z,7,1)end end
 end
 b:door(0,2.5,d/2,16,11)
 b:b('DoorLintel',0,levels>1 and 15 or 14,d/2,28,4,2,wall)
 b:b('Canopy',0,14,d/2+3,34,.7,8,c.dark,Enum.Material.Metal)
 local top=2.5+levels*h
 b:b('FlatRoof',0,top,0,w+3,1.2,d+3,wall)
 for _,s in {-1,1}do b:b('Parapet',0,top+1.6,s*d/2,w+3,3,1.5,wall);b:b('Parapet',s*w/2,top+1.6,0,1.5,3,d+3,wall)end
 for _,x in {-w*.28,w*.28}do b:roofPlant(x,top+1,-d*.2)end
 for i=1,5 do b:b('EntryStep',0,2.5-i*.5,d/2+i*1.6,26,.5,1.65,c.stone)end
 b:part('AccessRamp',V(7,.5,25),CF(23,1.2,d/2+12)*CFrame.Angles(math.rad(-5.5),0,0),c.stone)
 if sign then b:sign('Fascia',sign,0,top-2,d/2+1.2,math.min(w*.75,65),5,c.white,c.dark)end
 return top
end
local function displayCar(b,x,y,z,id,rot)
 local source=workspace:FindFirstChild('Dealership')or game.ServerStorage.RTA_BeforeArchitecture_20261017:FindFirstChild('PreviousDealership')
 local original=source and source:FindFirstChild(id)
 if not original or not original:IsA('Model')then return end
 local m=original:Clone();m.Name='ShowroomCar_'..id
 for _,p in m:GetDescendants()do if p:IsA('LuaSourceContainer')or p:IsA('ProximityPrompt')then p:Destroy()elseif p:IsA('BasePart')then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false elseif p:IsA('Sound')then p:Destroy()end end
 local _,sz=m:GetBoundingBox();local scale=math.min(8/sz.X,18/sz.Z,6/sz.Y);m:ScaleTo(m:GetScale()*scale)
 local bc,bs=m:GetBoundingBox();local target=b.origin*CF(x,y+bs.Y/2,z)*CFrame.Angles(0,math.rad(rot or 0),0)
 m:PivotTo(target*bc:ToObjectSpace(m:GetPivot()));m:SetAttribute('DisplayOnly',true);m.Parent=b.model;task.wait()
end
local function shelf(b,x,y,z,w,kind)
 b:b('DisplayBacking',x,y+5,z,w,10,.5,c.wood,Enum.Material.Wood)
 for r=1,3 do
  b:b('DisplayShelf',x,y+r*2.7,z+.9,w,.3,2.6,c.stone)
  for i=1,math.floor(w/3.8)do local xx=x-w/2+2+i*3.3
   if kind=='PHONE'then
    b:b('DisplayPhone',xx,y+r*2.7+.8,z+.7,.8,1.4,.15,c.dark,Enum.Material.Metal,false)
    b:b('PhoneScreen',xx,y+r*2.7+.85,z+.81,.64,1.15,.03,C(67,140,158),Enum.Material.Neon,false)
   elseif kind=='SHOES'then
    b:b('ShoeSole',xx,y+r*2.7+.35,z+1.1,1.1,.25,2,C(232,228,211),Enum.Material.SmoothPlastic,false)
    b:b('ShoeUpper',xx,y+r*2.7+.7,z+.8,1,.6,1.5,i%2==0 and c.red or c.navy,Enum.Material.Fabric,false)
   else
    b:b('GearCase',xx,y+r*2.7+.6,z+.7,2.2,1.1,1.4,i%2==0 and c.navy or c.dark,Enum.Material.Metal,false)
   end
  end
 end
end
function B.retail(root,origin,id)
 local title=id=='GUN_STORE'and'GEAR'or id=='SHOE_STORE'and'SHOES'or'PHONE'
 local w=id=='GUN_STORE'and 220 or 110;local d=id=='GUN_STORE'and 86 or 96
 local b=A.new(root,id,origin);local wall=id=='PHONE_STORE'and c.stone or c.brick
 b:site(id=='GUN_STORE'and 330 or 148,id=='GUN_STORE'and 160 or 172)
 local top=shell(b,w,d,2,15,wall,title)
 local awningColor=title=='GEAR'and C(37,93,79)or title=='SHOES'and C(48,51,51)or C(40,76,129)
 for _,x in {-w*.32,w*.32}do
  b:part('FabricAwning',V(w*.27,.35,7),CF(x,13,d/2+3.1)*CFrame.Angles(math.rad(12),0,0),awningColor,Enum.Material.Fabric,false)
  b:b('AwningValance',x,12.1,d/2+6.5,w*.27,1.6,.3,awningColor,Enum.Material.Fabric,false)
 end
 b:sign('StoreName',title,0,17,d/2+1.5,50,5,c.white,awningColor)
 b:counter(0,2.5,-d/2+12,28,'CHECKOUT')
 b.model:SetAttribute('ServicePosition',b.origin:PointToWorldSpace(V(0,3,-d/2+15)))
 for _,x in {-w*.28,w*.28}do shelf(b,x,2.5,-d/2+2,26,title)end
 for _,x in {-w*.27,w*.27}do
  b:b('MerchandiseIsland',x,4.3,5,15,3.6,7,c.dark,Enum.Material.Metal)
  b:b('IslandGlassTop',x,6.25,5,15,.3,7,c.glass,Enum.Material.Glass,true,.55)
  for i=1,5 do b:b('BoxedStock',x-7+i*2.3,6.8,5,1.6,1,3,i%2==0 and c.wood or c.navy,Enum.Material.SmoothPlastic,false)end
 end
 for _,x in {-w*.28,0,w*.23}do b:desk(x,17.5,0)end
 for _,x in {-w/2+5,w/2-5}do b:planter(x,.3,d/2+17,7,5,true)end
 b:parking(0,-d/2-15,math.floor(w/12))
 b:bench(-w*.3,.3,d/2+17,13)
 return b:finish()
end
function B.police(root,origin,id)
 local b=A.new(root,id,origin*CF(-18,0,-12));b:b('PoliceForecourt',18,-.1,12,190,.6,140,c.floor,Enum.Material.Pavement)
 shell(b,118,82,3,14,c.stone,id=='POLICE_01'and'POLICE'or'POLICE ANNEX')
 b:b('NavyEntranceTower',0,34,42.8,35,26,2.6,c.navy,Enum.Material.Concrete)
 b:sign('PoliceIdentity','POLICE',0,33,44.3,30,5,c.white,c.navy)
 b:sign('PoliceShield','◇',0,41,44.3,7,7,c.white,c.navy)
 b:counter(-20,2.5,5,25,'RECEPTION',c.navy)
 for _,x in {-35,-10,15}do b:bench(x,2.5,25,9,180)end
 for l=1,2 do for _,x in {-35,-12,11}do for _,z in {-20,7}do b:desk(x,2.5+l*14,z)end end end
 -- Secure holding area in the ground floor, with genuine barred doorways.
 for i=0,2 do local x=-43+i*24
  b:b('CellBack',x,8,-37,22,11,1,c.stone)
  for _,dx in {-11,11}do b:b('CellPartition',x+dx,8,-28,1,11,19,c.stone)end
  for k=-5,5 do b:b('CellBar',x+k*2,8,-18,.2,11,.2,c.dark,Enum.Material.Metal)end
  b:b('CellBunk',x,4,-32,14,.7,5,c.navy,Enum.Material.Fabric)
 end
 b:b('GarageFloor',81,1.2,-5,45,2.4,72,c.floor)
 b:b('GarageRear',81,10,-41,46,20,1.5,c.stone)
 b:b('GarageSide',104,10,-5,1.5,20,73,c.stone)
 b:b('GarageRoof',81,21,-5,48,2,76,c.navy)
 b:b('GarageHeader',81,18,32,47,5,1.5,c.navy)
 for _,x in {59,81,104}do b:b('GaragePier',x,9,32,1.5,18,1.5,c.stone)end
 b:sign('GarageSign','PATROL',81,18.5,33,36,3,c.white,c.navy)
 b:parking(65,53,5)
 displayCar(b,70,2.5,-5,'Hellcat');displayCar(b,92,2.5,-5,'Moostang')
 for _,x in {-48,35}do b:planter(x,.3,53,8,6,true)end
 for x=-60,105,5 do b:b('SecureFenceBar',x,4,-53,.22,8,.22,c.dark,Enum.Material.Metal,false)end
 b:beam('FenceRail',V(-60,7,-53),V(105,7,-53),.25,c.dark,Enum.Material.Metal)
 return b:finish()
end
function B.auto(root,origin,id)
 local b=A.new(root,id,origin*CF(-40,0,-20))
 b:b('DealershipForecourt',40,-.1,20,338,.6,181,C(166,167,158),Enum.Material.Pavement)
 shell(b,160,98,2,20,c.white,'RTA MOTORS')
 b:b('OrangePortal',0,23,50.8,48,36,1.2,c.orange,Enum.Material.Metal)
 -- This accent is a frame, never a solid wall across the shop entrance.
 local solid=b.chunk:FindFirstChild('OrangePortal');if solid then solid:Destroy()end
 for _,x in {-25,25}do b:b('OrangeJamb',x,23,50.8,2,36,2,c.orange,Enum.Material.Metal)end
 b:b('OrangeHeader',0,40,50.8,52,2,2,c.orange,Enum.Material.Metal)
 b:sign('DealerBrand','RTA MOTORS',0,42.3,51.4,108,7,c.white,c.dark)
 b:counter(-56,2.5,20,22,'SALES')
 b.model:SetAttribute('ServicePosition',b.origin:PointToWorldSpace(V(-56,3,24)))
 for i,pos in {{-40,-10},{0,-10},{40,12}}do displayCar(b,pos[1],2.5,pos[2],({'Supra','Hellcat','Moostang'})[i],20)end
 for i,pos in {{-40,-10},{0,-10},{40,12}}do displayCar(b,pos[1],22.5,pos[2],({'lego f40','bugatti','GTR'})[i],-15)end
 b:b('ServiceFloor',126,1.2,-5,86,2.4,88,c.floor)
 b:b('ServiceBack',126,14,-49,86,28,1.5,c.white)
 b:b('ServiceEast',169,14,-5,1.5,28,88,c.white)
 b:b('ServiceRoof',126,28,-5,89,2,91,c.dark)
 b:b('ServiceHeader',126,24,39,86,8,2,c.dark)
 for _,x in {84,126,169}do b:b('ServiceBayPier',x,12,39,2,24,2,c.white)end
 b:sign('ServiceSign','SERVICE',126,24.5,40.3,68,5,c.white,c.dark)
 for _,x in {105,147}do
  for i=1,5 do b:b('RaisedRollerDoor',x,21+i*.8,38.5,38,.6,1,c.floor,Enum.Material.Metal)end
  for _,dx in {-7,7}do b:b('VehicleLiftPost',x+dx,8,-10,1.4,16,1.8,c.orange,Enum.Material.Metal)end
  b:b('ToolCabinet',x,5,-43,18,6,4,c.red,Enum.Material.Metal)
  for i=1,4 do b:b('DrawerHandle',x,2.5+i,-40.9,12,.12,.3,c.floor,Enum.Material.Metal,false)end
 end
 displayCar(b,105,3,-10,'Volvo')
 b:parking(10,76,17)
 for _,x in {-70,65,165}do b:planter(x,.3,57,8,6,true)end
 return b:finish()
end
function B.repair(root,origin,id)
 local b=A.new(root,id,origin*CF(0,0,-12));b:site(176,142)
 b:b('WorkshopFloor',0,1,0,134,2,94,c.floor)
 b:b('WorkshopBack',0,14,-47,134,28,2,c.white)
 for _,s in {-1,1}do b:b('WorkshopSide',s*67,14,0,2,28,94,c.white)end
 b:b('Roof',0,28,0,139,2,99,c.dark)
 b:b('Fascia',0,24,47,134,8,2,c.navy)
 b:sign('RepairName','RTA SERVICE',0,24,48.2,103,5,c.white,c.navy)
 for _,x in {-67,-22,22,67}do b:b('ServicePier',x,10,47,2,20,2,c.white)end
 for _,x in {-44,0,44}do
  for _,dx in {-8,8}do b:b('LiftPost',x+dx,7,0,2,14,2,c.orange,Enum.Material.Metal)end
  b:b('Workbench',x,4,-35,25,4,5,c.dark,Enum.Material.Metal)
  for i=1,5 do b:b('ToolDrawer',x,2+i*.7,-32.4,24,.55,.1,c.red,Enum.Material.Metal,false)end
  b:light(x,26,0,12,2)
 end
 displayCar(b,-44,2,0,'Supra');displayCar(b,44,2,0,'Moostang')
 b:counter(-62,2,56,12,'SERVICE')
 b:parking(20,65,8)
 b.model:SetAttribute('Entrance',b.origin:PointToWorldSpace(V(0,4,50)))
 return b:finish()
end
local function gable(b,w,d,wall)
 local base=2.5;local eave=23;local ridge=37
 b:b('Foundation',0,1,0,w+4,2,d+4,c.stone)
 b:b('TimberFloor',0,2.2,0,w,.5,d,c.wood,Enum.Material.WoodPlanks)
 for _,s in {-1,1}do
  b:b('SideWall',s*w/2,12.5,0,1.4,21,d,wall,Enum.Material.WoodPlanks)
  b:b('BackWall',0,12.5,-d/2,w,21,1.4,wall,Enum.Material.WoodPlanks)
  b:window(s*(w/4+6),11.5,d/2,w/2-14,16)
  for x=12,w/2,12 do b:b('TimberFrontPost',s*x,12.5,d/2,1.2,22,1.8,c.wood,Enum.Material.Wood)end
  b:part('StandingSeamRoof',V(math.sqrt((w/2+3)^2+14^2),1.2,d+9),CF(s*(w/4+1.5),(eave+ridge)/2,0)*CFrame.Angles(0,0,-s*math.atan2(14,w/2+3)),c.dark,Enum.Material.Metal)
  for z=-d/2-3,d/2+3,7 do
   b:beam('RoofStandingSeam',V(0,ridge+.7,z),V(s*(w/2+3),eave+.7,z),.13,C(65,72,73),Enum.Material.Metal)
  end
  b:beam('GableTimber',V(0,ridge-.7,d/2+1),V(s*w/2,eave-.6,d/2+1),.9,c.wood,Enum.Material.Wood)
 end
 -- Horizontal gable boarding, narrowing to the ridge.
 for y=23,36,1 do local width=w*(1-(y-23)/14);if width>1 then b:b('GableBoard',0,y,d/2,width,.95,.7,wall,Enum.Material.WoodPlanks);b:b('BackGableBoard',0,y,-d/2,width,.95,.7,wall,Enum.Material.WoodPlanks)end end
 b:b('GableTie',0,23,d/2+1,w,1,1,c.wood,Enum.Material.Wood)
 b:b('KingPost',0,30,d/2+1,1,14,1,c.wood,Enum.Material.Wood)
 b:door(0,2.5,d/2,12,12)
 for _,x in {-w/2,w/2}do b:planter(x,.3,d/2+10,5,5,true)end
 for i=1,5 do b:b('EntryStep',0,2.5-i*.5,d/2+2+i*1.5,22,.5,1.55,c.wood,Enum.Material.WoodPlanks)end
 for _,x in {-w*.25,w*.25}do b:light(x,21,0,10,1.5)end
end
local function displayBoat(b,x,y,z,w,d)
 b:b('BoatHull',x,y+1,z,w,2,d,c.white,Enum.Material.SmoothPlastic)
 for _,side in {-1,1}do
  local prow=b:part('BoatBow',V(2,w/2,d*.3),CF(x+side*w/4,y+1,z-d*.65)*CFrame.Angles(0,0,-side*math.pi/2),c.white,Enum.Material.SmoothPlastic,false)
  local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Wedge;mesh.Parent=prow
 end
 b:b('BoatGunwale',x,y+2.3,z,w+.3,.7,d,c.navy,Enum.Material.Metal)
 b:b('BoatDeck',x,y+2.8,z,w-.9,.4,d-.9,c.wood,Enum.Material.WoodPlanks)
 b:b('BoatConsole',x,y+4.5,z,w*.5,3,d*.2,c.white)
 b:window(x,y+6.5,z-d*.12,w*.55,2.2)
 for _,dx in {-w*.25,w*.25}do b:b('BoatSeat',x+dx,y+3.5,z+d*.22,w*.32,1.3,d*.18,c.white,Enum.Material.Fabric)end
end
function B.fishing(root,origin,id)
 local b=A.new(root,id,origin*CF(0,0,-12));b:b('FishForecourt',0,-.1,12,230,.6,144,c.floor,Enum.Material.Pavement)
 gable(b,120,78,c.teal)
 b:sign('FishingSign','FISHING',0,27,40.5,64,6,c.white,c.teal)
 b:sign('FishSalesSign','FISH BUYER  /  물고기 판매',0,20,40.5,64,3,c.white,c.teal)
 b:counter(0,2.5,-17,36,'물고기 매입',c.teal)
 b.model:SetAttribute('ServicePosition',b.origin:PointToWorldSpace(V(0,3,-12)))
 for _,x in {-34,34}do
  b:b('ColdStorage',x,7,-29,20,9,12,c.floor,Enum.Material.Metal)
  b:sign('ColdStore','FRESH CATCH',x,9,-22.8,17,2,c.dark,c.white)
  b:b('IceCounter',x,4.5,8,24,4,12,c.dark,Enum.Material.Metal)
  b:b('Ice',x,6.6,8,23,.3,11,C(204,228,230),Enum.Material.Ice,false)
  for i=1,7 do
   local fish=b:b('FishDisplay',x-11+i*2.6,7,8,2.2,.8,1,C(101+i*8,145+i*4,148+i*5),Enum.Material.SmoothPlastic,false);fish.Shape=Enum.PartType.Ball
   b:b('FishTail',x-12+i*2.6,7,8,.5,.9,1.1,c.navy,Enum.Material.SmoothPlastic,false)
  end
 end
 b:sign('PriceBoard','물고기 매입\n잡은 물고기를 판매하세요\n보유 어획물 전체 판매',-46,14,-36.8,23,9,c.white,c.dark)
 b:bench(-47,.3,55,14)
 for _,x in {-89,89}do b:planter(x,.3,35,10,7,true)end
 b:parking(0,-52,14)
 return b:finish()
end
function B.marina(root,origin,id)
 local b=A.new(root,id,origin);b:site(538,190)
 gable(b,186,114,c.teal)
 b:sign('MarinaName','MARINA',0,28,59,88,6,c.white,c.teal)
 b:counter(-57,2.5,30,25,'BOAT SALES',c.teal)
 b.model:SetAttribute('ServicePosition',b.origin:PointToWorldSpace(V(-57,3,34)))
 displayBoat(b,-43,2.6,-14,12,25);displayBoat(b,35,2.6,-8,15,32)
 for _,x in {-165,165}do
  b:b('CoveredStoragePad',x,.8,0,107,1.6,134,c.stone)
  for _,dx in {-50,50}do for _,z in {-60,60}do b:b('BoatCanopyPost',x+dx,13,z,1.4,26,1.4,c.wood,Enum.Material.Wood)end end
  b:b('BoatCanopy',x,26,0,112,1.2,142,c.dark,Enum.Material.Metal)
  displayBoat(b,x,2,0,20,42)
 end
 b:parking(0,-82,29)
 for _,x in {-248,-118,118,248}do b:planter(x,.3,70,9,7,true)end
 return b:finish()
end
function B.aviation(root,origin,id)
 local b=A.new(root,id,origin*CF(-12,0,-20));b:b('AviationApron',12,-.1,20,138,.6,102,c.floor,Enum.Material.Concrete)
 b:b('HangarFloor',0,1,0,96,2,52,c.floor)
 b:b('HangarBack',0,17,-26,96,34,1.2,c.dark,Enum.Material.Metal)
 for _,x in {-48,48}do b:b('HangarWall',x,17,0,1.2,34,52,c.dark,Enum.Material.Metal)end
 b:b('HangarRoof',0,34,0,100,1.5,56,c.dark,Enum.Material.Metal)
 b:b('HangarFascia',0,29,26,96,10,1.2,c.dark,Enum.Material.Metal)
 b:sign('AviationIdentity','RTA AVIATION',-7,29,27,76,5,c.white,c.dark)
 for _,x in {-47,47}do b:b('HangarDoorTrack',x,12,27,1.3,24,2,c.red,Enum.Material.Metal)end
 for x=-42,42,4 do b:b('CorrugatedBack',x,17,-25.2,.16,32,.3,C(68,76,80),Enum.Material.Metal,false)end
 -- Two-floor glass sales office at the side, actual open ground-floor doorway.
 for _,y in {1,15,29}do b:b('OfficeFloor',62,y,2,27,1,49,c.dark,Enum.Material.Metal)end
 for _,y in {8,22}do b:window(75,y,2,46,12,90);b:window(62,y,-22,25,12)end
 b:window(62,22,27,25,12);b:door(62,1.5,27,12,11)
 for _,x in {49,75}do for _,z in {-22,27}do b:b('RedOfficeFrame',x,15,z,1.2,29,1.2,c.red,Enum.Material.Metal)end end
 b:counter(62,1.5,6,17,'SALES',c.dark)
 b.model:SetAttribute('ServicePosition',b.origin:PointToWorldSpace(V(62,2,11)))
 -- Narrow office stair with full floor opening, no sealed upper room.
 for _,p in b.chunk:GetChildren()do if p.Name=='OfficeFloor'and math.abs(b.origin:PointToObjectSpace(p.Position).Y-15)<.1 then p.Size=V(15,1,49);p.CFrame=b.origin*CF(56,15,2)end end
 for i=1,20 do b:b('OfficeStair',68,1.5+i*.675,-20+i*1.7,8,.3,1.8,c.stone)end
 b:desk(57,15.5,-8)
 b:light(0,32,0,18,2)
 -- Static civilian demonstrator inside the hangar; the apron stays clear for purchases.
 local body=b:b('DisplayHelicopterFuselage',-6,8,-3,7,7,14,c.dark,Enum.Material.Metal,false);body.Shape=Enum.PartType.Ball
 local cockpit=b:b('HelicopterCockpit',-6,8.4,-8,6.6,5.8,7,C(73,112,127),Enum.Material.Glass,false,.25);cockpit.Shape=Enum.PartType.Ball
 b:b('HelicopterEngine',-6,11.7,-1,4.2,2.8,8,c.dark,Enum.Material.Metal,false)
 b:b('HelicopterTailBoom',-6,8,12,1.4,1.6,18,c.dark,Enum.Material.Metal,false)
 b:b('HelicopterTailFin',-6,10,21,.5,6,4,c.red,Enum.Material.Metal,false)
 b:b('HelicopterTailplane',-6,8,18,9,.4,2.2,c.dark,Enum.Material.Metal,false)
 b:cyl('HelicopterRotorMast',-6,14,-1,.35,3,c.floor,Enum.Material.Metal)
 for angle=0,270,90 do b:part('HelicopterRotorBlade',V(19,.18,.8),CF(-6,15.4,-1)*CFrame.Angles(0,math.rad(angle+20),0)*CF(9,0,0),c.dark,Enum.Material.Metal,false)end
 for _,side in {-1,1}do
  b:beam('HelicopterSkid',V(-6+side*4,2,-12),V(-6+side*4,2,7),.35,c.floor,Enum.Material.Metal)
  for _,z in {-7,4}do b:beam('LandingStrut',V(-6+side*2.5,5,z),V(-6+side*4,2,z),.3,c.floor,Enum.Material.Metal)end
  b:window(-6+side*3.4,8.5,-2,4.2,3.6,90)
  b:b('HelicopterRedStripe',-6+side*3.55,6.8,-2,.08,.65,9,c.red,Enum.Material.Metal,false)
 end
 b:b('TailRotor',-7,10,21,.25,6,.45,c.floor,Enum.Material.Metal,false)
 b:b('TailRotor',-7,10,21,.25,.45,6,c.floor,Enum.Material.Metal,false)
 -- In-apron helipad, sized to the existing plot instead of covering its road.
 local pad=b:cyl('Helipad',-7,.6,51,18,.2,c.dark,Enum.Material.Asphalt)
 for i=0,35 do local t=2*math.pi*i/36;local t2=2*math.pi*(i+1)/36;b:beam('HelipadRing',V(-7+17*math.cos(t),.75,51+17*math.sin(t)),V(-7+17*math.cos(t2),.75,51+17*math.sin(t2)),.35,c.gold,Enum.Material.SmoothPlastic)end
 for _,x in {-11,-3}do b:b('HelipadH',x,.79,51,1,.04,13,c.white,Enum.Material.SmoothPlastic,false)end
 b:b('HelipadH',-7,.79,51,8,.04,1,c.white,Enum.Material.SmoothPlastic,false)
 b.model:SetAttribute('AircraftSpawn',b.origin:PointToWorldSpace(V(-7,3,51)))
 b.model:SetAttribute('Entrance',b.origin:PointToWorldSpace(V(0,4,29)))
 return b:finish()
end
return function(root,origin,id)
 if id=='POLICE_01'or id=='POLICE_02'then return B.police(root,origin,id)
 elseif id=='GUN_STORE'or id=='PHONE_STORE'or id=='SHOE_STORE'then return B.retail(root,origin,id)
 elseif id=='CAR_DEALER'then return B.auto(root,origin,id)
 elseif id=='REPAIR_SHOP'then return B.repair(root,origin,id)
 elseif id=='FISHING_STORE'then return B.fishing(root,origin,id)
 elseif id=='BOAT_DEALER'then return B.marina(root,origin,id)
 elseif id=='HELI_DEALER'then return B.aviation(root,origin,id)end
 error('Unsupported building '..id)
end
