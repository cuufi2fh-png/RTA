local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local UIS=game:GetService('UserInputService');local Run=game:GetService('RunService');local Http=game:GetService('HttpService');local Market=game:GetService('MarketplaceService');local CAS=game:GetService('ContextActionService')
local player=Players.LocalPlayer;local net=RS:WaitForChild('RTAContent');local C=require(net:WaitForChild('Catalog'))
local gui=Instance.new('ScreenGui');gui.Name='RTAContentUI';gui.ResetOnSpawn=false;gui.DisplayOrder=35;gui.Parent=player:WaitForChild('PlayerGui')
local bg=Color3.fromRGB(20,24,28);local cardColor=Color3.fromRGB(32,38,43);local muted=Color3.fromRGB(169,180,183);local gold=Color3.fromRGB(229,190,100);local white=Color3.fromRGB(238,239,230)
local function ui(class,parent,props)local v=Instance.new(class);for k,x in props do v[k]=x end;v.Parent=parent;return v end
local function text(parent,s,pos,size,color,font)
 return ui('TextLabel',parent,{Text=s,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=color or white,Font=font or Enum.Font.Gotham,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true})
end
local function button(parent,s,fn,size)
 local b=ui('TextButton',parent,{Text=s,Size=size or UDim2.new(1,0,0,38),BackgroundColor3=Color3.fromRGB(49,61,66),BorderSizePixel=0,TextColor3=white,Font=Enum.Font.GothamMedium,TextSize=14,TextWrapped=true});b.Activated:Connect(fn);return b
end
local panel=ui('Frame',gui,{Name='Panel',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1010,680),BackgroundColor3=bg,BorderSizePixel=0,Visible=false})
ui('UIStroke',panel,{Color=Color3.fromRGB(79,92,96),Thickness=1})
local scale=ui('UIScale',panel,{Scale=1})
local heading=text(panel,'RTA',UDim2.fromOffset(24,18),UDim2.fromOffset(660,24),gold,Enum.Font.GothamBold)
local balance=text(panel,'연결 중',UDim2.fromOffset(24,48),UDim2.fromOffset(820,24),muted)
local close=button(panel,'닫기  ×',function()panel.Visible=false end,UDim2.fromOffset(92,34));close.Name='Close';close.Position=UDim2.new(1,-114,0,18)
local nav=ui('ScrollingFrame',panel,{Name='Tabs',Position=UDim2.fromOffset(24,85),Size=UDim2.new(1,-48,0,44),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=2,BackgroundTransparency=1,BorderSizePixel=0})
ui('UIListLayout',nav,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
local hint=text(panel,'',UDim2.fromOffset(24,139),UDim2.new(1,-48,0,42),muted)
local content=ui('ScrollingFrame',panel,{Name='Content',Position=UDim2.fromOffset(24,191),Size=UDim2.new(1,-48,1,-250),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,BackgroundTransparency=1,BorderSizePixel=0})
local grid=ui('UIGridLayout',content,{CellSize=UDim2.fromOffset(306,186),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder})
local notice=text(panel,'',UDim2.new(0,24,1,-47),UDim2.new(1,-48,0,32),gold)
local mission=text(gui,'',UDim2.new(1,-360,0,110),UDim2.fromOffset(330,100),gold,Enum.Font.GothamBold);mission.TextXAlignment=Enum.TextXAlignment.Right
local marker=ui('BillboardGui',gui,{Name='Destination',Size=UDim2.fromOffset(180,50),AlwaysOnTop=true,Enabled=false,StudsOffsetWorldSpace=Vector3.new(0,6,0)})
local markerText=text(marker,'목적지',UDim2.new(),UDim2.fromScale(1,1),gold,Enum.Font.GothamBold);markerText.TextXAlignment=Enum.TextXAlignment.Center;markerText.TextStrokeTransparency=.4
local waypoint=Instance.new('Part');waypoint.Name='LocalDestination';waypoint.Size=Vector3.one;waypoint.Transparency=1;waypoint.Anchored=true;waypoint.CanCollide=false;waypoint.CanQuery=false;waypoint.Parent=workspace;marker.Adornee=waypoint
local state,category,plotId=nil,'Fish',nil;local selection={crop='Crop01',slot=1,power=50,angle=0,tee='Golf_1'};local priceCache={};local pricePending={};local render;local receivedAt=0
local categories={{'Fish','낚시'},{'Crops','농사'},{'Homes','주택'},{'Vehicles','차량'},{'Boats','보트'},{'Aircraft','항공기'},{'Businesses','사업'},{'Food','음식'},{'Weapons','총기'},{'Stocks','주식'},{'Premium','캐시·패스'},{'Golf','골프'}}
local function ask(a,b,c,e)net.Request:FireServer(a,b,c,e,Http:GenerateGUID(false))end
local function equip(id)local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if not h then return end;for _,f in {player.Backpack,player.Character}do for _,t in f:GetChildren()do if t:IsA('Tool')and t:GetAttribute('RTAWeaponId')==id then h:EquipTool(t);panel.Visible=false;return end end end end
local function owned(cat,id)
 if not state then return false end;local d=state.data
 local t=cat=='Homes'and d.rta.ownedHomes or cat=='Weapons'and d.rta.ownedWeapons or cat=='Vehicles'and d.rta.ownedVehicles or cat=='Boats'and d.content.boats or cat=='Aircraft'and d.content.aircraft or cat=='Businesses'and d.content.businesses
 return t and t[id]
end
local function offerLabel(key,b)
 local o=C.Offers[key];if not o then return end
 b.Text='R$ '..(priceCache[key]or o.robux)..' · Roblox 구매'
 if not priceCache[key]and not pricePending[key]then pricePending[key]=true;task.spawn(function()
  local ok,info=pcall(function()return Market:GetProductInfoAsync(o.id,o.kind=='Pass'and Enum.InfoType.GamePass or Enum.InfoType.Product)end)
  pricePending[key]=nil;if ok and info.PriceInRobux then priceCache[key]=info.PriceInRobux;if b.Parent then b.Text='R$ '..info.PriceInRobux..' · Roblox 구매'end end
 end)end
end
local function card(title,desc,accent)
 local f=ui('Frame',content,{Name=title,BackgroundColor3=cardColor,BorderSizePixel=0});ui('Frame',f,{Size=UDim2.new(1,0,0,3),BackgroundColor3=accent or gold,BorderSizePixel=0})
 text(f,title,UDim2.fromOffset(14,14),UDim2.new(1,-28,0,27),white,Enum.Font.GothamBold)
 text(f,desc,UDim2.fromOffset(14,45),UDim2.new(1,-28,0,68),muted)
 local actions=ui('Frame',f,{Position=UDim2.fromOffset(12,120),Size=UDim2.new(1,-24,0,56),BackgroundTransparency=1});ui('UIListLayout',actions,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5)})
 return actions,f
