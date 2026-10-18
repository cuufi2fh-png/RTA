-- Non-yielding mutations. The service validates proximity, session, ownership and policy first.
local T={}
local ownerFields={Homes='ownedHomes',Weapons='ownedWeapons',Vehicles='ownedVehicles'}
function T.quantity(n,max)return type(n)=='number'and n==n and n%1==0 and n>=1 and n<=max end
local function credit(d,c,n)if d.cash+n>c.Limits.balance then return false end d.cash+=n return true end
local function add(t,id,n)local v=t[id]or 0;if v+n>1000000 then return false end t[id]=v+n;return true end
function T.owns(d,category,id)
 local field=ownerFields[category]
 local set=field and d.rta[field]or category=='Boats'and d.content.boats or category=='Aircraft'and d.content.aircraft or category=='Businesses'and d.content.businesses
 return set and set[id]==true
end
function T.buy(d,c,category,id,quantity)
 local def=c[category]and c[category][id]
 if not def then return false,'없는 상품입니다.'end
 if def.offer or def.premium then return false,'로벅스 상품은 구매 버튼을 이용하세요.'end
 quantity=quantity or 1;if not T.quantity(quantity,99)then return false,'수량을 확인하세요.'end
 local cost=def.price or def.seedPrice
 if not cost or cost<=0 then return false,'구매할 수 없는 상품입니다.'end
 if category~='Food'and category~='Crops'then quantity=1;if T.owns(d,category,id)then return false,'이미 보유하고 있습니다.'end end
 if d.cash<cost*quantity then return false,'게임머니가 부족합니다.'end
 local set=ownerFields[category]and d.rta[ownerFields[category]]or category=='Boats'and d.content.boats or category=='Aircraft'and d.content.aircraft or category=='Businesses'and d.content.businesses
 if category=='Food'or category=='Crops'then local bag=category=='Food'and d.content.foods or d.content.seeds;if not add(bag,id,quantity)then return false,'보관함 한도입니다.'end
 elseif set then set[id]=true else return false,'지원하지 않는 상품입니다.'end
 d.cash-=cost*quantity;return true,def.name..' 구매 완료'
end
function T.grant(d,c,g)
 local s=d.content
 if g.type=='cash'then return credit(d,c,g.amount)
 elseif g.type=='seed'then return add(s.seeds,g.item,g.amount)
 elseif g.type=='food'then return add(s.foods,g.item,g.amount)
 elseif g.type=='token'then local ok=add(s.tokens,g.key,g.amount);if ok and g.key=='Grenades'then d.rta.ownedWeapons.Grenade=true end;return ok
 elseif g.type=='boost'then return add(s.tokens,g.key..'Boost',1)
 elseif g.type=='entitlement'then s.entitlements[g.key]=true
 elseif g.type=='home'then d.rta.ownedHomes[g.item]=true
 elseif g.type=='vehicle'then d.rta.ownedVehicles[g.item]=true
 elseif g.type=='weapon'then d.rta.ownedWeapons[g.item]=true
 elseif g.type=='boat'then s.boats[g.item]=true
 elseif g.type=='aircraft'then s.aircraft[g.item]=true
 else return false end
 if s.entitlements.FactoryLicense then s.businesses.Factory=true end
 if s.entitlements.LaundryLicense then s.businesses.Laundromat=true end
 if s.entitlements.Launcher then d.rta.ownedWeapons.Launcher=true end
 return true
end
function T.plant(d,c,crop,slot,now)
 if not T.quantity(slot,12)or not c.Crops[crop]then return false,'작물과 밭을 확인하세요.'end
 local s=d.content;local key=tostring(slot)
 if s.garden[key]then return false,'이미 작물이 자라고 있습니다.'end
 if (s.seeds[crop]or 0)<1 then return false,'씨앗이 부족합니다.'end
 s.seeds[crop]-=1;s.garden[key]={crop=crop,readyAt=now+c.Crops[crop].seconds};return true,'심기 완료'
end
function T.harvest(d,c,slot,now,randomUnit,randomAllowed)
 if not T.quantity(slot,12)then return false,'밭을 확인하세요.'end
 local s=d.content;local key=tostring(slot);local crop=s.garden[key];local def=crop and c.Crops[crop.crop]
 if not def or crop.readyAt>now then return false,'아직 수확할 수 없습니다.'end
 local amount=def.value*def.yieldCount
 if crop.crop=='MoneyTree'then
  amount=1700
  if randomAllowed then local roll=randomUnit*100;local cumulative=0;for _,r in c.MoneyTreeRewards do cumulative+=r.weight;if roll<cumulative then amount=r.amount;break end end end
 elseif (s.boosts.Harvest or 0)>now then amount=math.floor(amount*1.25)end
 if not credit(d,c,amount)then return false,'소지금 한도입니다.'end
 if def.perennial then crop.readyAt=now+def.seconds else s.garden[key]=nil end
 return true,'수확 +$'..amount
