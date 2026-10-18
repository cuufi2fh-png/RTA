local Players=game:GetService('Players')
local bank=workspace:WaitForChild('RTAHeroDistrict'):WaitForChild('01_PacificReserveBank')
local openApp=game:GetService('ReplicatedStorage'):WaitForChild('RTA'):WaitForChild('OpenApp')
local last={}
for _,p in ipairs(bank:GetDescendants())do
 if p:IsA('BasePart') and p:GetAttribute('InteractionId')=='BankService' then
  local prompt=p:FindFirstChildOfClass('ProximityPrompt')
  if prompt then prompt.Triggered:Connect(function(player)
   local character=player.Character
   local root=character and character:FindFirstChild('HumanoidRootPart')
   local humanoid=character and character:FindFirstChildOfClass('Humanoid')
   if not root or not humanoid or humanoid.Health<=0 or (root.Position-p.Position).Magnitude>12 then return end
   if player:GetAttribute('RTAInCustody') or os.clock()-(last[player] or -10)<1 then return end
   last[player]=os.clock();openApp:FireClient(player,'Bank')
  end)end
 end
end
Players.PlayerRemoving:Connect(function(player)last[player]=nil end)
