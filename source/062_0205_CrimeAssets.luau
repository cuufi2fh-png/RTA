-- Edit-time robbery interaction sites. Facility interiors will move these stable IDs later.
return function(C)
 local world=workspace.RTAWorld local folder=world:FindFirstChild('Robberies') or Instance.new('Folder') folder.Name='Robberies' folder.Parent=world
 local spawn=workspace:FindFirstChildWhichIsA('SpawnLocation',true)
 local function ground(pos)
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
  local hitboxes=workspace:FindFirstChild('Hitbox_Folder') local surfaces={}
  if hitboxes then for _,v in ipairs(hitboxes:GetChildren()) do if v.Name:find('Road') or v.Name:find('Sidewalk') then table.insert(surfaces,v) end end end
  params.FilterDescendantsInstances=surfaces
  for _,delta in ipairs({Vector3.zero,Vector3.new(20,0,0),Vector3.new(-20,0,0),Vector3.new(0,0,20),Vector3.new(0,0,-20),Vector3.new(45,0,45),Vector3.new(-45,0,-45)}) do
   local hit=workspace:Raycast(pos+delta+Vector3.new(0,150,0),Vector3.new(0,-500,0),params)
   if hit and hit.Normal.Y>.75 then return hit.Position end
  end
  error('No walkable street for robbery site '..tostring(pos))
 end
 for _,def in ipairs({{'Bank',160,-120},{'Jewelry',-250,-140},{'Restaurant',250,180},{'Cafe',-200,260},{'PoliceStation',400,-300},{'MilitaryBase',-500,-450}}) do
  if not folder:FindFirstChild(def[1]) then
   local pos=ground(spawn.Position+Vector3.new(def[2],0,def[3]))
   local p=Instance.new('Part') p.Name=def[1] p.Size=Vector3.new(4,3,2) p.Anchored=true p.Color=Color3.fromRGB(48,52,63) p.Material=Enum.Material.Metal p.Position=pos+Vector3.new(0,1.5,0) p.Parent=folder
   p:SetAttribute('DisplayName',C.Robberies[def[1]].name) p:SetAttribute('RTAFacilityPendingInterior',true)
   local prompt=Instance.new('ProximityPrompt') prompt.Name='Robbery' prompt.ActionText='강도 시작 / 전리품 수령' prompt.ObjectText=C.Robberies[def[1]].name prompt.HoldDuration=1 prompt.MaxActivationDistance=14 prompt.RequiresLineOfSight=true prompt.Parent=p
   local b=Instance.new('BillboardGui') b.Size=UDim2.fromOffset(220,48) b.StudsOffset=Vector3.new(0,4,0) b.AlwaysOnTop=true b.MaxDistance=180 b.Parent=p
   local l=Instance.new('TextLabel') l.Size=UDim2.fromScale(1,1) l.BackgroundColor3=Color3.fromRGB(18,20,26) l.BackgroundTransparency=.15 l.TextColor3=Color3.fromRGB(255,106,72) l.Font=Enum.Font.GothamBold l.TextSize=18 l.Text=C.Robberies[def[1]].name..' · 강도' l.Parent=b
  end
 end
 if not world:FindFirstChild('JailSpawn') then local p=Instance.new('Part') p.Name='JailSpawn' p.Size=Vector3.new(8,1,8) p.Anchored=true p.Transparency=.5 p.Color=Color3.fromRGB(80,110,150) p.Position=folder.PoliceStation.Position+Vector3.new(12,0,0) p.Parent=world end
 return {sites=#folder:GetChildren()}
end
