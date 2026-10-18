local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local C=require(script.Parent.Config)
local P=require(script.Parent.Profiles)
local net=RS:WaitForChild('PlayOS')
local request=net.Request
local update=net.Update
local tasks,ads,applications,cars,rates,lastBusiness={},{},{},{},{},{}
local function world() return workspace:FindFirstChild('PlayOSWorld') end
local function root(p) local ch=p.Character local h=ch and ch:FindFirstChildOfClass('Humanoid') return h and h.Health>0 and ch:FindFirstChild('HumanoidRootPart') end
local function near(p,part) local r=root(p) return r and part and part:IsA('BasePart') and (r.Position-part.Position).Magnitude<=C.InteractionDistance end
local function point(name) if not name then return nil end local w=world() return w and w:FindFirstChild('Points') and w.Points:FindFirstChild(name) end
local function send(p,message)
 local d=P.get(p) if not d then return end
 local listings={} for uid,a in pairs(ads) do table.insert(listings,{owner=uid,name=a.name}) end
 table.sort(listings,function(a,b) return a.owner<b.owner end)
 local candidates={} for uid in pairs(applications[p.UserId] or {}) do local q=Players:GetPlayerByUserId(uid) if q then table.insert(candidates,{id=uid,name=q.DisplayName}) end end
 local t=tasks[p]
 local depots={Taxi='TaxiDepot',Delivery='DeliveryDepot',Public='PublicDepot'}
 local target=point(t and t.target or depots[d.job])
 local navigation=target and {point=target.Name,title=target:GetAttribute('DisplayName') or target.Name,position=target.Position,stage=t and 'task' or 'reception',job=d.job} or false
 update:FireClient(p,{data=table.clone(d),message=message or '',ads=listings,candidates=candidates,temporary=P.temporary,navigation=navigation,task=t and {kind=t.kind,stage=t.stage,target=t.target,reward=t.reward} or false})
 local stats=p:FindFirstChild('leaderstats') local cash=stats and stats:FindFirstChild('Cash') if cash and (cash:IsA('IntValue') or cash:IsA('NumberValue')) then cash.Value=d.cash end
end
local changed=script.Parent:FindFirstChild('Changed')
if changed then changed.Event:Connect(function(p) if p and p.Parent==Players then send(p) end end) end
local function broadcast() for _,p in ipairs(Players:GetPlayers()) do send(p) end end
local function reward(d,amount) if d.cash+amount>C.MaxBalance then return false end d.cash+=amount return true end
local function destroyCar(p) if cars[p] then cars[p]:Destroy() cars[p]=nil end end
local function spawnCar(p)
 if not near(p,point('TaxiDepot')) then return '택시 차고로 이동하세요.' end
 destroyCar(p)
 local model=Instance.new('Model') model.Name='Taxi_'..p.UserId
 model:SetAttribute('OwnerUserId',p.UserId)
 local body=Instance.new('Part') body.Name='Body' body.Size=Vector3.new(7,2,12) body.Color=Color3.fromRGB(244,188,40) body.Anchored=true body.CFrame=point('TaxiDepot').CFrame*CFrame.new(0,3,12) body.Parent=model model.PrimaryPart=body
 local seat=Instance.new('VehicleSeat') seat.Name='Driver' seat.Size=Vector3.new(2,1,2) seat.CFrame=body.CFrame*CFrame.new(0,1.5,0) seat.Anchored=true seat.Parent=model
 for _,x in ipairs({-3.6,3.6}) do for _,z in ipairs({-3.5,3.5}) do local tire=Instance.new('Part') tire.Name='Wheel' tire.Shape=Enum.PartType.Cylinder tire.Size=Vector3.new(1,2.5,2.5) tire.Color=Color3.fromRGB(25,25,30) tire.Anchored=true tire.CFrame=body.CFrame*CFrame.new(x,-.7,z) tire.Parent=model end end
 model.Parent=world() cars[p]=model
 seat:GetPropertyChangedSignal('Occupant'):Connect(function() local h=seat.Occupant if h and Players:GetPlayerFromCharacter(h.Parent)~=p then h.Sit=false end end)
 return '택시 생성 완료. 운전석에 앉아 W/A/S/D 또는 모바일 조작을 사용하세요.'
end
local function begin(p,kind)
 local d=P.get(p) if not d then return end
 if tasks[p] then return '진행 중인 업무를 완료하거나 취소하세요.' end
 if d.job~=kind then return '먼저 해당 직업으로 취업하세요.' end
 local starts={Taxi='TaxiDepot',Delivery='DeliveryDepot',Public='PublicDepot'}
 if not near(p,point(starts[kind])) then return '해당 업무 접수처 가까이에서 시작하세요.' end
 tasks[p]={kind=kind,stage='pickup',target=kind=='Taxi' and 'TaxiPickup' or kind=='Delivery' and 'DeliveryPickup' or 'PublicWork',reward=C.Rewards[kind],since=os.clock()}
 return '업무를 받았습니다. 노란 목적지 표시를 따라가세요.'
