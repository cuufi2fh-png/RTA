local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local Debris=game:GetService('Debris')
local PS=game:GetService('ServerScriptService'):WaitForChild('PlayOS')
local P=require(PS.Profiles);local Schema=require(PS.ProfileSchema)
local net=RS:WaitForChild('RTAContent');local C=require(net.Catalog);local T=require(script.Parent.Transactions)
local World=require(script.Parent.World).start(C)
local origin=World.map:GetAttribute('MapOrigin')or Vector3.zero
local Vehicles=require(script.Parent.Vehicles).start(C,World,net)
local weaponCatalog=require(RS.RTA.Catalog)
local Weapons=require(game.ServerScriptService.RTA.Weapons).start(P,weaponCatalog,RS.RTA)
local sessions,jobs,robberies,golfRuns={},{},{},{}
local Fishing
local robberyNext=0;local Monetization
local function character(p)local ch=p.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local r=ch and ch:FindFirstChild('HumanoidRootPart');if h and h.Health>0 then return r,h,ch end end
local function point(id)return World.map.ActivityPoints:FindFirstChild(id)end
local function near(p,part,distance)local r=character(p);return r and part and part:IsA('BasePart')and(r.Position-part.Position).Magnitude<=(distance or 22)end
local function ownedNear(p,kind)local plot=World.ownedPlot(p,kind);return plot and near(p,plot.BuildArea,math.max(plot.BuildArea.Size.X,plot.BuildArea.Size.Z)*.65+15),plot end
local function summary(d)local out=Schema.copy(d);out.content.receipts=nil;return out end
local function send(p,message,menu,plotId)
 local d=P.get(p);if not d or p.Parent~=Players then return end
 Weapons.sync(p)
 local prices={};for id in C.Stocks do prices[id]=T.stockPrice(C,id,os.time())end
 local j=jobs[p];local robbery=robberies[p]
 net.State:FireClient(p,{data=summary(d),message=message or'',menu=menu,plotId=plotId,time=os.time(),temporary=P.temporary,prices=prices,randomAllowed=Monetization and Monetization.randomAllowed(p)or false,fishing=false,job=j and {kind=j.kind,target=j.target,stage=j.stage,position=point(j.target).Position}or false,robbery=robbery and {readyAt=robbery.readyAt}or false})
 local changed=PS:FindFirstChild('Changed');if changed then changed:Fire(p)end
end
Monetization=require(script.Parent.Monetization).start(P,C,T,send)
Fishing=require(script.Parent.Fishing).start(P,C,send)
local rng=Random.new()
local function budget(p)
 local now=os.clock();local s=sessions[p]
 if not s then s={tokens=10,at=now,seen={},order={}};sessions[p]=s end
 s.tokens=math.min(10,s.tokens+(now-s.at)*5);s.at=now
 if s.tokens<1 or s.busy then return nil end;s.tokens-=1;return s
end
local shops={Weapons='GunShop',Vehicles='CarShop',Boats='BoatShop',Aircraft='HeliShop',Crops='FarmShop',Food='FoodShop',Homes='Housing',Businesses='Business'}
local function shopNear(p,category)
 if near(p,point(shops[category]))then return true end
 if category=='Homes'then local r=character(p);if not r then return false end;for _,pl in World.plots:GetChildren()do local k=pl:GetAttribute('PlotType');if(k=='Home'or k=='LargeHome')and near(p,pl.PlotSign,24)then return true end end
 elseif category=='Businesses'then for _,pl in World.plots:GetChildren()do if pl:GetAttribute('PlotType')=='Business'and near(p,pl.PlotSign,24)then return true end end end
 return false
