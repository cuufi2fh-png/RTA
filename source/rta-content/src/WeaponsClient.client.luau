local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local CAS=game:GetService('ContextActionService')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer local net=RS:WaitForChild('RTA')
local C=require(net:WaitForChild('Catalog'))
local effects=require(net:WaitForChild('WeaponEffects')).new()
local Pose=require(net:WaitForChild('WeaponPose'))
local gui=player:WaitForChild('PlayerGui'):WaitForChild('RTAWeaponHUD')
gui.Enabled=false
local tool,pose,character=nil,nil,nil
local held,aiming=false,false local sequence=0 local lastShot=0 local baseFov=70
local charConnections={} local connections={}
local function connect(signal,fn) local c=signal:Connect(fn) table.insert(connections,c) return c end
local function blocked()
 local city=player.PlayerGui:FindFirstChild('RTAContentUI');if city and city.Panel.Visible then return true end
 local ui=player.PlayerGui:FindFirstChild('RTA_UI') local shop=player.PlayerGui:FindFirstChild('RTAExpansionGui')
 return UIS:GetFocusedTextBox()~=nil or (ui and (ui.Menu.Visible or ui.Phone.Visible or ui.WeaponWheel.Visible)) or (shop and shop.Panel.Visible)
end
local function setAim(value) aiming=value if pose then pose:aim(value) end end
local function scan()
 local nextTool=character and character:FindFirstChildOfClass('Tool')
 if not nextTool or not C.Weapons[nextTool:GetAttribute('RTAWeaponId')] then nextTool=nil end
 if nextTool==tool then return end
 if pose then pose:unequip() end
 if not tool and nextTool and workspace.CurrentCamera then baseFov=workspace.CurrentCamera.FieldOfView end
 tool=nextTool held=false setAim(false)
 if tool and pose then pose:equip(tool) end
 gui.Enabled=tool~=nil
 for _,name in ipairs({'RTAFire','RTAAim','RTAReload'}) do local b=CAS:GetButton(name) if b then b.Visible=tool~=nil end end
 if not tool and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=baseFov end
end
local function attach(ch)
 if not ch:WaitForChild('Humanoid',10) or player.Character~=ch then return end
 for _,c in ipairs(charConnections) do c:Disconnect() end table.clear(charConnections)
 if pose then pose:destroy() end
 character=ch pose=Pose.new(ch) tool=nil
 table.insert(charConnections,ch.ChildAdded:Connect(scan)) table.insert(charConnections,ch.ChildRemoved:Connect(scan))
 scan()
end
local function fire()
 if not tool or blocked() then return end
 local def=C.Weapons[tool:GetAttribute('RTAWeaponId')]
 if tool:GetAttribute('Reloading') or (tool:GetAttribute('Ammo') or 0)<=0 or os.clock()-lastShot<60/def.rpm+.005 then return end
 local camera=workspace.CurrentCamera local muzzle=tool:FindFirstChild('Muzzle',true)
 if not camera or not muzzle then return end
 lastShot=os.clock() sequence+=1
 local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={character}
 local result=workspace:Raycast(ray.Origin,ray.Direction*def.range,params)
 local target=result and result.Position or ray.Origin+ray.Direction*def.range
 local delta=target-muzzle.WorldPosition if delta.Magnitude<.01 then return end
 net.WeaponRequest:FireServer('Fire',tool:GetAttribute('RTAWeaponId'),delta.Unit,aiming,sequence)
end
CAS:BindAction('RTAFire',function(_,state)
 if not tool then return Enum.ContextActionResult.Pass end
 if state==Enum.UserInputState.Begin then held=true fire() elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then held=false end
 return Enum.ContextActionResult.Sink
end,true,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2)
CAS:BindAction('RTAAim',function(_,state)
 if not tool then return Enum.ContextActionResult.Pass end
 setAim(state==Enum.UserInputState.Begin and not blocked()) return Enum.ContextActionResult.Sink
end,true,Enum.UserInputType.MouseButton2,Enum.KeyCode.ButtonL2)
CAS:BindAction('RTAReload',function(_,state)
 if not tool then return Enum.ContextActionResult.Pass end
 if state==Enum.UserInputState.Begin and not blocked() then net.WeaponRequest:FireServer('Reload',tool:GetAttribute('RTAWeaponId')) end
 return Enum.ContextActionResult.Sink
end,true,Enum.KeyCode.R,Enum.KeyCode.ButtonX)
CAS:SetTitle('RTAFire','발사') CAS:SetTitle('RTAAim','조준') CAS:SetTitle('RTAReload','장전')
CAS:SetPosition('RTAFire',UDim2.new(1,-165,1,-210)) CAS:SetPosition('RTAAim',UDim2.new(1,-260,1,-160)) CAS:SetPosition('RTAReload',UDim2.new(1,-165,1,-110))
for _,name in ipairs({'RTAFire','RTAAim','RTAReload'}) do local b=CAS:GetButton(name) if b then b.Visible=false end end
connect(net.WeaponFX.OnClientEvent,function(kind,a,b,id,uid)
 if kind=='Shot' then
  effects:shot(a,b,id)
  if uid==player.UserId and tool then
   if pose then pose:fire() end local def=C.Weapons[id] local camera=workspace.CurrentCamera
   if camera and def then camera.CFrame*=CFrame.Angles(math.rad(def.recoil*(aiming and .7 or 1)),math.rad((math.random()-.5)*def.recoil*.35),0) end
  end
 elseif kind=='Impact' then effects:impact(a,b)
 elseif kind=='Reload' then effects:reload(a) if b==player.UserId and pose then pose:reload(id) end end
end)
connect(Run.RenderStepped,function(dt)
 if not tool then return end
 if blocked() then held=false setAim(false) end
 local def=C.Weapons[tool:GetAttribute('RTAWeaponId')] if not def then return end
 if held and def.automatic then fire() end
 local camera=workspace.CurrentCamera
 if camera then local target=aiming and def.adsFov or baseFov camera.FieldOfView+=(target-camera.FieldOfView)*(1-math.exp(-14*dt)) end
 gui.Crosshair.Visible=not blocked()
 gui.Ammo.Text=def.name..'  '..(tool:GetAttribute('Ammo') or 0)..' / '..(tool:GetAttribute('ReserveAmmo') or 0)..(tool:GetAttribute('Reloading') and '  장전 중' or '')
end)
connect(player.CharacterAdded,attach)
if player.Character then attach(player.Character) end
scan()
script.Destroying:Connect(function()
 for _,c in ipairs(connections) do c:Disconnect() end for _,c in ipairs(charConnections) do c:Disconnect() end
 if pose then pose:destroy() end effects:destroy()
 for _,name in ipairs({'RTAFire','RTAAim','RTAReload'}) do CAS:UnbindAction(name) end
 if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=baseFov end
end)
