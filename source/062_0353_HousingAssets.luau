-- Editable private-home templates; housing desk is provisional pending facade registration.
return function(C)
 local world=workspace.RTAWorld local storage=game.ServerStorage
 local templates=storage:FindFirstChild('RTAHomeTemplates') or Instance.new('Folder') templates.Name='RTAHomeTemplates' templates.Parent=storage
 local function part(parent,name,size,pos,color)
  local p=Instance.new('Part') p.Name=name p.Size=size p.Position=pos p.Anchored=true p.Color=color or Color3.fromRGB(210,205,190) p.Parent=parent return p
 end
 local point=world.Points:FindFirstChild('Housing')
 if not point then
  local base=world.Entrances.Business.Position+Vector3.new(12,0,0)
  point=part(world.Points,'Housing',Vector3.new(3,3,2),base,Color3.fromRGB(45,95,78)) point.CanCollide=false
  point:SetAttribute('RTAMenu',true) point:SetAttribute('DisplayName','주택 구매 / 내 집 입장')
  local prompt=Instance.new('ProximityPrompt') prompt.Name='Open' prompt.ActionText='주택 보기' prompt.ObjectText='RTA 부동산' prompt.HoldDuration=.2 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Parent=point
  local npc=storage.RTAShopkeeperR15:Clone() npc.Name='Housing' npc.Humanoid.DisplayName='부동산 중개인' npc:SetAttribute('RTAInvulnerable',true)
  npc.HumanoidRootPart.Anchored=true npc:PivotTo(CFrame.new(base+Vector3.new(0,1,-3))) npc.Parent=world.NPCs
  for _,p in ipairs(npc:GetDescendants()) do if p:IsA('BasePart') then p.CanCollide=false end end
 end
 for id,def in pairs(C.Homes) do if not templates:FindFirstChild(id) then
  local m=Instance.new('Model') m.Name=id m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=templates
  local w,d=def.width,def.depth local wood=Color3.fromRGB(130,102,75) local dark=Color3.fromRGB(56,65,67)
  local floor=part(m,'Floor',Vector3.new(w,1,d),Vector3.zero,wood) floor.Material=Enum.Material.WoodPlanks m.PrimaryPart=floor
  part(m,'Ceiling',Vector3.new(w,1,d),Vector3.new(0,12,0))
  for _,x in ipairs({-w/2,w/2}) do part(m,'Wall',Vector3.new(1,12,d),Vector3.new(x,6,0)) end
  for _,z in ipairs({-d/2,d/2}) do part(m,'Wall',Vector3.new(w,12,1),Vector3.new(0,6,z)) end
  -- Bedroom partition leaves a five-stud doorway at its center.
  for _,x in ipairs({-1,1}) do part(m,'BedroomPartition',Vector3.new(w/2-3,10,.5),Vector3.new(x*(w/4+1.5),5,-d/6)) end
  part(m,'BedBase',Vector3.new(10,2,7),Vector3.new(-w/4,1.5,-d/3),wood)
  part(m,'Mattress',Vector3.new(10,1,7),Vector3.new(-w/4,3,-d/3),Color3.fromRGB(220,231,233))
  part(m,'Pillow',Vector3.new(6,.5,2),Vector3.new(-w/4,3.8,-d/3-2),Color3.new(1,1,1))
  part(m,'Wardrobe',Vector3.new(5,8,3),Vector3.new(w/3,4.5,-d/3),wood)
  part(m,'SofaBase',Vector3.new(10,2.5,4),Vector3.new(-w/4,1.8,d/6),dark)
  part(m,'SofaBack',Vector3.new(10,3,1),Vector3.new(-w/4,3,d/6+2),dark)
  part(m,'CoffeeTable',Vector3.new(6,2,3),Vector3.new(-w/4,1.5,d/6-5),wood)
  part(m,'KitchenCounter',Vector3.new(4,4,10),Vector3.new(w/2-3,2.5,0),dark)
  part(m,'Sink',Vector3.new(3,.4,3),Vector3.new(w/2-3,4.7,0),Color3.fromRGB(150,170,175))
  local arrival=part(m,'Arrival',Vector3.new(1,1,1),Vector3.new(0,3,d/2-7)) arrival.Transparency=1 arrival.CanCollide=false
  local exit=part(m,'Exit',Vector3.new(6,8,.5),Vector3.new(0,4.5,d/2-.8),dark) exit.CanCollide=false
  local prompt=Instance.new('ProximityPrompt') prompt.Name='Leave' prompt.ObjectText=def.name prompt.ActionText='집에서 나가기' prompt.HoldDuration=.2 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=exit
  for _,z in ipairs({-d/4,d/4}) do
   local lamp=part(m,'Lamp',Vector3.new(6,.2,6),Vector3.new(0,11.3,z),Color3.fromRGB(255,230,180)) lamp.Material=Enum.Material.Neon
   local l=Instance.new('PointLight') l.Color=lamp.Color l.Range=32 l.Brightness=1 l.Parent=lamp
  end
 end end
 return #templates:GetChildren()
end