end
local destinations={'DeliveryA','DeliveryB','DeliveryC','TaxiA','TaxiB','TaxiC'}
local function startJob(p,d,kind)
 if kind~='Taxi'and kind~='Delivery'then return false,'택시 또는 배달 업무를 선택하세요.'end
 if not d.content.businesses[kind]then return false,'해당 사업을 먼저 시작하세요.'end
 if not near(p,point(kind=='Taxi'and'TaxiDepot'or'DeliveryDepot'))then return false,'업무 접수처로 이동하세요.'end
 if jobs[p]then return false,'진행 중인 업무를 먼저 완료하세요.'end
 if kind=='Taxi'then local v=Vehicles.state(p);if not v or not v.def.taxi or not v.seat.Occupant or Players:GetPlayerFromCharacter(v.seat.Occupant.Parent)~=p then return false,'소유한 택시 운전석에서 접수하세요.'end end
 local target=destinations[rng:NextInteger(kind=='Taxi'and 4 or 1,kind=='Taxi'and 6 or 3)]
 jobs[p]={kind=kind,target=target,stage='pickup',since=os.clock()};d.job=kind;return true,'표시된 장소로 이동하세요.'
end
local function finishJob(p,d)
 local j=jobs[p];if not j then return false,'진행 중인 업무가 없습니다.'end
 if not near(p,point(j.target),35)then return false,'목적지에서 완료하세요.'end
 if os.clock()-j.since<12 then return false,'업무 이동 시간이 부족합니다.'end
 if j.kind=='Taxi'then local v=Vehicles.state(p);if not v or not v.def.taxi or not v.seat.Occupant or Players:GetPlayerFromCharacter(v.seat.Occupant.Parent)~=p then return false,'택시 운전석에서 진행하세요.'end end
 if j.stage=='pickup'then
  local previous=j.target;repeat j.target=destinations[rng:NextInteger(j.kind=='Taxi'and 4 or 1,j.kind=='Taxi'and 6 or 3)]until j.target~=previous
  j.stage='dropoff';j.since=os.clock();return true,'인수 완료. 다음 목적지로 이동하세요.'
 end
 local reward=C.Businesses[j.kind].revenue;if d.cash+reward>C.Limits.balance then return false,'소지금 한도입니다.'end
 d.cash+=reward;d.orders+=1;jobs[p]=nil;return true,'운송 완료 +$'..reward
end
local function golfShot(p,id,power,angle)
 local tee=point(id);local hole=tee and tee:GetAttribute('HolePosition')
 if not hole or not near(p,tee,20)or not T.quantity(power,100)or type(angle)~='number'or angle~=angle or math.abs(angle)>180 then return false,'티박스에서 방향과 힘을 설정하세요.'end
 if golfRuns[p]then return false,'공이 멈출 때까지 기다려 주세요.'end
 local root=character(p);local start=tee.Position+Vector3.new(0,-2,0);local toward=Vector3.new(hole.X-start.X,0,hole.Z-start.Z).Unit
 toward=(CFrame.Angles(0,math.rad(angle),0)*toward)
 local ball=Instance.new('Part');ball.Name='GolfBall';ball.Shape=Enum.PartType.Ball;ball.Size=Vector3.new(1.1,1.1,1.1);ball.Color=Color3.new(1,1,1);ball.Anchored=true;ball.CanCollide=false;ball.Position=start;ball.Parent=World.dynamic
 local run={ball=ball};golfRuns[p]=run
 task.spawn(function()
  local velocity=toward*(power*1.55)+Vector3.new(0,power*.28,0);local position=start;local elapsed=0
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={ball,p.Character}
  while ball.Parent and elapsed<8 and golfRuns[p]==run do
   local dt=task.wait(.04);dt=math.min(dt,.1);elapsed+=dt;velocity+=Vector3.new(0,-55*dt,0);local delta=velocity*dt;local hit=workspace:Raycast(position,delta,params)
   if hit then position=hit.Position+hit.Normal*.6;velocity=(velocity-hit.Normal*velocity:Dot(hit.Normal))* .76;velocity=Vector3.new(velocity.X,math.max(0,-velocity.Y*.2),velocity.Z)
   else position+=delta end;ball.Position=position
   if Vector3.new(position.X-hole.X,0,position.Z-hole.Z).Magnitude<4 and position.Y<hole.Y+3 then
    local d=P.get(p);if d then d.cash=math.min(C.Limits.balance,d.cash+150);send(p,'홀인! 무료 골프 보상 +$150')end;break
   end
   if velocity.Magnitude<1 and elapsed>1 then break end
  end
  if golfRuns[p]==run then golfRuns[p]=nil end
  if ball.Parent then Debris:AddItem(ball,3)end
 end)
 return true,'샷!'
