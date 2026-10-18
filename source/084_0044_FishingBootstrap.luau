-- Fishing also boots when the user is rebuilding or replacing the city map.
local P=require(game.ServerScriptService.PlayOS.Profiles)
local C=require(game.ReplicatedStorage.RTAContent.Catalog)
local service=require(script.Parent.Fishing).start(P,C)
require(game.ServerScriptService.FishingSystem.Observers.FishingRodObserver).Start()
local net=game.ReplicatedStorage.FishingSystem.Remotes
local limits={}
net.Equipment.OnServerEvent:Connect(function(p,kind)
 if kind~='Basic'and kind~='Premium'and kind~='Store'and kind~='Sell'then return end
 local now=os.clock();if now-(limits[p]or 0)<.5 then return end;limits[p]=now
 local ok,message
 if kind=='Store'then
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if h then h:UnequipTools()end;ok=true;message='낚싯대를 넣었습니다.'
 elseif kind=='Sell'then
  local ch=p.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart');local map=workspace:FindFirstChild('RTA_IslandMap');local points=map and map:FindFirstChild('ActivityPoints');local near=false
  if points and root then for _,id in {'Fishing','FishShop'}do local v=points:FindFirstChild(id);if v and(v.Position-root.Position).Magnitude<(id=='Fishing'and 80 or 24)then near=true end end end
  for _,v in game:GetService('CollectionService'):GetTagged('RTAFishShop')do
   local part=v:IsA('BasePart')and v or v:IsA('Model')and v.PrimaryPart
   if root and part and(part.Position-root.Position).Magnitude<24 then near=true;break end
  end
  local d=P.get(p)
  if near and d then ok,message=require(script.Parent.Transactions).sellFish(d,C);if ok then local changed=game.ServerScriptService.PlayOS:FindFirstChild('Changed');if changed then changed:Fire(p)end end
  else ok=false;message='낚시 상점에서 판매할 수 있습니다.'end
 else ok,message=service.equip(p,kind)end
 net.Equipment:FireClient(p,ok,message)
end)
game.Players.PlayerRemoving:Connect(function(p)limits[p]=nil end)
script:SetAttribute('Booted',true)
if game:GetService('RunService'):IsStudio()then
 local b=Instance.new('BindableFunction');b.Name='RTAFishingTestBridge';b.OnInvoke=function()return {fishing=service,profiles=P,catalog=C}end;b.Parent=game.ServerStorage
end