end
local function act(parent,label,fn,width)return button(parent,label,fn,UDim2.new(width or 1,-3,0,50))end
local function buyActions(parent,cat,id,def)
 if def.offer then local b=act(parent,'구매',function()ask('Offer',def.offer)end);offerLabel(def.offer,b)
 else act(parent,'$'..(def.price or def.seedPrice)..' 구매',function()ask('Buy',cat,id,1)end)end
end
local function clear()for _,v in content:GetChildren()do if v:IsA('GuiObject')then v:Destroy()end end end
local function ordered(t)local ids={};for id in t do table.insert(ids,id)end;table.sort(ids);return ids end
render=function()
 clear();if not state then hint.Text='상점 정보에 연결 중입니다.';return end
 local d=state.data;local s=d.content
 balance.Text=('$%s   /   은행 $%s%s'):format(d.cash,d.bank,state.temporary and'  ·  Studio 테스트 데이터'or'')
 hint.Text='목록은 어디서나 볼 수 있습니다. 구매·출고·작업은 해당 부지의 접수처에서 진행하세요.'
 if plotId then
  local b=card('선택 부지  '..plotId,'주거·농사·사업 부지는 서버에서 한 명에게 배정됩니다. 건물은 직접 배치합니다.')
  act(b,'이 부지 배정받기',function()ask('ClaimPlot',plotId)end)
 end
 heading.Text=category=='Fish'and'FISHING  /  물고기 매입'or('RTA  /  '..category)
 nav.Visible=category~='Fish'
 if category=='Fish'then
  local total,count=0,0
  for id,n in s.fish do local def=C.Fish[id];if def and n>0 then total+=def.value*n;count+=n end end
  hint.Text='잡은 물고기를 이 상점에서 판매하세요. 어종별 가격과 보유 수량을 확인할 수 있습니다.'
  local sale=card('어획물 전체 판매',('총 %d마리  /  매입가 $%d'):format(count,total))
  act(sale,count>0 and('$'..total..' 받고 판매')or'판매할 물고기가 없습니다',function()if count>0 then ask('SellFish')end end)
  for _,id in ordered(C.Fish)do local def=C.Fish[id];local n=s.fish[id]or 0
   if n>0 then card(def.name,('보유 %d마리\n마리당 $%d  /  합계 $%d'):format(n,def.value,n*def.value))end
  end
 elseif category=='Crops'then
  hint.Text='농사 부지를 배정받은 뒤 씨앗을 선택하고 빈 밭에 심으세요. 돈나무 보상: $500 50% / $1500 30% / $5000 20%. 제한 계정은 고정 $1700.'
  for i=1,12 do local crop=s.garden[tostring(i)];local b=card('밭 '..i,crop and(C.Crops[crop.crop].name..' · '..math.max(0,crop.readyAt-state.time)..'초 남음')or('선택 씨앗: '..C.Crops[selection.crop].name))
   if crop then act(b,'수확',function()ask('Harvest',i)end)else act(b,'선택 씨앗 심기',function()ask('Plant',selection.crop,i)end)end
  end
  for _,id in ordered(C.Crops)do local def=C.Crops[id];local b=card(def.name,('씨앗 %d개 / 성장 %d초\n수확 $%d%s'):format(s.seeds[id]or 0,def.seconds,def.value,def.perennial and' · 반복 수확'or''))
   act(b,'선택',function()selection.crop=id;render()end,.35)
   local buy=act(b,def.offer and'씨앗 팩'or('$'..def.seedPrice..' 씨앗'),function()if def.offer then ask('Offer',def.offer)else ask('Buy','Crops',id,1)end end,.65)
   if def.offer then offerLabel(def.offer,buy)end
  end
 elseif category=='Homes'or category=='Vehicles'or category=='Boats'or category=='Aircraft'or category=='Weapons'then
  if category~='Homes'and category~='Weapons'then local b=card('차고 관리','보유한 차량은 해당 딜러샵에서 출고할 수 있습니다. 한 번에 1대만 운행합니다.');act(b,'운행 중 차량 반납',function()ask('Despawn')end)end
  if category=='Vehicles'then
   local b=card('차량 뽑기 · $25,000','일반 60% / 고급 25% / 희귀 10% / 영웅 4% / 전설 1%\n중복 차량은 $10,000 환급. 아래 버튼으로 차량별 확률을 확인하세요.')
   act(b,'차량별 확률',function()category='Odds';render()end,.5);act(b,state.randomAllowed and'뽑기'or'이용 제한',function()if state.randomAllowed then ask('RollVehicle')end end,.5)
  end
  for _,id in ordered(C[category])do local def=C[category][id];local has=owned(category,id);local description=has and'보유 중'or'미보유'
   if category=='Homes'then description..=def.large and' / 중앙 대형 부지 전용'or' / 일반 주거 부지 가능'
   elseif category=='Weapons'then description..=(' / 탄창 %d발 / 피해 %d'):format(def.magazine,def.damage)
   else description..=(' / 최고 속도 %d%s'):format(def.speed,def.taxi and' / 택시 업무 가능'or'')end
   local b=card(def.name,description)
   if has then
    if category=='Homes'then act(b,'내 주거 부지에 배치',function()ask('PlaceHome',id)end)
    elseif category=='Weapons'then act(b,'장착',function()equip(id)end,.4);act(b,'탄약 보급 $80',function()ask('Ammo',id)end,.6)
    else act(b,'딜러샵에서 출고',function()ask('Spawn',category,id)end)end
   else buyActions(b,category,id,def)end
  end
  if category=='Weapons'then
   local b=card('수류탄',('보유 %d개 / 사용 시 1개 소모'):format(s.tokens.Grenades or 0));act(b,'장착',function()equip('Grenade')end,.4);local buy=act(b,'5개 보급',function()ask('Offer','GrenadeKit')end,.6);offerLabel('GrenadeKit',buy)
   local l=card('유탄 발사기','탄창 4발 / 예비탄 12발 / 근처 대상에 범위 피해')
   if d.rta.ownedWeapons.Launcher then act(l,'장착',function()equip('Launcher')end,.4);act(l,'탄약 보급 $80',function()ask('Ammo','Launcher')end,.6)else local buy=act(l,'구매',function()ask('Offer','Launcher')end);offerLabel('Launcher',buy)end
  end
 elseif category=='Businesses'then
  local b=card('사업장 관리','진행 중인 생산·세탁을 완료 후 수령하세요. 2배권은 보관함에서 사용한 뒤 적용됩니다.')
  act(b,'생산 정산',function()ask('Collect','Production',false)end,.5);act(b,'공장 2배 사용',function()ask('FactoryBoost')end,.5)
  local b2=card('돈세탁','도난 물품 '..d.rta.stolenGoods..'개 / 2배권 '..(s.tokens.LaundryDouble or 0)..'개')
  act(b2,'일반 정산',function()ask('Collect','Laundry',false)end,.5);act(b2,'2배권 정산',function()ask('Collect','Laundry',true)end,.5)
  for _,id in ordered(C.Businesses)do local def=C.Businesses[id];local b=card(def.name,owned('Businesses',id)and('운영 권한 보유 / '..(s.selectedBusiness==id and'현재 사업장'or'미배치'))or'라이선스 미보유')
   if owned('Businesses',id)then
    act(b,'설비 배치',function()ask('PlaceBusiness',id)end,.45)
    act(b,(id=='Taxi'or id=='Delivery')and'업무 접수'or'작업 시작',function()if id=='Taxi'or id=='Delivery'then ask('StartJob',id)else ask('Produce',id,id=='Laundromat'and math.min(50,d.rta.stolenGoods)or 1)end end,.55)
   else buyActions(b,'Businesses',id,def)end
  end
  local endJob=card('운송 업무',state.job and(state.job.kind..' · '..state.job.target)or'택시나 배달 사업의 접수처에서 시작하세요.');act(endJob,'목적지에서 완료',function()ask('JobFinish')end,.65);act(endJob,'취소',function()ask('CancelJob')end,.35)
 elseif category=='Food'then
  for _,id in ordered(C.Food)do local def=C.Food[id];local b=card(def.name,('보유 %d개 / 회복 %d%s'):format(s.foods[id]or 0,def.heal,def.seconds>0 and(' / '..def.buff..' 10분')or''))
   if(s.foods[id]or 0)>0 then act(b,'먹기',function()ask('UseFood',id)end,.35)end
   local buy=act(b,def.offer and'구매'or('$'..def.price..' 구매'),function()if def.offer then ask('Offer',def.offer)else ask('Buy','Food',id,1)end end,(s.foods[id]or 0)>0 and .65 or 1);if def.offer then offerLabel(def.offer,buy)end
  end
 elseif category=='Stocks'then
  hint.Text='스마트폰 주식 앱에서도 이용할 수 있습니다. 가상 기업·게임머니 전용 / 30초마다 가격 변동 / 매수·매도 수수료 1%'
  if not s.entitlements.StockLicense then local b=card('주식 앱 라이선스','일회성 구매로 가상 주식 거래를 영구 해금합니다.');local buy=act(b,'구매',function()ask('Offer','StockLicense')end);offerLabel('StockLicense',buy)end
  for _,id in ordered(C.Stocks)do local def=C.Stocks[id];local b=card(def.name..' · '..id,('$%d / 보유 %d주'):format(state.prices[id],s.stocks[id]or 0));act(b,'1주 매수',function()ask('Trade',id,1,false)end,.5);act(b,'1주 매도',function()ask('Trade',id,1,true)end,.5)end
 elseif category=='Premium'then
  hint.Text='반복 구매 항목은 보관함에 지급됩니다. Roblox 구매창의 최종 가격을 확인하세요.'
  local b=card('구매 내역 복원','게임패스는 재접속 시 자동 반영됩니다. 개발자 상품은 영수증을 확인한 뒤 한 번만 지급합니다.');act(b,'구매 내역 다시 확인',function()ask('RestorePurchases')end)
  for _,key in ordered(C.Offers)do local o=C.Offers[key];local b=card(o.name,o.description);local buy=act(b,'구매',function()ask('Offer',key)end);offerLabel(key,buy)end
 elseif category=='Odds'then
  hint.Text='구매 전 차량별 확률입니다. 모든 결과 합계 100%. 중복 시 $10,000 환급. 제한 계정은 뽑기를 이용할 수 없습니다.'
  local counts={};for _,v in C.Vehicles do if v.rarity then counts[v.rarity]=(counts[v.rarity]or 0)+1 end end
  for _,id in ordered(C.Vehicles)do local v=C.Vehicles[id];if v.rarity then card(v.name,('%.6f%% · %s'):format(C.VehicleRoll.weights[v.rarity]/counts[v.rarity],v.rarity))end end
 elseif category=='Golf'then
  hint.Text='무료 골프. 티박스 옆에서 방향과 힘을 설정하고 샷을 누르세요. 홀인 보상 $150.'
  local a=card('힘 '..selection.power,'10~100 사이로 조절하세요.');act(a,'힘 -10',function()selection.power=math.max(10,selection.power-10);render()end,.5);act(a,'힘 +10',function()selection.power=math.min(100,selection.power+10);render()end,.5)
  local b=card('방향 '..selection.angle..'°','0°는 홀을 향합니다.');act(b,'-5°',function()selection.angle=math.max(-180,selection.angle-5);render()end,.5);act(b,'+5°',function()selection.angle=math.min(180,selection.angle+5);render()end,.5)
  for i=1,3 do local b=card(i..'번 홀','티박스에서 샷을 진행하세요.');act(b,'샷',function()ask('GolfShot','Golf_'..i,selection.power,selection.angle)end)end
 elseif category=='Robbery'then
  local b=card('은행 금고',state.robbery and('개방까지 '..math.max(0,state.robbery.readyAt-state.time)..'초')or'금고를 여는 동안 주변에 머물러야 합니다. 돈세탁 라이선스가 있으면 물품도 획득합니다.')
  act(b,'금고 개방',function()ask('RobberyStart')end,.5);act(b,'전리품 수령',function()ask('RobberyCollect')end,.5)
 end
