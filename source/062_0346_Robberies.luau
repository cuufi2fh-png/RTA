local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local R={}
function R.start(P,C,T,W,net,notify)
 local runs={} local owners={} local cooldown={} local sites=workspace.RTAWorld:WaitForChild('Robberies')
 local self={} local promptAt={}
 local function alive(p)
  local ch=p.Character local h=ch and ch:FindFirstChildOfClass('Humanoid') return h and h.Health>0 and ch:FindFirstChild('HumanoidRootPart')
 end
 local function send(p,run,message)
  if p.Parent~=Players then return end
  local point=run and sites:FindFirstChild(run.id)
  net.CrimeState:FireClient(p,{robbery=run and {id=run.id,name=C.Robberies[run.id].name,stage=run.stage,remaining=math.max(0,math.ceil(run.ready-os.clock())),position=run.stage=='ESCAPE' and (point:GetAttribute('ExteriorPosition') or point.Position) or point.Position} or false,message=message or ''})
 end
 function self.cancel(p,message)
  local run=runs[p] if run then owners[run.id]=nil runs[p]=nil send(p,nil,message or '강도 실패') end
 end
 function self.start(p,id)
  local d=P.get(p) local r=alive(p) local def=C.Robberies[id] local point=def and sites:FindFirstChild(id)
  if not d or not r or not point or (r.Position-point.Position).Magnitude>18 then return false,'강도 장소의 금고 가까이에서 시작하세요.' end
  if d.job=='Police' or d.job=='Military' or (p:GetAttribute('RTAInCustody')==true or (p:GetAttribute('RTAJailedUntil') or 0)>os.time()) then return false,'현재 신분으로 강도를 시작할 수 없습니다.' end
  if runs[p] or owners[id] then return false,'이미 진행 중인 강도입니다.' end
  if os.clock()<(cooldown[id] or 0) then return false,'금고가 복구 중입니다.' end
  local tool=p.Character:FindFirstChildOfClass('Tool') if not tool or not C.Weapons[tool:GetAttribute('RTAWeaponId')] or not d.rta.ownedWeapons[tool:GetAttribute('RTAWeaponId')] then return false,'소유한 총기를 장착하세요.' end
  local now=os.clock() local run={id=id,stage='BREACH',ready=now+def.seconds,expires=now+def.seconds+240}
  runs[p]=run owners[id]=p cooldown[id]=now+def.cooldown
  W.raise(p,def.wanted,def.name..' 강도 신고 접수') W.dispatch(p,def.guards)
  net.CrimeFX:FireAllClients('Alarm',point.Position) send(p,run,'금고를 열고 있습니다. 현장을 지키세요.')
  return true,'강도 시작'
 end
 function self.loot(p)
  local run=runs[p] local r=alive(p) if not run or not r then return false,'진행 중인 강도가 없습니다.' end
  local point=sites[run.id]
  if (r.Position-point.Position).Magnitude>18 or os.clock()<run.ready or run.stage~='BREACH' then return false,'금고 개방 후 현장에서 전리품을 수령하세요.' end
  run.stage='ESCAPE' run.ready=os.clock()+8 send(p,run,'현장에서 160스튜드 이상 벗어나 탈출하세요.') return true,'전리품 확보 / 탈출 필요'
 end
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<1 then return end elapsed=0
  for p,run in pairs(runs) do
   local r=alive(p) local d=P.get(p) local point=sites:FindFirstChild(run.id)
   if not r or not d or not point or os.clock()>run.expires or (p:GetAttribute('RTAInCustody')==true or (p:GetAttribute('RTAJailedUntil') or 0)>os.time()) or d.job=='Police' or d.job=='Military' then self.cancel(p,'강도 실패: 사망·체포·시간 초과·직업 변경') continue end
   local distance=(r.Position-point.Position).Magnitude
   if run.stage=='BREACH' and distance>65 then self.cancel(p,'강도 실패: 금고 개방 전에 현장을 이탈했습니다.')
   elseif run.stage=='ESCAPE' and not p:GetAttribute('RTAInterior') and (r.Position-(point:GetAttribute('ExteriorPosition') or point.Position)).Magnitude>=160 and os.clock()>=run.ready then
    local ok,message=T.robberyReward(d,C,run.id)
    if ok then owners[run.id]=nil runs[p]=nil send(p,nil,message) notify(p,message) else send(p,run,message) end
   else send(p,run) end
  end
 end)
 for _,point in ipairs(sites:GetChildren()) do
  local prompt=point:FindFirstChildOfClass('ProximityPrompt')
  if prompt then prompt.Triggered:Connect(function(p)
   if os.clock()-(promptAt[p] or -100)<1 then return end promptAt[p]=os.clock()
   local run=runs[p] local ok,message
   if run and run.id==point.Name then ok,message=self.loot(p) else ok,message=self.start(p,point.Name) end
   notify(p,message)
  end) end
 end
 Players.PlayerRemoving:Connect(function(p) self.cancel(p) promptAt[p]=nil end)
 return self
end
return R
