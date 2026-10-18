-- Editable public interiors. Exterior entrance anchors are provisional until facade audit.
return function()
 local world=workspace.RTAWorld
 local folder=world:FindFirstChild('Interiors') or Instance.new('Folder') folder.Name='Interiors' folder.Parent=world
 local entries=world:FindFirstChild('Entrances') or Instance.new('Folder') entries.Name='Entrances' entries.Parent=world
 local function part(parent,name,size,cf,color,material)
  local p=Instance.new('Part') p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.Color=color p.Material=material or Enum.Material.SmoothPlastic p.Parent=parent return p
 end
 local function sign(parent,cf,text,width)
  local p=part(parent,'Sign',Vector3.new(width or 18,3,.2),cf,Color3.fromRGB(22,25,32)) p.CanCollide=false
  local gui=Instance.new('SurfaceGui') gui.Face=Enum.NormalId.Front gui.PixelsPerStud=40 gui.Parent=p
  local label=Instance.new('TextLabel') label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text=text label.TextColor3=Color3.fromRGB(255,196,57) label.TextScaled=true label.Font=Enum.Font.GothamBold label.Parent=gui
 end
 local gray=Color3.fromRGB(69,75,85) local wood=Color3.fromRGB(122,88,61) local light=Color3.fromRGB(221,225,229)
 for index,def in ipairs({{'GunShop','RTA ARMORY · 총기상점'},{'ArmorShop','PROTECTION · 방어구'},{'CarShop','RTA MOTORS · 차량 출고'},{'Business','BUSINESS CENTER · 사업체'}}) do
  local id,title=def[1],def[2] local point=world.Points[id]
  if not folder:FindFirstChild(id) then
   local exterior=point:GetAttribute('ExteriorPosition') or point.Position point:SetAttribute('ExteriorPosition',exterior)
   local m=Instance.new('Model') m.Name=id m:SetAttribute('BuildingId','RTA-FAC-'..id) m:SetAttribute('ExteriorFacadePending',true) m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic m.Parent=folder
   local origin=CFrame.new(10000+index*120,1500,10000)
   part(m,'Floor',Vector3.new(48,1,52),origin,gray,Enum.Material.Concrete)
   part(m,'Ceiling',Vector3.new(48,1,52),origin*CFrame.new(0,15,0),Color3.fromRGB(33,37,44))
   for _,x in ipairs({-24,24}) do part(m,'SideWall',Vector3.new(1,15,52),origin*CFrame.new(x,7.5,0),light) end
   for _,z in ipairs({-26,26}) do part(m,'EndWall',Vector3.new(48,15,1),origin*CFrame.new(0,7.5,z),light) end
   for _,x in ipairs({-14,14}) do
    local lamp=part(m,'CeilingPanel',Vector3.new(10,.2,16),origin*CFrame.new(x,14.3,0),Color3.new(1,1,.9),Enum.Material.Neon)
    local l=Instance.new('SurfaceLight') l.Face=Enum.NormalId.Bottom l.Brightness=2 l.Range=32 l.Angle=150 l.Parent=lamp
   end
   sign(m,origin*CFrame.new(0,10,-25.3),title,38)
   part(m,'Counter',Vector3.new(20,4,3),origin*CFrame.new(0,2.5,-13),wood,Enum.Material.Wood)
   local terminal=part(m,'CheckoutTerminal',Vector3.new(2,1.5,.3),origin*CFrame.new(7,5.2,-13),Color3.fromRGB(35,190,156)) terminal.CanCollide=false
   local spawn=part(m,'Arrival',Vector3.new(2,1,2),origin*CFrame.new(0,3,17),gray) spawn.Transparency=1 spawn.CanCollide=false
   local exit=part(m,'Exit',Vector3.new(7,8,.4),origin*CFrame.new(0,4.5,25.2),Color3.fromRGB(33,53,62)) exit.CanCollide=false
   sign(m,origin*CFrame.new(0,10,24.8)*CFrame.Angles(0,math.pi,0),'EXIT · 밖으로',15)
   local out=Instance.new('ProximityPrompt') out.Name='Leave' out.ObjectText='거리로 돌아가기' out.ActionText='나가기' out.HoldDuration=.2 out.MaxActivationDistance=10 out.RequiresLineOfSight=false out.Parent=exit
   local entry=part(entries,id,Vector3.new(5,7,1),CFrame.new(exterior+Vector3.new(0,.5,0)),Color3.fromRGB(35,43,54)) entry.CanCollide=false entry:SetAttribute('BuildingId','RTA-FAC-'..id)
   sign(entries,CFrame.new(exterior+Vector3.new(0,5,-.6)),title,20)
   local prompt=Instance.new('ProximityPrompt') prompt.Name='Enter' prompt.ObjectText=title prompt.ActionText='입장' prompt.HoldDuration=.25 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Parent=entry
   point.CFrame=origin*CFrame.new(0,3,-9)
   local npc=world.NPCs:FindFirstChild(id) if npc then npc:PivotTo(origin*CFrame.new(0,3.5,-18)*CFrame.Angles(0,math.pi,0)) end
   if id=='GunShop' then
    for i,weapon in ipairs({'Pistol','SMG','Rifle','Shotgun'}) do
     local rack=part(m,weapon..'Rack',Vector3.new(8,7,1),origin*CFrame.new(-18+(i-1)*12,5,-23.5),Color3.fromRGB(38,42,48))
     local model=game.ServerStorage.RTAAssets.Weapons[weapon]:Clone() model.Name=weapon..'Display'
     for _,v in ipairs(model:GetDescendants()) do if v:IsA('BasePart') then v.Anchored=true v.CanCollide=false v.CanTouch=false elseif v:IsA('Script') or v:IsA('LocalScript') then v:Destroy() end end
     model.Parent=m local delta=(origin*CFrame.new(-18+(i-1)*12,5,-22))*model.Handle.CFrame:Inverse()
     for _,v in ipairs(model:GetDescendants()) do if v:IsA('BasePart') then v.CFrame=delta*v.CFrame end end
    end
   elseif id=='ArmorShop' then
    for i=1,3 do
     local cf=origin*CFrame.new(-14+(i-1)*14,0,-21)
     part(m,'DisplayPlinth',Vector3.new(6,1,5),cf*CFrame.new(0,1,0),gray)
     part(m,'ArmorDisplay',Vector3.new(3.5,4,1.5),cf*CFrame.new(0,4,0),Color3.fromRGB(35+i*15,47+i*10,58+i*10),Enum.Material.Metal)
     part(m,'HelmetDisplay',Vector3.new(2.5,1.5,2),cf*CFrame.new(0,7,0),gray,Enum.Material.Metal)
    end
   elseif id=='CarShop' then
    for _,x in ipairs({-15,15}) do
     local cf=origin*CFrame.new(x,2,4)
     part(m,'ShowCarBody',Vector3.new(7,2,12),cf,Color3.fromRGB(150,35,40),Enum.Material.Metal)
     part(m,'ShowCarCabin',Vector3.new(6,2,5),cf*CFrame.new(0,2,0),Color3.fromRGB(50,65,78),Enum.Material.Glass)
     for _,dx in ipairs({-3.7,3.7}) do for _,z in ipairs({-4,4}) do local tire=part(m,'DisplayTire',Vector3.new(1,3,3),cf*CFrame.new(dx,-.5,z),Color3.fromRGB(22,23,25)) tire.Shape=Enum.PartType.Cylinder end end
    end
   else
    for _,x in ipairs({-14,14}) do for _,z in ipairs({0,11}) do
     part(m,'ConsultationDesk',Vector3.new(8,2.5,4),origin*CFrame.new(x,1.8,z),wood,Enum.Material.Wood)
     part(m,'GuestChair',Vector3.new(3,2,3),origin*CFrame.new(x,1.5,z+4),Color3.fromRGB(40,62,74))
    end end
    sign(m,origin*CFrame.new(0,7,-22),'식당 / 코피 / 공장 / 세탁소',35)
   end
  end
 end
 return #folder:GetChildren()
end
