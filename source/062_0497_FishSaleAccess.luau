-- Shared SERVER-side location check for both existing sale request routes.
local Collection=game:GetService('CollectionService')
local Access={}
function Access.canSell(player)
 local char=player.Character
 local hum=char and char:FindFirstChildOfClass('Humanoid')
 local root=char and char:FindFirstChild('HumanoidRootPart')
 if not hum or hum.Health<=0 or not root or player:GetAttribute('RTAInCustody')then return false end
 local map=workspace:FindFirstChild('RTA_IslandMap')
 if not map then return false end
 local points=map:FindFirstChild('ActivityPoints')
 local shop=points and points:FindFirstChild('FishShop')
 local candidates={}
 if shop then table.insert(candidates,shop)end
 for _,v in Collection:GetTagged('RTAFishShop')do if v:IsDescendantOf(map)then table.insert(candidates,v:IsA('BasePart')and v or v:IsA('Model')and v.PrimaryPart)end end
 for _,part in candidates do
  if part and part:IsA('BasePart')and(root.Position-part.Position).Magnitude<=18 then
   local exclude={char,part}
   local npcs=map:FindFirstChild('ServiceNPCs');if npcs then table.insert(exclude,npcs)end
   local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances=exclude
   local hit=workspace:Raycast(root.Position,part.Position-root.Position,ray)
   if not hit or hit.Instance==part then return true end
  end
 end
 return false
end
return Access
