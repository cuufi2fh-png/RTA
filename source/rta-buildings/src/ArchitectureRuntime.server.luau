local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local Prompts=game:GetService('ProximityPromptService')
local Run=game:GetService('RunService')
local root=workspace:WaitForChild('RTA_IslandMap'):WaitForChild('Architecture')
local moving={};local details={};local last={}
for _,p in root:GetDescendants()do
 if p:IsA('BasePart')then
  if p:GetAttribute('ArchitectureDoor')then moving[p]={open=false,closed=p:GetAttribute('ClosedCFrame'),opened=p:GetAttribute('OpenCFrame'),details={}}
  elseif p:FindFirstChild('DoorOwner')then table.insert(details,p)end
 end
end
for _,p in details do local owner=p.DoorOwner.Value;local state=moving[owner];if state then state.details[p]=state.closed:ToObjectSpace(p.CFrame)end end
local function setDoor(p,state,open)
 if state.open==open then return end
 state.open=open;p:SetAttribute('Open',open)
 local goal=open and state.opened or state.closed
 if state.tween then state.tween:Cancel()end
 state.tween=Tween:Create(p,TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=goal});state.tween:Play()
 for part,relative in state.details do if part.Parent then Tween:Create(part,TweenInfo.new(.4),{CFrame=goal*relative}):Play()end end
end
local running=true
task.spawn(function()
 while running and root.Parent do
  local characters={}
  for _,player in Players:GetPlayers()do local ch=player.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local hrp=ch and ch:FindFirstChild('HumanoidRootPart');if h and h.Health>0 and hrp then table.insert(characters,hrp)end end
  for p,state in moving do
   if not p.Parent then moving[p]=nil
   else
    local open=false
    for _,hrp in characters do if (hrp.Position-state.closed.Position).Magnitude<19 then open=true;break end end
    setDoor(p,state,open)
   end
  end
  task.wait(.2)
 end
end)
local function bankService(p,player)
 if not p or not p:IsA('BasePart')or not p:IsDescendantOf(root)or not p:GetAttribute('BankService')then return false end
 local ch=player.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local hrp=ch and ch:FindFirstChild('HumanoidRootPart')
 if not h or h.Health<=0 or not hrp or(hrp.Position-p.Position).Magnitude>12 or player:GetAttribute('RTAInCustody')then return false end
 if os.clock()-(last[player]or-10)<.6 then return false end;last[player]=os.clock()
 local net=game.ReplicatedStorage:FindFirstChild('RTA');local event=net and net:FindFirstChild('OpenApp')
 if event then event:FireClient(player,'Bank');return true end
 return false
end
local connection=Prompts.PromptTriggered:Connect(function(prompt,player)bankService(prompt.Parent,player)end)
Players.PlayerRemoving:Connect(function(p)last[p]=nil end)
script.Destroying:Connect(function()running=false;connection:Disconnect();for _,s in moving do if s.tween then s.tween:Cancel()end end end)
if Run:IsStudio()then local hook=Instance.new('BindableFunction');hook.Name='ArchitectureTest';hook.OnInvoke=function()return {bankService=bankService,doors=moving}end;hook.Parent=game.ServerStorage end
script:SetAttribute('Ready',true)
