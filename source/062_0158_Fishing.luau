-- RTA adapter for the user-supplied FREE R6 Fishing System.
-- The supplied state machine, rod, line effects and UI are retained; only the server grants fish.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local RS=game:GetService('ReplicatedStorage')
local F={}
function F.start(P,C,send)
 if F.running then if send then F.notify=send end;return F end
 F.running=true;F.notify=send
 local system=RS:WaitForChild('FishingSystem')
 local Model=require(system.Shared.Fishing)
 local config=require(system.Shared.Configuration)
 local rules=config.Fishing
 local network=require(system.Shared.Network)
 local rng=Random.new()
 local sessions,limits,tools,connections={},{},{},{}
 local lines=Instance.new('Folder');lines.Name='RTAFishingLines';lines.Parent=workspace
 local function clock()return workspace:GetServerTimeNow()end
 local function rig(p)
  local ch=p.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local root=ch and ch:FindFirstChild('HumanoidRootPart')
  if h and h.Health>0 and root then return ch,h,root end
 end
 local function rod(p)
  local ch=rig(p);if not ch then return end
  local owned=tools[p];if not owned then return end
  for _,t in owned do if t.Parent==ch then return t end end
 end
 local function snapshot(p,s,message)
  network.Snapshot:FireClient(p,{session=s and s.state or Model.Ready,target=s and s.target or false,id=s and s.id or false,message=message or''})
 end
 local function cleanVisual(s)if s and s.visual then s.visual:Destroy();s.visual=nil end end
 local function cancel(p,message)
  local s=sessions[p];sessions[p]=nil;cleanVisual(s)
  p:SetAttribute('RTAFishingBusy',false)
  snapshot(p,nil,message)
 end
 local function water(p,target)
  if typeof(target)~='Vector3'then return end
  for _,n in {target.X,target.Y,target.Z}do if n~=n or math.abs(n)>100000 then return end end
  local ch,h,root=rig(p);if not root or h.SeatPart or h:GetState()==Enum.HumanoidStateType.Swimming or(target-root.Position).Magnitude>rules.CastRange or(target-root.Position).Magnitude<3 then return end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={ch,lines};params.IgnoreWater=false
  local hit=workspace:Raycast(target+Vector3.new(0,3,0),Vector3.new(0,-8,0),params)
  if not hit or not(hit.Material==Enum.Material.Water or hit.Instance:HasTag('Water'))or(hit.Position-target).Magnitude>4 then return end
  local eye=ch:FindFirstChild('Head');local start=eye and eye.Position or root.Position+Vector3.new(0,2,0)
  local sight=workspace:Raycast(start,hit.Position+Vector3.new(0,.3,0)-start,params)
  if sight and(sight.Position-hit.Position).Magnitude>2 then return end
  return hit.Position
 end
 local function valid(p,s)
  local ch,h,r=rig(p);return r and rod(p)==s.tool and not h.SeatPart and h:GetState()~=Enum.HumanoidStateType.Swimming and(r.Position-s.origin).Magnitude<12 and(s.target-r.Position).Magnitude<=rules.CastRange+6
 end
 local function grant(p,s)
  local d=P.get(p);if not d then return false end
  local premium=s.tool:GetAttribute('RTARodType')=='Premium'
  if premium and not d.content.entitlements.PremiumRod then cancel(p,'프리미엄 낚싯대 권한을 확인해 주세요.');return true end
  local key=premium and'FishingPremiumSequence'or'FishingSequence'
  local seq=d.content.tokens[key]or 0
  local id=('Fish%02d'):format((premium and 31 or 1)+seq%(premium and 20 or 30))
  local def=C.Fish[id]
  if(d.content.fish[id]or 0)>=1000000 then cancel(p,'물고기 보관함이 가득 찼습니다.');return true end
  -- No yields: inventory and cycle advance together. A session can award only once.
  s.awarded=true;d.content.fish[id]=(d.content.fish[id]or 0)+1;d.content.tokens[key]=(seq+1)%600000
  p:SetAttribute('RTAFishingBusy',false);cleanVisual(s)
  network.FishLanded:FireClient(p,def.name)
  if F.notify then F.notify(p,def.name..' 낚시 성공! 낚시 상점에서 판매할 수 있습니다.')else local changed=game.ServerScriptService.PlayOS:FindFirstChild('Changed');if changed then changed:Fire(p)end end
  return true
 end
 local function visual(p,s)
  local f=Instance.new('Folder');f.Name=tostring(p.UserId);f:SetAttribute('OwnerUserId',p.UserId);f.Parent=lines;s.visual=f
  local bobber=Instance.new('Part');bobber.Name='Bobber';bobber.Shape=Enum.PartType.Ball;bobber.Size=Vector3.one*.35;bobber.Color=config.Line.BobberColor;bobber.Anchored=true;bobber.CanCollide=false;bobber.CanTouch=false;bobber.CanQuery=false;bobber.Position=s.target;bobber.Parent=f
  local tipPart=s.tool:FindFirstChild('StylizedFishingRod');local tip=tipPart and tipPart:FindFirstChild('End')
  if tip then local a=Instance.new('Attachment');a.Parent=bobber;local b=Instance.new('Beam');b.Name='Line';b.Attachment0=tip;b.Attachment1=a;b.Width0=.035;b.Width1=.035;b.FaceCamera=true;b.Segments=16;b.Color=ColorSequence.new(config.Line.Color);b.Parent=f end
 end
 function F.equip(p,kind)
  local d=P.get(p);local ch,h=rig(p)
  if not d or not h or(kind~='Basic'and kind~='Premium')then return false,'잠시 후 다시 장착하세요.'end
  if kind=='Premium'and not d.content.entitlements.PremiumRod then return false,'프리미엄 낚싯대가 필요합니다.'end
  cancel(p);h:UnequipTools()
  tools[p]=tools[p]or{}
  local t=tools[p][kind]
  if not t or not t.Parent then
   t=Instance.new('Tool');t.Name=kind=='Premium'and'프리미엄 낚싯대'or'낚싯대';t.ToolTip='물을 누르고 있다 놓아 캐스팅 · 입질 버튼 · 릴 조절';t.CanBeDropped=false;t.RequiresHandle=false;t:SetAttribute('RTARodType',kind);t:AddTag('FishingRod');tools[p][kind]=t;t.Parent=p.Backpack
   t.Unequipped:Connect(function()if sessions[p]and sessions[p].tool==t then cancel(p,'낚시를 종료했습니다.')end end)
  end
  h:EquipTool(t);return true,'물을 누르고 있다가 게이지에 맞춰 놓으세요.'
 end
 local function handle(p,action,id,seq,value)
  if type(action)~='string'or #action>16 or type(id)~='string'or #id<8 or #id>48 or type(seq)~='number'or seq%1~=0 or seq<1 or seq>10000000 then return false end
  local now=clock();local l=limits[p]
  if not l then l={tokens=24,at=now,seqs={},order={}};limits[p]=l end
  l.tokens=math.min(24,l.tokens+(now-l.at)*20);l.at=now
  if l.tokens<1 then return false end;l.tokens-=1
  if seq<=(l.seqs[id]or 0)then return false end
  if not l.seqs[id]then table.insert(l.order,id);if #l.order>16 then l.seqs[table.remove(l.order,1)]=nil end end;l.seqs[id]=seq
  if action=='Cancel'then if sessions[p]and sessions[p].id==id then cancel(p)end;return true end
  local t=rod(p);local d=P.get(p);if not t or not d then return false end
  if t:GetAttribute('RTARodType')=='Premium'and not d.content.entitlements.PremiumRod then return false end
  local s=sessions[p]
  if action=='Begin'then
   if s and (not s.awarded and s.state.Stage=='Caught' or Model.PhaseAt(s.state,now,rules)~='Ready')then return false end
   if l.nextCast and now<l.nextCast then return false end
   local target=water(p,value);if not target then snapshot(p,nil,'물을 향해 던져 주세요.');return false end
   if s then cleanVisual(s)end
   local _,_,root=rig(p)
   s={id=id,tool=t,state=Model.Begin(now),target=target,origin=root.Position,holding=false,lastHold=now,lastShake=0,expires=now+90,sendAt=0,awarded=false}
   sessions[p]=s;p:SetAttribute('RTAFishingBusy',true);l.nextCast=now+1;snapshot(p,s);return true
  end
  if not s or s.id~=id then return false end
  if not valid(p,s)then cancel(p,'낚시 위치를 벗어났습니다.');return false end
  if action=='Release'then
   if s.state.Stage~='Charging'or now-s.state.StartedAt<.08 then return false end
   s.state=Model.Release(s.state,now,rng:NextNumber(),Vector2.new(rng:NextNumber(),rng:NextNumber()),rules)
   if(d.content.boosts.Fishing or 0)>os.time()then s.state.BiteAt=math.max(now+rules.CastTime+.6,s.state.BiteAt-2)end
   visual(p,s);snapshot(p,s);return true
  elseif action=='Shake'then
   if now-s.lastShake<.16 or Model.PhaseAt(s.state,now,rules)~='Shaking'then return false end
   s.lastShake=now;s.state=Model.Shake(s.state,now,Vector2.new(rng:NextNumber(),rng:NextNumber()),rules);snapshot(p,s);return true
  elseif action=='Hold'then
   if type(value)~='boolean'then return false end
   s.holding=value;s.lastHold=now;return true
  end
  return false
 end
 network.Request.OnServerEvent:Connect(handle)
 local step=0
 Run.Heartbeat:Connect(function(dt)
  step+=dt;if step<1/30 then return end;local elapsed=math.min(step,.1);step=0;local now=clock()
  for p,s in sessions do
   if not valid(p,s)or now>s.expires then cancel(p,'낚시가 취소되었습니다.');continue end
   local old=s.state.Stage
   if old=='Charging'and now-s.state.StartedAt>12 then cancel(p);continue end
   if old=='Line'and now>s.state.BiteAt+18 then s.state=table.clone(s.state);s.state.Stage='Escaped';s.state.EndedAt=now end
   if s.state.Stage=='Reeling'then s.state=Model.StepReel(s.state,now,elapsed,s.holding and now-s.lastHold<1,rng:NextNumber(),rules)end
   if s.state.Stage=='Caught'and not s.awarded then grant(p,s)end
   if s.state.Stage=='Escaped'then cleanVisual(s);p:SetAttribute('RTAFishingBusy',false)end
   if now>=s.sendAt or old~=s.state.Stage then snapshot(p,s);s.sendAt=now+.05 end
   if s.visual then
    local bob=s.visual.Bobber;local dip=Model.PhaseAt(s.state,now,rules)=='Shaking'and-.3 or 0
    bob.Position=s.target+Vector3.new(0,.12+math.sin(now*4)*.08+dip,0)
   end
   if(s.state.Stage=='Caught'and s.awarded or s.state.Stage=='Escaped')and now>s.state.EndedAt+rules.ResultTime then sessions[p]=nil;snapshot(p,nil)end
  end
 end)
 local function added(p)
  local function reset()cancel(p);tools[p]=nil end
  connections[p]=p.CharacterAdded:Connect(reset)
 end
 Players.PlayerAdded:Connect(added);for _,p in Players:GetPlayers()do added(p)end
 Players.PlayerRemoving:Connect(function(p)cleanVisual(sessions[p]);sessions[p]=nil;tools[p]=nil;limits[p]=nil;if connections[p]then connections[p]:Disconnect();connections[p]=nil end end)
 F.handle=handle;F.cancel=cancel;F.state=function(p)return sessions[p]end;F.water=water
 return F
end
return F
