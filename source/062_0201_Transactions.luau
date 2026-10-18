-- ServerScriptService.RTA.Transactions. Pure, non-yielding state mutations.
-- Caller MUST validate live profile, character, point proximity, cooldown, and rate.
-- Never accept prices/rewards/timestamps/catalog tables from a client.
local T={}
local function qty(n,max)
 return type(n)=='number' and n==n and n>=1 and n<=max and n%1==0
end
local function room(d,amount,c)
 return d.cash+amount<=c.Limits.balance
end
local function count(t) local n=0 for _ in pairs(t) do n+=1 end return n end
function T.purchase(d,c,category,id)
 local field=({Weapons='ownedWeapons',Vehicles='ownedVehicles',Armor='ownedArmor'})[category]
 local item=field and c[category][id]
 if not item then return false,'없는 상품입니다.' end
 local owned=d.rta[field]
 if owned[id] then return false,'이미 소유한 상품입니다.' end
 if count(owned)>=c.Limits.inventory then return false,'보유 한도입니다.' end
 if d.cash<item.price then return false,'소지금이 부족합니다.' end
 d.cash-=item.price owned[id]=true
 return true,item.name..' 구매 완료'
end
function T.selectBusiness(d,c,id)
 local def=c.Businesses[id]
 if not def then return false,'없는 사업 분야입니다.' end
 if d.rta.businessType then return false,'이미 사업 분야를 선택했습니다.' end
 -- Owners of the original v1 business may select a sector once, without paying again.
 if not d.business and d.bank<def.price then return false,'은행 잔액이 부족합니다.' end
 if not d.business then d.bank-=def.price end
 d.business=true d.rta.businessType=id
 return true,def.name..' 사업 시작'
end
function T.startProduction(d,c,now)
 local r=d.rta local def=c.Businesses[r.businessType]
 if not def or r.businessType=='Laundromat' then return false,'생산 가능한 사업체가 없습니다.' end
 if r.production then return false,'진행 중인 생산을 먼저 수령하세요.' end
 if r.stock>=c.Limits.goods then return false,'재고가 가득 찼습니다.' end
 if d.cash<def.cost then return false,'재료비가 부족합니다.' end
 d.cash-=def.cost r.production={finishAt=now+def.seconds}
 return true,def.product..' 생산 중'
end
function T.collectProduction(d,c,now)
 local r=d.rta
 if not r.production or now<r.production.finishAt then return false,'생산이 완료되지 않았습니다.' end
 if r.stock>=c.Limits.goods then return false,'재고가 가득 찼습니다.' end
 r.production=false r.stock+=1
 return true,'생산품 수령 완료'
end
function T.sellStock(d,c,quantity)
 local r=d.rta local def=c.Businesses[r.businessType]
 if not def or r.businessType=='Laundromat' or not qty(quantity,50) or quantity>r.stock then return false,'판매할 재고가 없습니다.' end
 local amount=def.revenue*quantity
 if not room(d,amount,c) then return false,'소지금 한도입니다.' end
 r.stock-=quantity d.cash+=amount d.orders=math.min(c.Limits.balance,d.orders+quantity)
 return true,'판매 수익 ₩'..amount
end
function T.startWash(d,c,quantity,now)
 local r=d.rta local def=c.Businesses.Laundromat
 if r.businessType~='Laundromat' then return false,'현금세탁소가 필요합니다.' end
 if r.wash then return false,'세탁기가 사용 중입니다.' end
 if not qty(quantity,50) or quantity>r.stolenGoods then return false,'세탁할 물품이 부족합니다.' end
 if r.cleanGoods+quantity>c.Limits.goods then return false,'보관 한도입니다.' end
 local cost=quantity*def.cost
 if d.cash<cost then return false,'세탁 비용이 부족합니다.' end
 d.cash-=cost r.stolenGoods-=quantity r.wash={quantity=quantity,finishAt=now+def.seconds}
 return true,'세탁기에 물품을 넣었습니다.'
end
function T.collectWash(d,c,now)
 local r=d.rta
 if r.businessType~='Laundromat' or not r.wash or now<r.wash.finishAt then return false,'세탁이 완료되지 않았습니다.' end
 if r.cleanGoods+r.wash.quantity>c.Limits.goods then return false,'보관 한도입니다.' end
 r.cleanGoods+=r.wash.quantity r.wash=false
 return true,'세탁한 물품 수령 완료'
end
function T.sellCleanGoods(d,c,quantity)
 local r=d.rta
 if r.businessType~='Laundromat' or not qty(quantity,50) or quantity>r.cleanGoods then return false,'판매할 세탁 물품이 없습니다.' end
 local amount=quantity*c.Businesses.Laundromat.revenue
 if not room(d,amount,c) then return false,'소지금 한도입니다.' end
 r.cleanGoods-=quantity d.cash+=amount
 return true,'세탁 물품 판매 ₩'..amount
end
function T.robberyReward(d,c,id)
 local def=c.Robberies[id]
 if not def then return false,'없는 장소입니다.' end
 local goods=d.rta.businessType=='Laundromat' and def.goods or 0
 if not room(d,def.cash,c) or d.rta.stolenGoods+goods>c.Limits.goods then return false,'보상 보관 한도입니다.' end
 -- Non-laundromat owners only collect the cash. Never convert forbidden goods to cash.
 d.cash+=def.cash d.rta.stolenGoods+=goods
 return true,'강도 보상 ₩'..def.cash..' / 물품 '..goods
end
return T