end
local function handle(p,a,b,c,e)
 local d=P.get(p);if not d then return false,'데이터를 안전하게 연결하는 중입니다.'end
 if a=='Sync'then return true,''end
 if a=='Offer'then local ok,result=Monetization.offer(p,b);if ok then net.Purchase:FireClient(p,result);return true,'Roblox 구매창에서 확인하세요.'end;return false,result end
 if a=='RestorePurchases'then task.spawn(Monetization.sync,p,false);return true,'구매 내역 확인 중'end
 if a=='Buy'then if not shopNear(p,b)then return false,'해당 상점 접수처로 이동하세요.'end;local ok,msg=T.buy(d,C,b,c,e);if ok and b=='Weapons'then Weapons.sync(p)end;return ok,msg end
 if a=='ClaimPlot'then
  local plot=World.plot(b);if not plot or not near(p,plot.PlotSign,24)then return false,'부지 표지판 가까이에서 배정받으세요.'end
  local kind=plot:GetAttribute('PlotType');if kind=='LargeHome'then kind='Home'end
  if kind~='Home'and kind~='Farm'and kind~='Business'then return false,'이곳은 직접 건축하는 공용 시설 부지입니다.'end
  local ok,msg=World.claim(p,kind,b);if ok then d.content[kind=='Home'and'homePlot'or kind=='Farm'and'farmPlot'or'businessPlot']=b;if kind=='Farm'then World.garden(p,d.content)end end;return ok,msg
 end
 if a=='PlaceHome'then local at=ownedNear(p,'Home');if not at then return false,'내 주거 플롯으로 이동하세요.'end
  if not T.owns(d,'Homes',b)then return false,'보유한 주택을 선택하세요.'end;local ok,msg=World.home(p,b);if ok then d.content.selectedHome=b end;return ok,msg end
 if a=='PlaceBusiness'then local at=ownedNear(p,'Business');if not at or not d.content.businesses[b]then return false,'소유한 사업을 내 사업 부지에서 선택하세요.'end
  local ok,msg=World.business(p,b);if ok then d.content.selectedBusiness=b;d.business=true end;return ok,msg end
 if a=='Plant'then if not ownedNear(p,'Farm')then return false,'내 농사 부지로 이동하세요.'end;local ok,msg=T.plant(d,C,b,c,os.time());if ok then World.garden(p,d.content)end;return ok,msg end
 if a=='Harvest'then if not ownedNear(p,'Farm')then return false,'내 농사 부지로 이동하세요.'end;local ok,msg=T.harvest(d,C,b,os.time(),rng:NextNumber(),Monetization.randomAllowed(p));if ok then World.garden(p,d.content)end;return ok,msg end
 if a=='EquipRod'then return Fishing.equip(p,b)end
 if a=='SellFish'then if not require(script.Parent.FishSaleAccess).canSell(p)then return false,'FISHING 상점의 매입 카운터에서 판매하세요.'end;return T.sellFish(d,C)end
 if a=='UseFood'then
  local def=C.Food[b];local _,h=character(p);if not def or not h or(d.content.foods[b]or 0)<1 then return false,'보유한 음식을 선택하세요.'end
  d.content.foods[b]-=1;h.Health=math.min(h.MaxHealth,h.Health+def.heal)
  if def.buff~='None'then d.content.boosts[def.buff]=math.min(os.time()+1800,math.max(os.time(),d.content.boosts[def.buff]or 0)+def.seconds)end
  return true,def.name..' 사용 완료'
 end
 if a=='FactoryBoost'then if(d.content.tokens.FactoryBoost or 0)<1 then return false,'공장 2배권이 없습니다.'end
  if not d.content.businesses.Factory then return false,'공장 라이선스가 필요합니다.'end
  d.content.tokens.FactoryBoost-=1;d.content.boosts.Factory=math.max(os.time(),d.content.boosts.Factory or 0)+1800;return true,'공장 수익 2배 활성화'end
 if a=='Produce'then if not ownedNear(p,'Business')or d.content.selectedBusiness~=b then return false,'내 사업장에서 진행하세요.'end;return T.beginProduction(d,C,b,os.time(),c)end
 if a=='Collect'then if not ownedNear(p,'Business')then return false,'내 사업장에서 정산하세요.'end;return T.collectProduction(d,C,b=='Laundry',c==true,os.time())end
 if a=='Trade'then return T.trade(d,C,b,c,e==true,os.time())end
 if a=='RollVehicle'then if not near(p,point('CarShop'),30)then return false,'차량 딜러샵에서 뽑기를 이용하세요.'end;return T.rollVehicle(d,C,rng:NextNumber(),Monetization.randomAllowed(p))end
 if a=='Spawn'then
  if(b~='Vehicles'and b~='Boats'and b~='Aircraft')or not T.owns(d,b,c)then return false,'보유한 이동 수단을 선택하세요.'end
  local vendor=point(shops[b]);if not near(p,vendor,32)then return false,'해당 딜러샵으로 이동하세요.'end
  return Vehicles.spawn(p,b,c,vendor:GetAttribute('SpawnPosition'))
 end
 if a=='Despawn'then Vehicles.remove(p);return true,'이동 수단 반납 완료'end
 if a=='Ammo'then if not near(p,point('GunShop'),25)then return false,'총기 상점에서 보급하세요.'end;return Weapons.refill(p,b)end
 if a=='StartJob'then return startJob(p,d,b)end
 if a=='JobFinish'then return finishJob(p,d)end
 if a=='CancelJob'then jobs[p]=nil;return true,'업무 취소'end
 if a=='GolfShot'then return golfShot(p,b,c,e)end
 if a=='RobberyStart'then
  if not near(p,point('BankVault'),18)then return false,'은행 금고 앞에서 시작하세요.'end
  if robberyNext>os.time()or next(robberies)then return false,'금고 보안이 작동 중입니다.'end
  robberies[p]={readyAt=os.time()+60};p:SetAttribute('RTAWanted',3);return true,'금고 개방 중 · 60초 동안 주변을 지키세요.'
 end
 if a=='RobberyCollect'then
  local job=robberies[p];if not job or job.readyAt>os.time()or not near(p,point('BankVault'),24)then return false,'금고 개방을 완료하고 가까이에서 수령하세요.'end
  if d.cash+3500>C.Limits.balance then return false,'소지금 한도입니다.'end
  d.cash+=3500;if d.content.entitlements.LaundryLicense then d.rta.stolenGoods=math.min(1000000,d.rta.stolenGoods+10)end
  robberies[p]=nil;robberyNext=os.time()+300;return true,'현금 $3500과 보유 라이선스에 따른 도난 물품을 획득했습니다.'
 end
 return false,'지원하지 않는 작업입니다.'