end
function T.sellFish(d,c)
 local amount=0;for id,n in d.content.fish do local def=c.Fish[id];if def then amount+=n*def.value end end
 if amount==0 then return false,'판매할 물고기가 없습니다.'end
 if not credit(d,c,amount)then return false,'소지금 한도입니다.'end d.content.fish={};return true,'물고기 판매 +$'..amount
end
function T.beginProduction(d,c,kind,now,amount)
 local s=d.content;if not s.businesses[kind]or not c.Businesses[kind]then return false,'사업 라이선스가 필요합니다.'end
 if kind=='Taxi'or kind=='Delivery'then return false,'운송 업무를 받아주세요.'end
 if kind=='Laundromat'then
  if s.laundry then return false,'진행 중인 세탁물을 수령하세요.'end
  if not T.quantity(amount,50)or d.rta.stolenGoods<amount then return false,'도난 물품이 부족합니다.'end
  d.rta.stolenGoods-=amount;s.laundry={kind=kind,readyAt=now+c.Businesses[kind].seconds,amount=amount}
 else
  if s.production then return false,'진행 중인 생산물을 수령하세요.'end
  local cost=kind=='Factory'and 150 or 45;if d.cash<cost then return false,'재료비가 부족합니다.'end
  d.cash-=cost;s.production={kind=kind,readyAt=now+c.Businesses[kind].seconds,amount=1}
 end
 return true,'작업을 시작했습니다.'
end
function T.collectProduction(d,c,laundry,useDouble,now)
 local s=d.content;local field=laundry and'laundry'or'production';local p=s[field]
 if not p or now<p.readyAt then return false,'작업이 아직 끝나지 않았습니다.'end
 local amount=c.Businesses[p.kind].revenue*p.amount
 if laundry and useDouble then if (s.tokens.LaundryDouble or 0)<1 then return false,'세탁 2배권이 없습니다.'end;amount*=2 end
 if not laundry and p.kind=='Factory'and(s.boosts.Factory or 0)>now then amount*=2 end
 if not credit(d,c,amount)then return false,'소지금 한도입니다.'end
 if laundry and useDouble then s.tokens.LaundryDouble-=1 end
 s[field]=false;return true,'작업 정산 +$'..amount
end
function T.stockPrice(c,id,now)
 local def=c.Stocks[id];if not def then return nil end
 local tick=math.floor(now/30)
 return math.max(5,math.floor(def.base+math.sin(tick*.31+def.phase)*def.amplitude+math.sin(tick*.071+def.phase*2)*def.amplitude*.4))
end
function T.trade(d,c,id,quantity,sell,now)
 if not d.content.entitlements.StockLicense then return false,'주식 앱 라이선스가 필요합니다.'end
 if not T.quantity(quantity,1000)then return false,'거래 수량은 1~1000주입니다.'end
 local price=T.stockPrice(c,id,now);if not price then return false,'없는 종목입니다.'end
 local n=d.content.stocks[id]or 0
 if sell then
  if n<quantity then return false,'보유 주식이 부족합니다.'end
  local revenue=math.floor(price*quantity*.99);if not credit(d,c,revenue)then return false,'소지금 한도입니다.'end
  d.content.stocks[id]=n-quantity;return true,'매도 완료 +$'..revenue
 else
  local cost=math.ceil(price*quantity*1.01);if d.cash<cost or n+quantity>1000000 then return false,'잔액 또는 보유 한도를 확인하세요.'end
  d.cash-=cost;d.content.stocks[id]=n+quantity;return true,'매수 완료 -$'..cost
 end
end
function T.vehicleOdds(c)
 local counts={};for _,v in c.Vehicles do if v.rarity then counts[v.rarity]=(counts[v.rarity]or 0)+1 end end
 local list={};for id,v in c.Vehicles do if v.rarity then table.insert(list,{id=id,name=v.name,chance=c.VehicleRoll.weights[v.rarity]/counts[v.rarity]})end end
 table.sort(list,function(a,b)return a.id<b.id end);return list
end
function T.rollVehicle(d,c,randomUnit,policyAllowed)
 if not policyAllowed then return false,'이 계정에서는 유료 무작위 아이템을 이용할 수 없습니다.'end
 if d.cash<c.VehicleRoll.price then return false,'게임머니가 부족합니다.'end
 local odds=T.vehicleOdds(c);local roll=randomUnit*100;local cumulative=0;local selected=odds[#odds]
 for _,v in odds do cumulative+=v.chance;if roll<cumulative then selected=v;break end end
 d.cash-=c.VehicleRoll.price
 local dupe=d.rta.ownedVehicles[selected.id]==true
 if dupe then d.cash=math.min(c.Limits.balance,d.cash+c.VehicleRoll.duplicateRefund)else d.rta.ownedVehicles[selected.id]=true end
 return true,selected.name..(dupe and' · 중복 보상 $'..c.VehicleRoll.duplicateRefund or' 획득!'),selected.id
end
return T