end
local function interact(p,name)
 local t=tasks[p] if not t or t.target~=name or not near(p,point(name)) then return '현재 목적지에서 상호작용하세요.' end
 if os.clock()-t.since<C.MinimumTaskSeconds then return '이동 및 작업 중입니다. 잠시 후 다시 시도하세요.' end
 if t.kind=='Taxi' then local car=cars[p] if not car or not car.Driver.Occupant or Players:GetPlayerFromCharacter(car.Driver.Occupant.Parent)~=p then return '본인 택시 운전석에서 진행하세요.' end end
 if t.stage=='pickup' and t.kind~='Public' then t.stage='dropoff' t.target=t.kind=='Taxi' and 'TaxiDropoff' or 'DeliveryDropoff' t.since=os.clock() return '인수 완료. 다음 목적지로 이동하세요.' end
 local d=P.get(p) if not d then return end
 if not reward(d,t.reward) then return '소지금 한도에 도달했습니다.' end
 tasks[p]=nil return '업무 완료! ₩'..t.reward..' 지급되었습니다.'
end
local function handle(p,action,arg)
 local d=P.get(p) if not d then return end
 if action=='Sync' then return ''
 elseif action=='Deposit' or action=='Withdraw' then
  if type(arg)~='number' or arg~=arg or arg%1~=0 or arg<1 or arg>C.MaxBalance then return '올바른 금액을 입력하세요.' end
  local from=action=='Deposit' and 'cash' or 'bank' local to=action=='Deposit' and 'bank' or 'cash'
  if d[from]<arg or d[to]+arg>C.MaxBalance then return '잔액 또는 계좌 한도를 확인하세요.' end d[from]-=arg d[to]+=arg return '거래 완료'
 elseif action=='Job' then
  if type(arg)~='string' or not C.Jobs[arg] then return '없는 직업입니다.' end
  tasks[p]=nil destroyCar(p) d.job=arg return C.Jobs[arg]..' 취업 완료'
 elseif action=='Begin' then if arg=='Taxi' or arg=='Delivery' or arg=='Public' then return begin(p,arg) end
 elseif action=='Cancel' then tasks[p]=nil return '업무 취소'
 elseif action=='Car' then if d.job~='Taxi' then return '택시 기사만 이용할 수 있습니다.' end return spawnCar(p)
 elseif action=='Interact' then if type(arg)=='string' and #arg<40 then return interact(p,arg) end
 elseif action=='BuyBusiness' then
  if d.rta then return '사업체 접수처에서 레스토랑·공장·세탁소·카페 중 선택하세요.' end
  if d.business then return '이미 사업체가 있습니다.' end
  if d.bank<C.BusinessPrice then return '은행 잔액 ₩'..C.BusinessPrice..'이 필요합니다.' end
  d.bank-=C.BusinessPrice d.business=true return '내 사업체 개설 완료'
 elseif action=='BusinessOrder' then
  if d.rta then return '사업체 접수처에서 생산·세탁·판매 업무를 진행하세요.' end
  if not d.business or not near(p,point('Business')) then return '사업체를 소유하고 상가 카운터로 이동하세요.' end
  if os.clock()-(lastBusiness[p] or -100)<30 then return '다음 주문은 30초 후 처리할 수 있습니다.' end
  if not reward(d,C.BusinessOrderReward) then return '소지금 한도 초과' end lastBusiness[p]=os.clock() d.orders=math.min(C.MaxBalance,d.orders+1) return '주문 처리 수익 ₩'..C.BusinessOrderReward
 elseif action=='Advertise' then
  if not d.business then return '사업체를 먼저 개설하세요.' end
  if ads[p.UserId] then return '이미 공고가 등록되어 있습니다.' end
  ads[p.UserId]={name=p.DisplayName..'의 사업체'} broadcast() return '현재 서버 채용 공고 등록 완료'
 elseif action=='Apply' then
  if type(arg)~='number' or not ads[arg] or arg==p.UserId then return '지원할 공고를 선택하세요.' end
  applications[arg]=applications[arg] or {} if applications[arg][p.UserId] then return '이미 지원한 공고입니다.' end applications[arg][p.UserId]=true local owner=Players:GetPlayerByUserId(arg) if owner then send(owner,'새 입사 지원서가 도착했습니다.') end return '지원서 제출 완료'
 elseif action=='Hire' then
  if type(arg)~='number' or not d.business or not applications[p.UserId] or not applications[p.UserId][arg] then return '유효한 지원자가 아닙니다.' end
  local q=Players:GetPlayerByUserId(arg) local qd=q and P.get(q) if not qd then return '지원자가 오프라인입니다.' end
  q:SetAttribute('PlayOSEmployer',p.UserId) applications[p.UserId][arg]=nil send(q,'채용되었습니다. 상가에서 직원 업무를 수행하세요.') return '채용 완료'
 elseif action=='EmployeeWork' then
  local owner=Players:GetPlayerByUserId(p:GetAttribute('PlayOSEmployer') or 0)
  if not owner or not ads[owner.UserId] or not near(p,point('Business')) then return '고용된 직원만 상가에서 근무할 수 있습니다.' end
  if os.clock()-(lastBusiness[p] or -100)<30 then return '근무 보상 대기 중입니다.' end
  if not reward(d,80) then return '소지금 한도 초과' end lastBusiness[p]=os.clock() return '직원 근무 보상 ₩80'
 end
 return '요청을 확인하세요.'