end
net.Request.OnServerEvent:Connect(function(p,a,b,c,e,nonce)
 if type(a)~='string'or #a>32 or type(nonce)~='string'or #nonce>48 then return end
 for _,v in {b,c,e}do if type(v)~='string'and type(v)~='number'and type(v)~='boolean'then return end;if type(v)=='string'and #v>80 then return end;if type(v)=='number'and(v~=v or math.abs(v)>1000000)then return end end
 local s=budget(p);if not s or s.seen[nonce]then return end;s.seen[nonce]=true;table.insert(s.order,nonce);if #s.order>128 then s.seen[table.remove(s.order,1)]=nil end
 s.busy=true;local ok,success,message=pcall(handle,p,a,b,c,e);s.busy=false
 if not ok then warn('RTA content action failed',a,success);message='작업 중 오류가 발생했습니다.'end
 send(p,message)
end)
for _,v in World.map:GetDescendants()do if v:IsA('ProximityPrompt')and(v.Parent:GetAttribute('ContentPoint')or v.Parent:GetAttribute('Menu'))then
 v.Triggered:Connect(function(p)
  if not budget(p)or not near(p,v.Parent,24)then return end
  local id=v.Parent:GetAttribute('ContentPoint');local kind=v.Parent:GetAttribute('Menu')
  send(p,'',kind,id)
 end)
