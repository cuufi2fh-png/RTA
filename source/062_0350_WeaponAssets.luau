-- Edit-time replaceable templates. Forward is -Z. Keep Handle/Muzzle/Aim contracts.
return function(C)
 local storage=game:GetService('ServerStorage')
 local assets=storage:FindFirstChild('RTAAssets') or Instance.new('Folder') assets.Name='RTAAssets' assets.Parent=storage
 local folder=assets:FindFirstChild('Weapons') or Instance.new('Folder') folder.Name='Weapons' folder.Parent=assets
 for id,def in pairs(C.Weapons) do
  if not folder:FindFirstChild(id) then
   local t=Instance.new('Tool') t.Name=id t.CanBeDropped=false t.ToolTip=def.name
   t:SetAttribute('RTAWeaponId',id) t:SetAttribute('RTAWeaponSlot',def.slot) t:SetAttribute('DisplayName',def.name)
   local length=id=='Pistol' and 1.8 or id=='SMG' and 2.8 or 4
   local h=Instance.new('Part') h.Name='Handle' h.Size=Vector3.new(.3,.65,.45) h.Color=Color3.fromRGB(35,37,41) h.Material=Enum.Material.Metal h.CanCollide=false h.Massless=true h.Parent=t
   local function piece(name,size,offset,color)
    local p=Instance.new('Part') p.Name=name p.Size=size p.CFrame=h.CFrame*CFrame.new(offset) p.Color=color p.Material=Enum.Material.Metal p.CanCollide=false p.CanTouch=false p.Massless=true p.Parent=t
    local weld=Instance.new('WeldConstraint') weld.Part0=h weld.Part1=p weld.Parent=p return p
   end
   piece('Receiver',Vector3.new(.36,.35,length*.6),Vector3.new(0,.5,-length*.2),Color3.fromRGB(47,51,57))
   piece('Barrel',Vector3.new(.18,.18,length*.65),Vector3.new(0,.5,-length*.65),Color3.fromRGB(22,25,30))
   if id~='Pistol' then piece('Stock',Vector3.new(.3,.55,.85),Vector3.new(0,.3,.65),Color3.fromRGB(61,51,40)) piece('Magazine',Vector3.new(.25,.7,.4),Vector3.new(0,-.15,-.8),Color3.fromRGB(34,37,41)) end
   local muzzle=Instance.new('Attachment') muzzle.Name='Muzzle' muzzle.Position=Vector3.new(0,.5,-length) muzzle.Parent=h
   local aim=Instance.new('Attachment') aim.Name='Aim' aim.Position=Vector3.new(0,.8,.25) aim.Parent=h
   t.Grip=CFrame.new(0,-.25,0) t.Parent=folder
  end
 end
 return folder
end