end
request.OnServerEvent:Connect(function(p,action,arg)
 if type(action)~='string' or #action>32 then return end
 local now=os.clock() local r=rates[p] or {at=now,tokens=8} rates[p]=r r.tokens=math.min(8,r.tokens+(now-r.at)*4) r.at=now if r.tokens<1 then return end r.tokens-=1
 if arg~=nil and type(arg)~='string' and type(arg)~='number' then return end
 local ok,msg=pcall(handle,p,action,arg) if not ok then warn('PlayOS request failed: '..tostring(msg)) msg='처리 중 오류가 발생했습니다.' end send(p,msg)
end)
local function added(p)
 if not P.load(p) then p:Kick('PlayOS: 데이터를 안전하게 불러오지 못했습니다. 잠시 후 다시 접속하세요.') return end
 if not p.Parent then P.save(p,true) return end
 local s=p:FindFirstChild('leaderstats') if not s then s=Instance.new('Folder') s.Name='leaderstats' s.Parent=p end
 local v=s:FindFirstChild('Cash') if not v then v=Instance.new('IntValue') v.Name='Cash' v.Parent=s end
 p.CharacterAdded:Connect(function() tasks[p]=nil destroyCar(p) task.delay(1,function() if p.Parent then send(p,'도시에 오신 것을 환영합니다.') end end) end)
 send(p,'휴대폰에서 직업을 선택하세요.')
end
Players.PlayerAdded:Connect(added) for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
Players.PlayerRemoving:Connect(function(p)
 tasks[p]=nil rates[p]=nil ads[p.UserId]=nil applications[p.UserId]=nil lastBusiness[p]=nil destroyCar(p)
 for _,a in pairs(applications) do a[p.UserId]=nil end
 for _,q in ipairs(Players:GetPlayers()) do if q:GetAttribute('PlayOSEmployer')==p.UserId then q:SetAttribute('PlayOSEmployer',nil) end end
 if not P.save(p,true) then warn('PlayOS: departure save retained for retry '..p.UserId) end broadcast()
end)
local accumulator=0
Run.Heartbeat:Connect(function(dt)
 accumulator+=dt if accumulator<1/20 then return end local step=math.min(accumulator,.1) accumulator=0
 for p,car in pairs(cars) do local seat=car:FindFirstChild('Driver') local h=seat and seat.Occupant
  if h and Players:GetPlayerFromCharacter(h.Parent)==p then
   local turn=seat.SteerFloat local throttle=seat.ThrottleFloat local cf=car:GetPivot()*CFrame.Angles(0,-turn*step*1.5,0)
   local delta=cf.LookVector*throttle*step*45
   local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={car,p.Character}
   if delta.Magnitude>0 and not workspace:Blockcast(cf,Vector3.new(6,2,11),delta,params) then car:PivotTo(cf+delta) else car:PivotTo(cf) end
  end
 end
end)
task.spawn(function() while task.wait(1) do
 local list={} for p in pairs(P.loaded) do table.insert(list,p) end
 local gap=45/math.max(1,#list)
 for _,p in ipairs(list) do task.spawn(function()
  local profile=P.loaded[p] if not profile then return end
  if not P.save(p,profile.closing==true) then warn('PlayOS save failed; retained for retry '..p.UserId) end
  if not P.get(p) and p.Parent then p:Kick('저장 연결이 끊겼습니다. 다시 접속하세요.') end
 end) task.wait(gap) end
 end end)
game:BindToClose(function() local pending=0 for p in pairs(P.loaded) do pending+=1 task.spawn(function() P.save(p,true) pending-=1 end) end local deadline=os.clock()+25 while pending>0 and os.clock()<deadline do task.wait(.1) end end)