end end
local function added(p)
 task.spawn(function()
  local deadline=os.clock()+30;while p.Parent and not P.get(p)and os.clock()<deadline do task.wait(.2)end
  if not p.Parent or not P.get(p)then return end
  Monetization.loadPolicy(p);Monetization.sync(p,true)
  local d=P.get(p);if not d then return end
  for kind,key in {Home='homePlot',Farm='farmPlot',Business='businessPlot'}do
   local id=d.content[key];if id then local ok=World.claim(p,kind,id);if not ok then d.content[key]=false end end
  end
  if d.content.selectedHome and World.ownedPlot(p,'Home')then World.home(p,d.content.selectedHome)end
  if d.content.selectedBusiness and World.ownedPlot(p,'Business')then World.business(p,d.content.selectedBusiness)end
  World.garden(p,d.content);send(p,'RTA 섬에 오신 것을 환영합니다. P: 휴대폰 / F: 낚싯대')
 end)
 p.CharacterAdded:Connect(function()jobs[p]=nil;robberies[p]=nil;task.delay(1,function()if p.Parent then send(p)end end)end)
end
Players.PlayerAdded:Connect(added);for _,p in Players:GetPlayers()do added(p)end
Players.PlayerRemoving:Connect(function(p)World.release(p);sessions[p]=nil;jobs[p]=nil;robberies[p]=nil;if golfRuns[p]then golfRuns[p].ball:Destroy();golfRuns[p]=nil end end)
local timer=0
Run.Heartbeat:Connect(function(dt)
 timer+=dt;if timer<1 then return end;timer=0
 for _,p in Players:GetPlayers()do local d=P.get(p);local r,h=character(p)
  if d and r then
   local now=os.time();local s=d.content
   h.WalkSpeed=p:GetAttribute('RTAFishingBusy')and 0 or((s.boosts.Speed or 0)>now and 24 or 16)
   if(s.boosts.Regen or 0)>now then h.Health=math.min(h.MaxHealth,h.Health+2)end
   local armor=(s.boosts.Armor or 0)>now;p.Character:SetAttribute('ContentArmorBuff',armor)
   p:SetAttribute('RTASafeZone',r.Position.Z-origin.Z<-175 and math.abs(r.Position.X-origin.X)<2000 or(r.Position-point('Housing').Position).Magnitude<60)
   if robberies[p]and not near(p,point('BankVault'),55)then robberies[p]=nil;send(p,'금고 구역을 벗어나 강도가 중단되었습니다.')end
   if s.entitlements.FactoryAuto and s.production and s.production.kind=='Factory'and s.production.readyAt<=now then local ok,msg=T.collectProduction(d,C,false,false,now);if ok then send(p,msg)end end
  end
 end
end)
-- Server-only test interface; no client can invoke it.
script:SetAttribute('Booted',true)
if Run:IsStudio()then local bridge=Instance.new('BindableFunction');bridge.Name='RTAContentTestBridge';bridge.OnInvoke=function()return {handle=handle,send=send,world=World,vehicles=Vehicles,profiles=P,catalog=C,transactions=T,fishing=Fishing}end;bridge.Parent=game.ServerStorage end
