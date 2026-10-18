local Marketplace=game:GetService('MarketplaceService')
local Policy=game:GetService('PolicyService')
local Players=game:GetService('Players')
local M={}
function M.start(P,C,T,send)
 local policies,checking,lastSync={},{},{}
 local products,passes={},{ }
 for key,o in C.Offers do if o.id>0 then if o.kind=='Product'then products[o.id]=o else passes[o.id]=o end end end
 local self={}
 function self.randomAllowed(p)return policies[p]==true end
 function self.loadPolicy(p)
  local ok,result=pcall(function()return Policy:GetPolicyInfoForPlayerAsync(p)end)
  if p.Parent==Players then policies[p]=ok and type(result)=='table'and result.ArePaidRandomItemsRestricted==false end
  return policies[p]==true
 end
 local function syncPass(p,id,o)
  local ok,owns=pcall(function()return Marketplace:UserOwnsGamePassAsync(p.UserId,id)end)
  if not ok or not owns then return false end
  -- Record verified permanent entitlements. Reconciliation runs on every join.
  local d=P.get(p);if not d then return false end
  return T.grant(d,C,o.grant)
 end
 function self.sync(p,force)
  if checking[p]or(not force and os.clock()-(lastSync[p]or-100)<30)then return end
  checking[p]=true;lastSync[p]=os.clock()
  for id,o in passes do if not p.Parent then break end;syncPass(p,id,o);task.wait(.08)end
  checking[p]=nil;if p.Parent then send(p,'구매 내역 동기화 완료')end
 end
 function self.offer(p,key)
  local o=C.Offers[key];local d=P.get(p)
  if not o or o.id<=0 or not d then return false,'상품 연결을 확인하는 중입니다.'end
  -- Random-tree restriction uses a fixed, disclosed expected-value alternative.
  if o.kind=='Pass'then
   local ok,owns=pcall(function()return Marketplace:UserOwnsGamePassAsync(p.UserId,o.id)end)
   if not ok then return false,'구매 내역 확인에 실패했습니다. 잠시 후 다시 시도하세요.'end
   if owns then syncPass(p,o.id,o);return false,'이미 소유한 패스입니다. 보유 내역을 갱신했습니다.'end
  end
  return true,{id=o.id,kind=o.kind,key=key}
 end
 Marketplace.ProcessReceipt=function(receipt)
  local o=products[receipt.ProductId]
  local p=Players:GetPlayerByUserId(receipt.PlayerId)
  if not o or not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
  local ok=P.commitReceipt(p,tostring(receipt.PurchaseId),function(d)return T.grant(d,C,o.grant)end)
  if not ok then return Enum.ProductPurchaseDecision.NotProcessedYet end
  send(p,o.name..' 지급 완료');return Enum.ProductPurchaseDecision.PurchaseGranted
 end
 Marketplace.PromptGamePassPurchaseFinished:Connect(function(p,id,purchased)
  local o=passes[id];if purchased and o then task.spawn(function()if syncPass(p,id,o)then send(p,o.name..' 해금 완료')end end)end
 end)
 Players.PlayerRemoving:Connect(function(p)policies[p]=nil;checking[p]=nil;lastSync[p]=nil end)
 return self
end
return M
