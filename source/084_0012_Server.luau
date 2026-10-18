local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local PlayOS=game:GetService('ServerScriptService'):WaitForChild('PlayOS')
local P=require(PlayOS.Profiles)
local Schema=require(PlayOS.ProfileSchema)
local Net=RS:WaitForChild('RTA')
local C=require(Net.Catalog)
local T=require(script.Parent.Transactions)
local points=workspace:WaitForChild('RTAWorld'):WaitForChild('Points')
local sessions={}
local function near(player,point)
 local ch=player.Character local h=ch and ch:FindFirstChildOfClass('Humanoid')
 local root=ch and ch:FindFirstChild('HumanoidRootPart')
 if not h or h.Health<=0 or not root or not point or not point:IsA('BasePart') then return false end
 return (root.Position-point.Position).Magnitude<=18
end
local function session(p)
 local s=sessions[p]
 if not s then s={tokens=8,at=os.clock(),seen={},order={}} sessions[p]=s end
 return s
end
local function budget(p)
 local s=session(p) local now=os.clock()
 s.tokens=math.min(8,s.tokens+(now-s.at)*3) s.at=now
 if s.tokens<1 then return false end s.tokens-=1 return true
end
local function send(p,message,menu)
 local d=P.get(p) if not d then return end
 Net.State:FireClient(p,{data=Schema.copy(d),message=message or '',menu=menu or false,time=os.time()})
 local changed=PlayOS:FindFirstChild('Changed') if changed then changed:Fire(p) end
end
local allowed={Sync=true,Purchase=true,SelectBusiness=true,StartProduction=true,CollectProduction=true,SellStock=true,StartWash=true,CollectWash=true,SellCleanGoods=true,EquipArmor=true}
local function handle(p,a,id,quantity)
 local d=P.get(p) if not d then return false,'데이터 연결 중입니다.' end
 if a=='Sync' then return true,'' end
 if a=='Purchase' then
  local category=({GunShop='Weapons',CarShop='Vehicles',ArmorShop='Armor'})[id]
  -- Purchase encodes shop in id and product ID in quantity (a bounded string).
  if not category or type(quantity)~='string' or not near(p,points:FindFirstChild(id)) then return false,'상점 NPC 가까이에서 이용하세요.' end
  return T.purchase(d,C,category,quantity)
 end
 if a=='EquipArmor' then
  if not near(p,points:FindFirstChild('ArmorShop')) or not C.Armor[id] or not d.rta.ownedArmor[id] then return false,'소유한 방어구를 방어구 상점에서 장착하세요.' end
  d.rta.equippedArmor=id return true,'방어구 선택 완료'
 end
 if not near(p,points:FindFirstChild('Business')) then return false,'사업체 접수처 가까이에서 이용하세요.' end
 if a=='SelectBusiness' then return T.selectBusiness(d,C,id)
 elseif a=='StartProduction' then return T.startProduction(d,C,os.time())
 elseif a=='CollectProduction' then return T.collectProduction(d,C,os.time())
 elseif a=='SellStock' then return T.sellStock(d,C,quantity)
 elseif a=='StartWash' then return T.startWash(d,C,quantity,os.time())
 elseif a=='CollectWash' then return T.collectWash(d,C,os.time())
 elseif a=='SellCleanGoods' then return T.sellCleanGoods(d,C,quantity) end
 return false,'지원하지 않는 요청입니다.'
end
Net.Request.OnServerEvent:Connect(function(p,a,id,quantity,requestId)
 if not budget(p) or type(a)~='string' or not allowed[a] then return end
 if type(requestId)~='string' or #requestId<1 or #requestId>48 then return end
 if id~=nil and (type(id)~='string' or #id>48) then return end
 if quantity~=nil and type(quantity)~='number' and type(quantity)~='string' then return end
 if type(quantity)=='string' and #quantity>48 then return end
 if type(quantity)=='number' and (quantity~=quantity or math.abs(quantity)>1000000 or quantity%1~=0) then return end
 local s=session(p)
 if s.seen[requestId] then return end
 s.seen[requestId]=true table.insert(s.order,requestId)
 if #s.order>128 then s.seen[table.remove(s.order,1)]=nil end
 local ok,_,message=pcall(handle,p,a,id,quantity)
 if not ok then warn('RTA transaction failed: '..tostring(_)) message='처리 중 오류가 발생했습니다.' end
 send(p,message)
end)
for _,point in ipairs(points:GetChildren()) do
 local prompt=point:FindFirstChildOfClass('ProximityPrompt')
 if prompt and point:GetAttribute('RTAMenu') then
  prompt.Triggered:Connect(function(p)
   if budget(p) and near(p,point) then send(p,'',point.Name) end
  end)
 end
end
Players.PlayerRemoving:Connect(function(p) sessions[p]=nil end)
