local A=require(script.Parent.Architecture)
local V=Vector3.new
local CF=CFrame.new
return function(root,origin)
 local b=A.new(root,'BANK',origin);local c=A.colors
 b.model:SetAttribute('Floors',12);b.model:SetAttribute('PublicName','RTA BANK')
 b:site(300,380)
 b:b('Foundation',0,1.2,0,204,2.4,156,c.stone)
 b:b('LobbyFloor',0,2.8,0,200,.6,152,c.floor,Enum.Material.Marble)
 -- Thin inlaid bands retain the lobby's pale stone character without heavy decals.
 for x=-80,80,20 do b:b('FloorInlay',x,3.11,0,.13,.02,150,c.dark,Enum.Material.SmoothPlastic,false)end
 for z=-60,60,20 do b:b('FloorInlay',0,3.11,z,198,.02,.13,c.dark,Enum.Material.SmoothPlastic,false)end
 for _,s in {-1,1}do
  b:b('Plinth',s*101,2,0,2,4,154,c.stone)
  b:b('PodiumUpperCornice',0,32.3,s*76,202,3,2,c.stone)
  b:b('PodiumSideCornice',s*100,32.3,0,2,3,154,c.stone)
  b:b('GroundWindowSill',s*60,4,76,80,2,2,c.stone)
  for x=30,90,20 do b:window(s*x,16.8,76,18,23.4)end
  for z=-60,60,20 do b:window(s*100,17,z,18,26,90)end
  if s==1 then for x=-90,90,20 do b:window(x,17,-76,18,26)end end
  for z=-70,70,20 do b:b('LimestonePier',s*100,17.8,z,3,30,3,c.stone)end
  for x=-100,100,20 do if math.abs(x)>1 then b:b('LimestonePier',x,17.8,s*76,3,30,3,c.stone)end end
 end
 -- Curved stone corners and projecting entrance canopy follow the approved podium.
 for _,x in {-99,99}do for _,z in {-75,75}do b:cyl('RoundedCornerPier',x,17.5,z,2.5,31,c.stone)end end
 b:door(0,3.1,76,24,13,nil)
 b:window(0,25,76,36,11)
 b:b('EntranceCanopy',0,17.2,81,45,1.2,13,c.stone)
 b:sign('BankWordmark','RTA BANK',0,29,77.8,67,5.6,c.dark,c.stone)
 for i=1,6 do b:b('EntranceStep',0,3.1-i*.5,77+i*2,40,.5,2.1,c.stone)end
 b:part('EntranceRamp',V(9,.6,30),CF(33,1.6,88)*CFrame.Angles(math.rad(-5.9),0,0),c.stone)
 b:rail(V(38,0,102),V(38,3,74))
 b:b('PodiumRoof',0,33,0,203,1.2,155,c.stone)
 -- Replace the center of the roof with slabs having a real stair opening.
 for _,p in b.chunk:GetChildren()do if p.Name=='PodiumRoof'then p:Destroy()end end
 b:slabHole(33.7,200,152,36,-17,24,29,c.stone)
 -- Double-height lobby and mezzanine.
 b:batch('Lobby')
 b:b('MezzanineRear',0,18.2,-51,197,.7,48,c.floor,Enum.Material.Marble)
 b:b('MezzanineWest',-88,18.2,24,21,.7,102,c.floor,Enum.Material.Marble)
 b:b('MezzanineEast',88,18.2,37,21,.7,76,c.floor,Enum.Material.Marble)
 b:rail(V(-77,18.6,-27),V(77,18.6,-27));b:rail(V(-77,18.6,-27),V(-77,18.6,74));b:rail(V(77,18.6,4),V(77,18.6,74))
 b:stairs(86,3.1,-28,15.5,20)
 b:stairs(36,18.6,-28,15.4,20)
 for _,x in {-65,65}do b:cyl('LobbyColumn',x,18,0,1.3,30,c.dark,Enum.Material.Metal)end
 for i=-1,1 do b:counter(i*18,3.1,-4,15,'BANK',c.stone)end
 b:b('ReceptionBackdrop',0,12,-9,58,18,1.1,c.stone)
 b:sign('InteriorWordmark','RTA BANK',0,17,-8.25,32,4.8,c.dark,c.stone)
 for _,x in {-68,-50}do b:bench(x,3.1,46,13)end
 for _,pos in {{-84,62},{84,62},{-65,-9},{62,-10},{-85,-65}}do b:planter(pos[1],3.1,pos[2],5,5,true)end
 for i=1,3 do local x=52+(i-1)*11
  b:b('ATMBody',x,7,44,7,8,4,c.dark,Enum.Material.Metal)
  b:sign('ATMDisplay','RTA\nATM',x,8.2,46.1,4.3,3,Color3.fromRGB(173,222,232),c.navy)
  b:b('ATMKeypad',x,5.9,46.3,3,.3,1,c.floor,Enum.Material.Metal,false)
  b:b('ATMSlot',x,4.7,46.12,2.8,.28,.2,c.dark,Enum.Material.Metal,false)
  local service=b:b('BankService',x,7,47,5,5,2,c.dark,nil,false,1);service:SetAttribute('BankService',true)
  local pp=Instance.new('ProximityPrompt');pp.ActionText='은행 이용';pp.ObjectText='RTA ATM';pp.MaxActivationDistance=10;pp.RequiresLineOfSight=true;pp.Parent=service
 end
 for _,x in {-40,0,40}do
  for _,z in {24,56}do
   b:b('PendantStem',x,28,z,.12,9,.12,c.dark,Enum.Material.Metal,false)
   b:cyl('PendantLamp',x,23,z,.65,3,c.gold,Enum.Material.Metal)
   b:light(x,21.5,z,1.1,1.1)
  end
 end
 for _,x in {-88,88}do for _,z in {-48,5,50}do b:light(x,31.7,z,9,1.5)end end
 -- A real back-of-house vault, reached directly through the bank.
 b:batch('VaultInterior')
 b:b('VaultFloor',-48,3.2,-50,71,.4,49,c.floor,Enum.Material.Marble)
 b:b('VaultBack',-48,13,-74,73,20,1.4,c.stone)
 b:b('VaultWest',-84,13,-50,1.4,20,49,c.stone)
 b:b('VaultEast',-12,13,-50,1.4,20,49,c.stone)
 b:b('VaultFrontLeft',-72,13,-26,24,20,1.4,c.stone)
 b:b('VaultFrontRight',-25,13,-26,26,20,1.4,c.stone)
 b:b('VaultLintel',-49,21,-26,24,4,2.8,c.dark,Enum.Material.Metal)
 b:b('VaultThreshold',-49,3.5,-26,23,.5,4,c.dark,Enum.Material.Metal)
 for _,x in {-61,-37}do b:b('VaultDoorFrame',x,12,-26,1.5,17,3,c.dark,Enum.Material.Metal)end
 b:sign('VaultSign','VAULT',-49,23.8,-24.8,23,3,c.white,c.dark)
 -- The heavy circular door is open against its right jamb, leaving a 22-stud route.
 local door=b:part('OpenVaultDoor',V(1.7,16,16),CF(-34,11.5,-19)*CFrame.Angles(0,math.rad(10),0),c.dark,Enum.Material.Metal);door.Shape=Enum.PartType.Cylinder
 for radius=5,7,2 do
  for i=0,15 do local t=2*math.pi*i/16
   b:b('VaultBolt',-32.9,11.5+math.sin(t)*radius,-19+math.cos(t)*radius,.5,.5,.5,c.gold,Enum.Material.Metal,false)
  end
 end
 b:sign('VaultKeypad','● ● ●\n1 2 3\n4 5 6',-65,8,-24.9,2,3,c.white,c.dark)
 for row=1,5 do for col=1,12 do local x=-80+col*5
  b:b('SafeDepositBox',x,4+row*2.1,-72.9,4.7,1.9,.8,c.floor,Enum.Material.Metal)
  b:b('SafeKeyhole',x+1.5,4+row*2.1,-72.4,.25,.35,.15,c.gold,Enum.Material.Metal,false)
 end end
 for _,x in {-66,-36}do
  b:b('VaultTable',x,6.1,-49,15,.6,8,c.dark,Enum.Material.Metal)
  for _,dx in {-6,6}do for _,dz in {-3,3}do b:b('VaultTableLeg',x+dx,4.6,-49+dz,.5,3,.5,c.dark,Enum.Material.Metal)end end
  for ix=1,4 do for iz=1,3 do for layer=0,1 do
   b:b(x==-66 and'BundledCash'or'GoldBars',x-7+ix*2.7,6.8+layer*.7,-53+iz*2,2.4,.65,1.4,x==-66 and Color3.fromRGB(115,147,108)or c.gold,x==-66 and Enum.Material.SmoothPlastic or Enum.Material.Metal,false)
   if x==-66 then b:b('CashBand',x-7+ix*2.7,7.15+layer*.7,-53+iz*2,.4,.035,1.42,c.white,Enum.Material.SmoothPlastic,false)end
  end end end
 end
 b:light(-49,17.6,-48,10,2)
 b.model:SetAttribute('VaultPoint',b.origin:PointToWorldSpace(V(-49,6.3,-36)))
 -- Twelve occupied levels: public podium plus ten office floors above.
 for level=0,9 do
  b:batch('OfficeFloor_'..(level+3))
  local y=34+level*14
  b:slabHole(y,112,92,36,-17,24,29,c.floor)
  for _,s in {-1,1}do
   b:b('TowerFloorBand',0,y+1,s*46,114,2,1.5,c.dark,Enum.Material.Metal)
   b:b('TowerSideFloorBand',s*56,y+1,0,1.5,2,94,c.dark,Enum.Material.Metal)
   for x=-48,48,16 do b:window(x,y+7.5,s*46,13.2,11.5);b:b('VerticalStoneFin',x-7.7,y+7.2,s*47,2,14.4,3,c.stone)end
   for z=-38,38,19 do b:window(s*56,y+7.5,z,16.5,11.5,90);b:b('SideStoneFin',s*57,y+7.2,z-9,3,14.4,2,c.stone)end
  end
  if level<9 then b:stairs(36,y+.3,-28,14,20)end
  b:rail(V(24,y+.3,-31),V(24,y+.3,-2))
  if level%3==0 then
   b:b('MeetingTable',-19,y+3,4,31,.5,10,c.wood,Enum.Material.Wood)
   for x=-30,-6,8 do for _,z in {-4,12}do b:bench(x,y+.3,z,5,z<0 and 180 or 0)end end
   b:sign('BoardRoom','RTA  /  '..(level+3),-20,y+8,-43,30,4,c.white,c.navy)
  else for _,x in {-37,-14,9}do for _,z in {-24,10}do b:desk(x,y+.3,z)end end end
  b:sign('FloorNumber','LEVEL '..(level+3),49,y+6,-42,9,2,c.dark,c.stone)
  b:planter(-48,y+.3,34,4,4,true)
  b:light(-20,y+13.4,5,24,1.2)
 end
 b:batch('RoofAndPlaza')
 b:b('TowerRoof',0,174.7,0,116,1.5,96,c.stone)
 for _,s in {-1,1}do b:b('Crown',0,177,s*47,116,4,2,c.stone);b:b('Crown',s*57,177,0,2,4,96,c.stone)end
 for _,x in {-24,0,24}do b:roofPlant(x,175.5,-12)end
 for _,x in {-75,-45,45,75}do b:planter(x,.3,108,12,6,true);b:bench(x,.3,121,13,180)end
 for _,x in {-128,128}do for _,z in {-130,-70,-10,50,130}do b:planter(x,.3,z,7,10,true)end end
 b:parking(0,-143,10)
 b:sign('StreetBank','RTA BANK',112,8,125,30,6,c.dark,c.stone)
 return b:finish()
end
