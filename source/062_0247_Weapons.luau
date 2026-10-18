-- ServerScriptService.RTA.Weapons. Every projectile and damage result is server-owned.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Storage=game:GetService('ServerStorage')
local W={}
function W.start(P,C,net)
 local self={} local states={} local bullets={} local rng=Random.new()
 local templates=Storage:WaitForChild('RTAAssets'):WaitForChild('Weapons')
 local damageEvent=script.Parent:FindFirstChild('DamageDealt')
 local function root(p)
  local ch=p.Character local h=ch and ch:FindFirstChildOfClass('Humanoid')
  return h and h.Health>0 and ch:FindFirstChild('HumanoidRootPart'),ch,h
 end
 local function state(p)
  local s=states[p] if not s then s={weapons={},tokens=40,at=os.clock(),sequence=0} states[p]=s end return s
 end
 local function attributes(tool,a)
  tool:SetAttribute('Ammo',a.ammo) tool:SetAttribute('ReserveAmmo',a.reserve) tool:SetAttribute('Reloading',a.reloading~=nil)
 end
 local function ownedTool(p,id)
  for _,container in ipairs({p.Character,p:FindFirstChildOfClass('Backpack')}) do
   if container then for _,t in ipairs(container:GetChildren()) do if t:IsA('Tool') and t:GetAttribute('RTAWeaponId')==id then return t end end end
  end
 end
 function self.sync(p)
  local d=P.get(p) local r=root(p) local backpack=p:FindFirstChildOfClass('Backpack')
  if not d or not r or not backpack then return end
  local s=state(p)
  for id in pairs(d.rta.ownedWeapons) do
   local def=C.Weapons[id] local template=templates:FindFirstChild(id)
   local handle=template and template:FindFirstChild('Handle') local muzzle=template and template:FindFirstChild('Muzzle',true)
   local valid=template and template:IsA('Tool') and handle and handle:IsA('BasePart') and muzzle and muzzle:IsA('Attachment')
   if def and template and not valid then warn('RTA invalid weapon template: '..id) end
   if def and valid and not ownedTool(p,id) then
    local t=template:Clone() t.CanBeDropped=false t:SetAttribute('RTAWeaponId',id) t:SetAttribute('RTAWeaponSlot',def.slot) t:SetAttribute('DisplayName',def.name)
    local a=s.weapons[id] or {ammo=def.magazine,reserve=def.reserve,last=-math.huge}
    a.reloading=nil s.weapons[id]=a attributes(t,a) t.Parent=backpack
   end
  end
 end
 function self.refill(p,id)
  local d=P.get(p) local def=C.Weapons[id] local s=states[p] local a=s and s.weapons[id]
  if not d or not def or not a or not d.rta.ownedWeapons[id] then return false,'소유한 무기를 선택하세요.' end
  if a.reserve>=def.reserve then return false,'예비 탄약이 가득 찼습니다.' end
  if d.cash<80 then return false,'탄약 비용 ₩80이 필요합니다.' end
  d.cash-=80 a.reserve=def.reserve local t=ownedTool(p,id) if t then attributes(t,a) end
  return true,'예비 탄약 보충 완료'
 end
 local function effects(pos,kind,...)
  for _,p in ipairs(Players:GetPlayers()) do local r=root(p) if r and (r.Position-pos).Magnitude<1300 then net.WeaponFX:FireClient(p,kind,...) end end
 end
 local function hit(b,result)
  local model=result.Instance
  while model and not (model:IsA('Model') and model:FindFirstChildOfClass('Humanoid')) do model=model.Parent end
  local h=model and model:FindFirstChildOfClass('Humanoid')
  if h and h.Health>0 and model~=b.character and not model:GetAttribute('RTAInvulnerable') and not model:FindFirstChildOfClass('ForceField') then
   local damage=b.damage*(result.Instance.Name=='Head' and 1.5 or 1)
   local armor=model:GetAttribute('RTAArmor') or 0
   if armor>0 then local absorbed=math.min(armor,damage*.7) model:SetAttribute('RTAArmor',armor-absorbed) damage-=absorbed end
   h:TakeDamage(damage)
   if damageEvent then damageEvent:Fire(b.player,model,damage,b.weapon) end
  end
  effects(result.Position,'Impact',result.Position,result.Normal)
 end
 net.WeaponRequest.OnServerEvent:Connect(function(p,action,id,direction,ads,sequence)
  if (p:GetAttribute('RTAInCustody')==true or (p:GetAttribute('RTAJailedUntil') or 0)>os.time()) then return end
  local s=state(p) local now=os.clock() s.tokens=math.min(40,s.tokens+(now-s.at)*20) s.at=now
  if s.tokens<1 then return end s.tokens-=1
  if action~='Fire' and action~='Reload' then return end
  if type(id)~='string' or #id>48 or not C.Weapons[id] then return end
  local d=P.get(p) local r,ch,h=root(p)
  if not d or not r or not d.rta.ownedWeapons[id] then return end
  local tool=ownedTool(p,id) local a=s.weapons[id] local def=C.Weapons[id]
  if not tool or tool.Parent~=ch or not a then return end
  if action=='Reload' then
   if a.reloading or a.ammo>=def.magazine or a.reserve<=0 then return end
   local token={} a.reloading=token attributes(tool,a)
   effects(r.Position,'Reload',r.Position,p.UserId,def.reload)
   task.delay(def.reload,function()
    if states[p]~=s or a.reloading~=token then return end
    a.reloading=nil
    local current=root(p)
    if current and tool.Parent==p.Character then local n=math.min(def.magazine-a.ammo,a.reserve) a.ammo+=n a.reserve-=n end
    if tool.Parent then attributes(tool,a) end
   end)
   return
  end
  if typeof(direction)~='Vector3' or type(ads)~='boolean' or type(sequence)~='number'
   or sequence~=sequence or sequence%1~=0 or sequence<=s.sequence or sequence>1e12 then return end
  for _,n in ipairs({direction.X,direction.Y,direction.Z}) do if n~=n or math.abs(n)>2 then return end end
  if direction.Magnitude<.9 or direction.Magnitude>1.1 then return end
  if a.reloading or a.ammo<1 or now-a.last<60/def.rpm or #bullets+def.pellets>C.Limits.bullets then return end
  local head=ch:FindFirstChild('Head') local muzzle=tool:FindFirstChild('Muzzle',true)
  if not head or not muzzle or not muzzle:IsA('Attachment') or (muzzle.WorldPosition-head.Position).Magnitude>8 then return end
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={ch} params.IgnoreWater=false
  if workspace:Raycast(head.Position,muzzle.WorldPosition-head.Position,params) then return end
  s.sequence=sequence a.ammo-=1 a.last=now attributes(tool,a)
  local origin=muzzle.WorldPosition local spread=math.rad(ads and def.adsSpread or def.spread)
  local aim=CFrame.lookAt(Vector3.zero,direction.Unit)
  for _=1,def.pellets do
   local angle=rng:NextNumber(0,math.pi*2) local radius=math.sqrt(rng:NextNumber())*math.tan(spread)
   local dir=aim:VectorToWorldSpace(Vector3.new(math.cos(angle)*radius,math.sin(angle)*radius,-1)).Unit
   table.insert(bullets,{player=p,character=ch,weapon=id,pos=origin,velocity=dir*def.speed,left=def.range,damage=def.damage,params=params})
  end
  local visualRay=direction.Unit*math.min(def.range,90) local obstacle=workspace:Raycast(origin,visualRay,params)
  effects(origin,'Shot',origin,obstacle and obstacle.Position or origin+visualRay,id,p.UserId)
 end)
 Run.Heartbeat:Connect(function(dt)
  -- Small ray segments traverse the swept path; no Touched/client hit claims.
  dt=math.min(dt,.1)
  for i=#bullets,1,-1 do
   local b=bullets[i] local delta=b.velocity*dt local distance=math.min(delta.Magnitude,b.left)
   local step=delta.Unit*distance local result=workspace:Raycast(b.pos,step,b.params)
   if result then hit(b,result) table.remove(bullets,i)
   else b.pos+=step b.left-=distance b.velocity+=Vector3.new(0,-workspace.Gravity*.12*dt,0)
    if b.left<=.01 then table.remove(bullets,i) end
   end
  end
 end)
 local function added(p)
  local s=state(p)
  s.characterConnection=p.CharacterAdded:Connect(function() task.delay(.4,function() if p.Parent then self.sync(p) end end) end)
  task.spawn(function()
   local deadline=os.clock()+30
   while p.Parent and not P.get(p) and os.clock()<deadline do task.wait(.25) end
   if p.Parent then self.sync(p) end
  end)
 end
 Players.PlayerAdded:Connect(added) for _,p in ipairs(Players:GetPlayers()) do added(p) end
 Players.PlayerRemoving:Connect(function(p) local s=states[p] if s and s.characterConnection then s.characterConnection:Disconnect() end states[p]=nil end)
 return self
end
return W