end
for _,entry in categories do local b=button(nav,entry[2],function()category=entry[1];plotId=nil;render()end,UDim2.fromOffset(80,36));b.Name=entry[1]end
local function open(cat,id)category=cat or category;plotId=id;panel.Visible=true;render();ask('Sync')end
local openEvent=Instance.new('BindableEvent');openEvent.Name='RTAContentOpen';openEvent.Parent=player.PlayerGui;openEvent.Event:Connect(function(cat)open(cat)end)
net.State.OnClientEvent:Connect(function(s)
 state=s;receivedAt=os.clock();notice.Text=s.message or''
 if s.menu then local menus={Home='Homes',LargeHome='Homes',Business='Businesses',Farm='Crops',Bank='Robbery',Public='Weapons',Fishing='Fish',Shop='Premium',Dealer='Vehicles',Golf='Golf',Robbery='Robbery'};local cat=s.plotId=='HELI_DEALER'and'Aircraft'or s.plotId=='BOAT_DEALER'and'Boats'or C[s.menu]and s.menu or menus[s.menu];if cat then open(cat,s.plotId and s.plotId:match('^HOME')and s.plotId or s.plotId and(s.plotId:match('^BIZ')or s.plotId:match('^FARM'))and s.plotId or nil)end end
 if panel.Visible then render()end
 marker.Enabled=s.job~=false;if s.job then waypoint.Position=s.job.position;mission.Text=s.job.kind..'  /  '..s.job.stage..'\n'..s.job.target..'  ·  목적지에서 [E]'else mission.Text=''end
end)
net.Purchase.OnClientEvent:Connect(function(o)if type(o)~='table'or type(o.id)~='number'or o.id<=0 then return end;if o.kind=='Pass'then Market:PromptGamePassPurchase(player,o.id)elseif o.kind=='Product'then Market:PromptProductPurchase(player,o.id)end end)
UIS.InputBegan:Connect(function(input,processed)if processed then return end;if input.KeyCode==Enum.KeyCode.E and state and state.job then ask('JobFinish')end end)
local lift=0
local function liftAction(name,status)if status==Enum.UserInputState.Begin then lift=name=='RTAClimb'and 1 or-1 elseif status==Enum.UserInputState.End or status==Enum.UserInputState.Cancel then lift=0 end;return Enum.ContextActionResult.Pass end
CAS:BindAction('RTAClimb',liftAction,true,Enum.KeyCode.Space);CAS:BindAction('RTADescend',liftAction,true,Enum.KeyCode.LeftControl);CAS:SetTitle('RTAClimb','상승');CAS:SetTitle('RTADescend','하강');CAS:SetPosition('RTAClimb',UDim2.fromScale(.8,.55));CAS:SetPosition('RTADescend',UDim2.fromScale(.9,.55))
local driveTime,syncTime=0,0
Run.Heartbeat:Connect(function(dt)
 local cam=workspace.CurrentCamera;if cam then scale.Scale=math.min(1,(cam.ViewportSize.X-24)/1010,(cam.ViewportSize.Y-40)/680)end
 driveTime+=dt;syncTime+=dt
 if driveTime>=.08 then driveTime=0;local ch=player.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local seat=h and h.SeatPart
  for _,name in {'RTAClimb','RTADescend'}do local b=CAS:GetButton(name);if b then b.Visible=seat~=nil and seat.Parent:GetAttribute('VehicleCategory')=='Aircraft'end end
  if seat and seat:IsA('VehicleSeat')and seat.Parent:GetAttribute('OwnerUserId')==player.UserId then net.Drive:FireServer(seat.ThrottleFloat,seat.SteerFloat,lift)end
 end
 if syncTime>10 then syncTime=0;ask('Sync')end
end)
for i=1,12 do if state then break end;ask('Sync');task.wait(1)end
