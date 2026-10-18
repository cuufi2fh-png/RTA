local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Storage=game:GetService('ServerStorage')
local W={}
function W.start(P,C,net,notify)
 local Jail=require(script.Parent.Jail).start()
 local state={} local npcs={} local serial=0 local bombs={} local lastArrest={}
 local world=workspace.RTAWorld local folder=world:FindFirstChild('Responders') or Instance.new('Folder') folder.Name='Responders' folder.Parent=world
 local self={}
 local function alive(p)
  local ch=p.Character local h=ch and ch:FindFirstChildOfClass('Humanoid') local r=ch and ch:FindFirstChild('HumanoidRootPart')
  if h and h.Health>0 and r then return r,h,ch end
 end
 local function send(p)
  local s=state[p] local level=s and s.level or 0 p:SetAttribute('RTAWanted',level)
  net.CrimeState:FireClient(p,{wanted=level,responder=level>=5 and '폭격' or level>=4 and '군인' or level>0 and '경찰' or '없음'})
 end
 function self.level(p) return state[p] and state[p].level or 0 end
 function self.raise(p,minimum,reason)
  local r=alive(p) if not r then return end
  local s=state[p] or {level=0,lastDispatch=0,lastBomb=0} state[p]=s
  s.level=math.clamp(math.max(s.level,minimum),0,5) s.lastCrime=os.clock() s.lastSeen=os.clock() send(p)
  if reason then notify(p,reason) end
 end
 function self.clear(p)
  state[p]=nil if p.Parent then send(p) end
  for id,b in pairs(bombs) do if b.target==p then bombs[id]=nil net.CrimeFX:FireAllClients('Cancel',id) end end
  for m,n in pairs(npcs) do if n.target==p then m:Destroy() npcs[m]=nil end end
 end
 local function ground(pos,excluded)
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances=excluded or {folder}
  return workspace:Raycast(pos+Vector3.new(0,50,0),Vector3.new(0,-160,0),params)
 end
 local function spawnNPC(p,military)
  local r=alive(p) if not r then return end
  local count=0 for _ in pairs(npcs) do count+=1 end if count>=C.Limits.activeNPCs then return end
  local angle=math.random()*math.pi*2 local hit=ground(r.Position+Vector3.new(math.cos(angle)*65,0,math.sin(angle)*65),{folder,p.Character}) local interior=p:GetAttribute('RTAInterior') local room=interior and world.Interiors:FindFirstChild(interior)
  if room then
   local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={room.Floor}
   local pos=room.Arrival.Position+Vector3.new(math.cos(angle)*10,5,math.sin(angle)*4-6)
   hit=workspace:Raycast(pos,Vector3.new(0,-20,0),params)
  end
  if not hit then return end
  local m=Storage.RTAShopkeeperR15:Clone() m.Name=military and 'MilitaryResponder' or 'PoliceResponder' m:SetAttribute('RTALaw',military and 'Military' or 'Police') m:SetAttribute('TargetUserId',p.UserId)
  m:SetAttribute('RTAInvulnerable',nil) local h=m.Humanoid h.DisplayName=military and '군인' or '경찰' h.MaxHealth=military and 180 or 100 h.Health=h.MaxHealth h.WalkSpeed=military and 18 or 16
  for _,v in ipairs(m:GetDescendants()) do if v:IsA('BasePart') then v.Anchored=false end end
  local colors=m:FindFirstChildOfClass('BodyColors') if colors then colors.TorsoColor3=military and Color3.fromRGB(65,80,49) or Color3.fromRGB(25,44,82) end
  m:PivotTo(CFrame.new(hit.Position+Vector3.new(0,3,0))) m.Parent=folder m.HumanoidRootPart:SetNetworkOwner(nil)
  local gun=Storage.RTAAssets.Weapons[military and 'Rifle' or 'Pistol']:Clone() gun.Parent=m h:EquipTool(gun)
  npcs[m]={target=p,military=military,shot=0,move=0,born=os.clock()}
 end
 function self.dispatch(p,count)
  local military=self.level(p)>=4 for _=1,math.min(count,8) do spawnNPC(p,military) end
 end
 function self.arrest(officer,userId)
  local target=Players:GetPlayerByUserId(userId) local d=P.get(officer) local level=target and self.level(target) or 0
  if officer:GetAttribute('RTAInCustody') or not d or level==0 or officer==target or self.level(officer)>0 then return false,'체포할 수 없는 대상입니다.' end
  if (level<=3 and d.job~='Police') or (level>=4 and d.job~='Military') then return false,'수배 단계에 맞는 경찰/군인 직업이 필요합니다.' end
  local a=alive(officer) local b,h,ch=alive(target)
  if not a or not b or (a.Position-b.Position).Magnitude>8 then return false,'대상에게 8스튜드 이내로 접근하세요.' end
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={officer.Character}
  local hit=workspace:Raycast(a.Position,b.Position-a.Position,params) if hit and not hit.Instance:IsDescendantOf(ch) then return false,'벽 뒤의 대상은 체포할 수 없습니다.' end
  if h.Health>35 and ch:FindFirstChildOfClass('Tool') then return false,'무장한 대상의 체력을 35 이하로 낮추세요.' end
  local td=P.get(target) if not td then return false,'대상 데이터가 없습니다.' end
  local jail=world:FindFirstChild('JailSpawn') if not jail then return false,'구금 시설을 찾을 수 없습니다.' end
  td.rta.stolenGoods=0 self.clear(target) Jail.detain(target,jail.CFrame,20,'PoliceStation')
  local pair=tostring(officer.UserId)..':'..userId local now=os.clock()
  if now-(lastArrest[pair] or -1000)>120 and d.cash+300<=C.Limits.balance then d.cash+=300 lastArrest[pair]=now end
  notify(target,'체포되었습니다. 20초 구금 / 미세탁 물품 압수') return true,'체포 완료'
 end
 local damage=script.Parent:WaitForChild('DamageDealt')
 damage.Event:Connect(function(attacker,victim)
  if not attacker or not attacker.Parent then return end
  local d=P.get(attacker) if not d then return end
  local vp=Players:GetPlayerFromCharacter(victim)
  local lawful=self.level(attacker)==0 and ((d.job=='Police' and vp and self.level(vp)>0 and self.level(vp)<=3) or (d.job=='Military' and vp and self.level(vp)>=4))
  if not lawful then local s=state[attacker] if not s or os.clock()-(s.lastGunCrime or -100)>5 then self.raise(attacker,self.level(attacker)+1,'총격 신고로 수배 단계가 올랐습니다.') if state[attacker] then state[attacker].lastGunCrime=os.clock() end end end
 end)
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.25 then return end elapsed=0 local now=os.clock()
  for p,s in pairs(state) do
   local r,h,ch=alive(p)
   if not r or not p.Parent then self.clear(p) continue end
   local count=0 for _,n in pairs(npcs) do if n.target==p then count+=1 end end
   if (now-s.lastCrime<45 or now-(s.lastSeen or s.lastCrime)<12) and now-s.lastDispatch>12 and count<math.min(4,s.level) then s.lastDispatch=now self.dispatch(p,math.min(4,s.level)-count) end
   if s.level>=5 and now-s.lastBomb>=C.Wanted.bombInterval then
    s.lastBomb=now local hit=ground(r.Position,{folder,ch})
    local bombCount=0 for _ in pairs(bombs) do bombCount+=1 end
    if hit and bombCount<6 then serial+=1 local id='bomb'..serial local position=hit.Position local radius=C.Wanted.bombRadius local due=now+C.Wanted.bombWarning
     bombs[id]={position=position,radius=radius,due=due,target=p} net.CrimeFX:FireAllClients('Warning',id,position,radius,C.Wanted.bombWarning)
    end
   end
   if now-s.lastCrime>60 and now-(s.lastSeen or s.lastCrime)>25 then s.level-=1 s.lastCrime=now-45 if s.level<=0 then self.clear(p) else send(p) end end
  end
  for m,n in pairs(npcs) do
   local r,h,ch=alive(n.target) local nh=m:FindFirstChildOfClass('Humanoid') local nr=m:FindFirstChild('HumanoidRootPart')
   if not r or not m.Parent or not nh or nh.Health<=0 or not nr or self.level(n.target)==0 or n.military~=(self.level(n.target)>=4) or (nr.Position-r.Position).Magnitude>600 or now-n.born>180 then m:Destroy() npcs[m]=nil continue end
   if now-n.move>1 then n.move=now nh:MoveTo(r.Position) end
   local distance=(nr.Position-r.Position).Magnitude
   if distance<110 and now-n.shot>(n.military and .9 or 1.4) then
    n.shot=now local head=m:FindFirstChild('Head') local origin=head and head.Position or nr.Position
    local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={m}
    local result=workspace:Raycast(origin,r.Position-origin,params)
    if result and result.Instance:IsDescendantOf(ch) then
     if state[n.target] then state[n.target].lastSeen=now end
     net.WeaponFX:FireAllClients('Shot',origin,r.Position,n.military and 'Rifle' or 'Pistol',0)
     if math.random()<.65 and not ch:FindFirstChildOfClass('ForceField') then
      local amount=n.military and 10 or 6 local armor=ch:GetAttribute('RTAArmor') or 0 local absorbed=math.min(armor,amount*.7) ch:SetAttribute('RTAArmor',armor-absorbed) h:TakeDamage(amount-absorbed)
     end
    end
   end
  end
  for id,b in pairs(bombs) do if now>=b.due then
   bombs[id]=nil net.CrimeFX:FireAllClients('Explosion',id,b.position,b.radius)
   for _,p in ipairs(Players:GetPlayers()) do local r,h,ch=alive(p)
    if r and (r.Position-b.position).Magnitude<=b.radius and not ch:FindFirstChildOfClass('ForceField') then
     local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={ch,folder}
     if not workspace:Raycast(b.position+Vector3.new(0,2,0),r.Position-(b.position+Vector3.new(0,2,0)),params) then h:TakeDamage(70) end
    end
   end
  end end
 end)
 Players.PlayerRemoving:Connect(function(p) self.clear(p) for key in pairs(lastArrest) do if key:match('^'..p.UserId..':') or key:match(':'..p.UserId..'$') then lastArrest[key]=nil end end end)
 return self
end
return W
