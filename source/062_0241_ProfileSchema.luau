-- ServerScriptService.PlayOS.ProfileSchema; pure migration/validation, no yielding.
local S = {}
local sectors = {Restaurant=true, CashFactory=true, JewelryFactory=true, Laundromat=true, Cafe=true}
local function integer(n, maximum)
 return type(n)=='number' and n==n and n>=0 and n<=maximum and n%1==0
end
local function identifier(s)
 return type(s)=='string' and #s>=1 and #s<=48 and s:match('^[%w_]+$')~=nil
end
local function ownership(t)
 if type(t)~='table' then return false end
 local count=0
 for id,value in pairs(t) do
  count+=1
  if count>256 or not identifier(id) or value~=true then return false end
 end
 return true
end
local function fields(t, allowed)
 if type(t)~='table' then return false end
 for k in pairs(t) do if not allowed[k] then return false end end
 return true
end
function S.copy(value)
 if type(value)~='table' then return value end
 local result={}
 for k,v in pairs(value) do result[k]=S.copy(v) end
 return result
end
function S.extension()
 return {businessType=false,ownedWeapons={},ownedVehicles={},ownedArmor={},equippedArmor=false,
  stolenGoods=0,cleanGoods=0,stock=0,wash=false,production=false,graphics='Auto'}
end
function S.normalize(d, config)
 if type(d)~='table' or (d.version~=1 and d.version~=2) then return nil end
 for _,k in ipairs({'cash','bank','orders'}) do if not integer(d[k],config.MaxBalance) then return nil end end
 if type(d.job)~='string' or not config.Jobs[d.job] or type(d.business)~='boolean' then return nil end
 if d.version==1 then
  -- Project v1 has no expansion fields. Unexpected extension is refused, not discarded.
  if d.rta~=nil then return nil end
 else
  local r=d.rta
  if not fields(r,{businessType=true,ownedWeapons=true,ownedVehicles=true,ownedArmor=true,equippedArmor=true,
   stolenGoods=true,cleanGoods=true,stock=true,wash=true,production=true,graphics=true}) then return nil end
  if r.businessType~=false and not sectors[r.businessType] then return nil end
  if r.businessType~=false and not d.business then return nil end
  for _,k in ipairs({'ownedWeapons','ownedVehicles','ownedArmor'}) do if not ownership(r[k]) then return nil end end
  if r.equippedArmor~=false and (not identifier(r.equippedArmor) or not r.ownedArmor[r.equippedArmor]) then return nil end
  for _,k in ipairs({'stolenGoods','cleanGoods','stock'}) do if not integer(r[k],1000000) then return nil end end
  if r.graphics~='Auto' and r.graphics~='Low' and r.graphics~='Medium' and r.graphics~='High' then return nil end
  if r.wash~=false then
   if r.businessType~='Laundromat' or not fields(r.wash,{quantity=true,finishAt=true})
    or not integer(r.wash.quantity,50) or r.wash.quantity<1 or not integer(r.wash.finishAt,100000000000) then return nil end
  end
  if r.production~=false then
   if not r.businessType or r.businessType=='Laundromat' or not fields(r.production,{finishAt=true})
    or not integer(r.production.finishAt,100000000000) then return nil end
  end
 end
 -- Only schema-owned keys are stored. Nested ownership remains independent of live data.
 return {version=2,cash=d.cash,bank=d.bank,job=d.job,business=d.business,orders=d.orders,
  rta=d.version==1 and S.extension() or S.copy(d.rta)}
end
return S
