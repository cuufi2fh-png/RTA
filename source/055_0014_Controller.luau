local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local Run=game:GetService('RunService')
local Net=RS:WaitForChild('RTA')
local C=require(Net:WaitForChild('Catalog'))
local gui=script.Parent local panel=gui.Panel local content=panel.Content
local menu,state=nil,nil
local receivedAt=0
local function request(a,id,quantity) Net.Request:FireServer(a,id,quantity,Http:GenerateGUID(false)) end
local function button(name,text,fn)
 local b=Instance.new('TextButton') b.Name=name b.Size=UDim2.new(1,-12,0,52) b.BackgroundColor3=Color3.fromRGB(36,40,48)
 b.TextColor3=Color3.fromRGB(255,205,74) b.Font=Enum.Font.GothamMedium b.TextSize=16 b.TextWrapped=true b.Text=text b.Parent=content
 b.Activated:Connect(fn)
end
local function render()
 if not state or not menu then return end
 for _,v in ipairs(content:GetChildren()) do if v:IsA('GuiObject') then v:Destroy() end end
 local d=state.data local r=d.rta
 local names={GunShop='총기 상점',CarShop='차량 상점',ArmorShop='방어구 상점',Business='사업체 접수처'}
 panel.Title.Text=names[menu] or menu
 panel.Balance.Text='현금 ₩'..d.cash..'   은행 ₩'..d.bank
 local category=({GunShop='Weapons',CarShop='Vehicles',ArmorShop='Armor'})[menu]
 if category then
  local field=({Weapons='ownedWeapons',Vehicles='ownedVehicles',Armor='ownedArmor'})[category]
  local ids={} for id in pairs(C[category]) do table.insert(ids,id) end table.sort(ids)
  for _,id in ipairs(ids) do local item=C[category][id] local owned=r[field][id]
   button(id,item.name..(owned and ' · 보유' or ' · ₩'..item.price),function()
    if owned and category=='Armor' then request('EquipArmor',id) else request('Purchase',menu,id) end
   end)
   if owned and category=='Weapons' then button(id..'Ammo',item.name..' 탄약 보충 · ₩80',function() request('BuyAmmo',id) end) end
  end
 elseif menu=='Business' then
  if not r.businessType then
   for _,id in ipairs({'Restaurant','CashFactory','JewelryFactory','Laundromat','Cafe'}) do local def=C.Businesses[id]
    button(id,def.name..(d.business and ' · 기존 소유자 무료 선택' or ' · 은행 ₩'..def.price),function() request('SelectBusiness',id) end)
   end
  elseif r.businessType=='Laundromat' then
   panel.Title.Text='현금세탁소 · 미세탁 '..r.stolenGoods..' / 판매 가능 '..r.cleanGoods
   button('Wash','물품 넣기 · 최대 50개 / 개당 ₩15',function() request('StartWash',nil,math.min(50,r.stolenGoods)) end)
   button('Collect',r.wash and ('세탁 수령 · 완료까지 '..math.max(0,r.wash.finishAt-state.time)..'초') or '세탁 수령',function() request('CollectWash') end)
   button('Sell','세탁한 물품 판매 · 최대 50개',function() request('SellCleanGoods',nil,math.min(50,r.cleanGoods)) end)
  else
   local def=C.Businesses[r.businessType] panel.Title.Text=def.name..' · '..def.product..' 재고 '..r.stock
   button('Produce',def.product..' 생산 · ₩'..def.cost..' / '..def.seconds..'초',function() request('StartProduction') end)
   button('Collect',r.production and ('생산품 수령 · 완료까지 '..math.max(0,r.production.finishAt-state.time)..'초') or '생산품 수령',function() request('CollectProduction') end)
   button('Sell','재고 판매 · 최대 50개',function() request('SellStock',nil,math.min(50,r.stock)) end)
  end
 end
end
panel.Close.Activated:Connect(function() panel.Visible=false menu=nil end)
local stateConnection=Net.State.OnClientEvent:Connect(function(s)
 state=s receivedAt=os.clock() if s.menu then menu=s.menu panel.Visible=true end
 panel.Notice.Text=s.message or '' render()
end)
local elapsed=0
local timerConnection=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.25 then return end elapsed=0
 if not panel.Visible or menu~='Business' or not state then return end
 local r=state.data.rta local timed=r.wash or r.production
 local collect=content:FindFirstChild('Collect')
 if timed and collect then
  local remaining=math.max(0,math.ceil(timed.finishAt-state.time-(os.clock()-receivedAt)))
  collect.Text=remaining>0 and ('완료까지 '..remaining..'초 · 수령 대기') or '완료 · 눌러서 수령'
 end
end)
script.Destroying:Connect(function() stateConnection:Disconnect() timerConnection:Disconnect() end)
request('Sync')
