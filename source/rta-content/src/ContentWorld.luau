-- Runtime presentation for player-owned plots. All authoring plots remain empty in Edit mode.
local W={}
local V=Vector3.new
local C=Color3.fromRGB
function W.start(Catalog)
 local map=workspace:WaitForChild('RTA_IslandMap');local plots=map:WaitForChild('Plots');local dynamic=Instance.new('Folder');dynamic.Name='PlayerContent';dynamic.Parent=map
 local homes,farms,businesses={},{},{}
 local self={map=map,plots=plots,dynamic=dynamic}
 local function part(parent,name,size,cf,color,material)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
 end
 function self.plot(id)
  if type(id)~='string'then return nil end
  for _,p in plots:GetChildren()do if p:GetAttribute('PlotId')==id then return p end end
 end
 function self.claim(player,kind,id)
  local plot=self.plot(id);local t=plot and plot:GetAttribute('PlotType');local wanted=kind=='Home'and(t=='Home'or t=='LargeHome')or kind==t
  if not plot or not wanted then return false,'해당 용도의 부지를 선택하세요.'end
  local owner=plot:GetAttribute('OwnerUserId');if owner~=0 and owner~=player.UserId then return false,'다른 플레이어의 부지입니다.'end
  for _,other in plots:GetChildren()do if other~=plot and other:GetAttribute('OwnerUserId')==player.UserId then local ot=other:GetAttribute('PlotType');if ot==kind or(kind=='Home'and(ot=='Home'or ot=='LargeHome'))then return false,'이미 같은 종류의 부지를 보유하고 있습니다.'end end end
  plot:SetAttribute('OwnerUserId',player.UserId);return true,'부지를 배정했습니다.'
 end
 function self.ownedPlot(player,kind)
  for _,p in plots:GetChildren()do local k=p:GetAttribute('PlotType');if p:GetAttribute('OwnerUserId')==player.UserId and(k==kind or(kind=='Home'and(k=='Home'or k=='LargeHome')))then return p end end
 end
 function self.home(player,id)
  local p=self.ownedPlot(player,'Home');local def=Catalog.Homes[id]
  if not p or not def then return false,'주거 플롯을 먼저 배정받으세요.'end
  if def.large and p:GetAttribute('PlotType')~='LargeHome'then return false,'중앙 대형 주택 플롯이 필요합니다.'end
  if homes[player]then homes[player]:Destroy()end
  local model=Instance.new('Model');model.Name=def.name..'_'..player.UserId;model:SetAttribute('OwnerUserId',player.UserId);model:SetAttribute('HouseId',id)
  local cf=p.BuildArea.CFrame*CFrame.new(0,.6,0);local w,d=def.width,def.depth;local h=12;local wall=C(225,220,205);local trim=C(63,76,78)
  if def.style%3==0 then wall=C(187,137,107)elseif def.style%3==1 then wall=C(207,215,211)end
  local function b(n,size,offset,col,mat)return part(model,n,size,cf*CFrame.new(offset),col or wall,mat)end
  b('Foundation',V(w+4,1.2,d+4),V(0,0,0),C(151,151,140),Enum.Material.Concrete)
  for level=0,def.levels-1 do
   local y=level*h
   b('Floor',V(w,.7,d),V(0,y+.8,0),C(163,135,99),Enum.Material.WoodPlanks)
   b('BackWall',V(w,h,.6),V(0,y+h/2,-d/2))
   b('WestWall',V(.6,h,d),V(-w/2,y+h/2,0));b('EastWall',V(.6,h,d),V(w/2,y+h/2,0))
   local door=6
   for _,side in {-1,1}do b('FrontWall',V((w-door)/2,h,.6),V(side*(w+door)/4,y+h/2,d/2))end
   b('DoorLintel',V(door,3,.6),V(0,y+h-1.5,d/2),trim)
   -- Windows are physically open side-wall bays in the front facade, no teleport interiors.
   if level<def.levels-1 then
    -- Open-air stair along the side keeps all floors reachable without sealed holes.
    for step=1,16 do b('Stair',V(7,.7,2.2),V(w/2-4,y+step*h/16,-d/2+step*2),trim,Enum.Material.Concrete)end
   end
   local front=b('Balcony',V(w+3,.5,7),V(0,y+.5,d/2+3),C(175,181,177),Enum.Material.Concrete)
   for _,side in {-1,1}do b('WindowGlass',V(7,5,.15),V(side*w*.3,y+7,d/2+.4),C(112,159,173),Enum.Material.Glass).Transparency=.4 end
  end
  -- Upper floors need a real stair opening: replace a small side section of each upper slab.
  for _,v in model:GetChildren()do if v.Name=='Floor'and v.Position.Y>cf.Position.Y+3 then local y=cf:PointToObjectSpace(v.Position).Y;v:Destroy();b('UpperFloor',V(w-9,.7,d),V(-4.5,y,0),C(163,135,99),Enum.Material.WoodPlanks);b('Landing',V(9,.7,math.max(3,d-34)),V(w/2-4.5,y,d/2-(d-34)/2),C(163,135,99),Enum.Material.WoodPlanks)end end
  b('Roof',V(w+4,1.1,d+5),V(0,def.levels*h+.5,0),trim,Enum.Material.Slate)
  b('SofaSeat',V(8,1.2,3),V(-w*.25,2,0),C(98,127,128),Enum.Material.Fabric)
  b('SofaBack',V(8,3,.7),V(-w*.25,3,-1.4),C(98,127,128),Enum.Material.Fabric)
  b('TableTop',V(6,.5,4),V(-w*.25,2.5,6),C(122,98,72),Enum.Material.Wood)
  b('KitchenCounter',V(12,3,3),V(w*.25,2.5,-d/2+3),C(202,201,186),Enum.Material.Marble)
  b('BedBase',V(7,1,9),V(w*.25,1.5,3),C(124,95,69),Enum.Material.Wood)
  b('Mattress',V(6.6,.7,8.6),V(w*.25,2.3,3),C(232,230,215),Enum.Material.Fabric)
  for i=1,4 do b('FrontStep',V(8,.5,2),V(0,.5-i*.12,d/2+4+i*2),C(177,178,164),Enum.Material.Concrete)end
  model.Parent=dynamic;homes[player]=model;return true,def.name..' 배치 완료'
 end
 function self.garden(player,data)
  local plot=self.ownedPlot(player,'Farm');if not plot then return end
  if farms[player]then farms[player]:Destroy()end
  local model=Instance.new('Model');model.Name='Farm_'..player.UserId;model.Parent=dynamic;farms[player]=model
  local width=plot.BuildArea.Size.X;local depth=plot.BuildArea.Size.Z;local cf=plot.BuildArea.CFrame
  for i=1,12 do local x=((i-1)%3-1)*width*.27;local z=(math.floor((i-1)/3)-1.5)*depth*.2;local p=data.garden[tostring(i)]
   local soil=part(model,'Bed_'..i,V(width*.22,.6,depth*.16),cf*CFrame.new(x,.8,z),C(100,71,45),Enum.Material.Ground);soil:SetAttribute('FarmSlot',i)
   if p then local ready=p.readyAt<=os.time();local h=p.crop=='MoneyTree'and 18 or(ready and 7 or 3)
    part(model,'Stem',V(1,h,1),cf*CFrame.new(x,h/2+1,z),C(93,117,52),Enum.Material.Wood)
    local leaf=part(model,'Crop_'..p.crop,V(h*.8,h*.7,h*.8),cf*CFrame.new(x,h*.85+1,z),ready and C(174,168,70)or C(86,148,65),Enum.Material.Grass);leaf.Shape=Enum.PartType.Ball
   end
  end
 end
 function self.business(player,id)
  local p=self.ownedPlot(player,'Business');if not p then return false,'사업 플롯을 먼저 배정받으세요.'end
  if businesses[player]then businesses[player]:Destroy()end
  local m=Instance.new('Model');m.Name='BusinessEquipment_'..player.UserId;local cf=p.BuildArea.CFrame
  -- Replaceable equipment only; the user authors the permanent commercial buildings.
  local base=part(m,'WorkCounter',V(18,4,5),cf*CFrame.new(0,2.4,0),C(78,97,100),Enum.Material.Metal)
  if id=='Factory'then for i=1,3 do part(m,'Machine',V(6,7,7),cf*CFrame.new((i-2)*10,4,-12),C(151,164,164),Enum.Material.Metal)end
  elseif id=='Laundromat'then for i=1,3 do part(m,'Washer',V(6,6,5),cf*CFrame.new((i-2)*8,3.4,-8),C(210,218,214),Enum.Material.Metal);local door=part(m,'WasherDoor',V(3.8,3.8,.2),cf*CFrame.new((i-2)*8,3.4,-5.4),C(81,126,148),Enum.Material.Glass);door.Shape=Enum.PartType.Ball end
  elseif id=='Cafe'then part(m,'CoffeeMachine',V(4,3,3),cf*CFrame.new(0,6,0),C(60,64,65),Enum.Material.Metal)end
  base:SetAttribute('BusinessType',id);m.Parent=dynamic;businesses[player]=m;return true,'사업 설비 배치 완료'
 end
 function self.release(player)
  for _,set in {homes,farms,businesses}do if set[player]then set[player]:Destroy();set[player]=nil end end
  for _,p in plots:GetChildren()do if p:GetAttribute('OwnerUserId')==player.UserId then p:SetAttribute('OwnerUserId',0)end end
 end
 return self
end
return W
