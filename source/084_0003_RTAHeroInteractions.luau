-- Server-only, local interactions. Does not invent economy or grant currency.
local TweenService=game:GetService('TweenService')
local root=workspace:WaitForChild('RTAHeroDistrict')
local states={}
local function near(player,p)
 local char=player and player.Character;local h=char and char:FindFirstChildOfClass('Humanoid');local r=char and char:FindFirstChild('HumanoidRootPart')
 return h and h.Health>0 and r and (r.Position-p.Position).Magnitude<=14
end
local function perform(p,player)
 if not p:IsDescendantOf(root) or not near(player,p) then return false end
 local s=states[p] if not s or s.busy or os.clock()-s.last<.65 then return false end
 s.busy=true;s.last=os.clock()
 if p:GetAttribute('Door') or p:GetAttribute('VaultSlide') then
  local goal
  if p:GetAttribute('VaultSlide') then goal=s.open and s.closed or s.closed*CFrame.new(0,0,14)
  else local hinge=p:GetAttribute('Hinge');local pivot=CFrame.new(hinge);goal=s.open and s.closed or pivot*CFrame.Angles(0,math.rad(100),0)*pivot:ToObjectSpace(s.closed) end
  local delta=goal*s.closed:Inverse()
  for obj,cf in pairs(s.attachments)do TweenService:Create(obj,TweenInfo.new(1.3,Enum.EasingStyle.Quad),{CFrame=delta*cf}):Play() end
  local t=TweenService:Create(p,TweenInfo.new(1.3,Enum.EasingStyle.Quad),{CFrame=goal});t:Play();t.Completed:Wait();s.open=not s.open;p:SetAttribute('Open',s.open)
 elseif p:GetAttribute('InteractionId')=='Washer' then
  local q=p:FindFirstChildOfClass('ProximityPrompt');q.ActionText='세탁 중';q.Enabled=false
  local bank=p.Parent;local nearest
  for _,v in ipairs(bank:GetChildren())do if v.Name=='WashDisplay' and (v.Position-p.Position).Magnitude<2 then nearest=v break end end
  local label=nearest and nearest:FindFirstChildWhichIsA('TextLabel',true)
  if label then label.Text='WASHING' end
  task.wait(8)
  if label then label.Text='READY' end
  q.ActionText='세탁기 작동';q.Enabled=true
 end
 s.busy=false;return true
end
for _,p in ipairs(root:GetDescendants())do
 if p:IsA('BasePart') and (p:GetAttribute('Door') or p:GetAttribute('VaultSlide') or p:GetAttribute('InteractionId')=='Washer')then
  local s={closed=p.CFrame,open=false,busy=false,last=-math.huge,attachments={}};states[p]=s
  for _,v in ipairs(p.Parent:GetChildren())do if v:IsA('BasePart')then
   local ref=v:FindFirstChild('DoorOwner')
   if (ref and ref.Value==p) or (p:GetAttribute('VaultSlide') and v:GetAttribute('VaultDetail')) then s.attachments[v]=v.CFrame end
  end end
  local q=p:FindFirstChildOfClass('ProximityPrompt');if q then q.Triggered:Connect(function(player)perform(p,player)end)end
 end
end
-- Test hook is server-only and not reachable through remotes.
if game:GetService('RunService'):IsStudio()then local t=Instance.new('BindableFunction');t.Name='StudioInteractionTest';t.OnInvoke=perform;t.Parent=script end
