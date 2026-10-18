local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local p=Players.LocalPlayer
local event=game.ReplicatedStorage:WaitForChild('FishingSystem'):WaitForChild('Remotes'):WaitForChild('Equipment')
local gui=Instance.new('ScreenGui');gui.Name='RTAFishingAccess';gui.ResetOnSpawn=false;gui.DisplayOrder=46;gui.Parent=p:WaitForChild('PlayerGui')
local function button(text,pos,width,kind)
 local b=Instance.new('TextButton');b.Name=kind;b.Text=text;b.AnchorPoint=Vector2.new(1,1);b.Position=pos;b.Size=UDim2.fromOffset(width,36);b.TextColor3=Color3.fromRGB(235,238,235);b.TextSize=14;b.Font=Enum.Font.GothamMedium;b.BackgroundColor3=Color3.fromRGB(30,44,49);b.BackgroundTransparency=.1;b.BorderSizePixel=0;b.Parent=gui
 local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(92,130,130);stroke.Transparency=.5;stroke.Parent=b
 b.Activated:Connect(function()event:FireServer(kind)end);return b
end
local function equipOrStore()
 local ch=p.Character;if ch then for _,t in ch:GetChildren()do if t:IsA('Tool')and t:HasTag('FishingRod')then event:FireServer('Store');return end end end
 event:FireServer('Basic')
end
local toggle=button('낚싯대  [F]',UDim2.new(1,-22,1,-142),170,'Basic')
local premium=button('프리미엄',UDim2.new(1,-198,1,-142),100,'Premium')
local store=button('넣기',UDim2.new(1,-304,1,-142),64,'Store')
local msg=Instance.new('TextLabel');msg.Name='Message';msg.AnchorPoint=Vector2.new(1,1);msg.Position=UDim2.new(1,-22,1,-185);msg.Size=UDim2.fromOffset(460,40);msg.BackgroundTransparency=1;msg.TextColor3=Color3.fromRGB(244,221,163);msg.TextStrokeTransparency=.35;msg.Font=Enum.Font.GothamMedium;msg.TextSize=14;msg.TextWrapped=true;msg.TextXAlignment=Enum.TextXAlignment.Right;msg.Text='';msg.Parent=gui
local generation=0
event.OnClientEvent:Connect(function(_,text)generation+=1;local n=generation;msg.Text=text or'';task.delay(5,function()if n==generation then msg.Text=''end end)end)
UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.F then equipOrStore()end end)
-- Compact extra buttons on narrow screens; keep the rod reachable without the default backpack.
local function layout()
 local c=workspace.CurrentCamera;if not c then return end
 local narrow=c.ViewportSize.X<650
 premium.Position=UDim2.new(1,narrow and-22 or-198,1,narrow and-226 or-142)
 store.Position=UDim2.new(1,narrow and-128 or-304,1,narrow and-226 or-142)
 msg.Size=UDim2.fromOffset(math.min(460,c.ViewportSize.X-35),40)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(layout)end;layout()
