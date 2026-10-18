local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Http=game:GetService('HttpService')
local net=RS:WaitForChild('RTA') local player=Players.LocalPlayer
local gui=player.PlayerGui:WaitForChild('RTACrimeHUD') local effects=require(net:WaitForChild('CrimeEffects')).new()
local function request(action,id) net.Request:FireServer(action,id,nil,Http:GenerateGUID(false)) end
net.CrimeState.OnClientEvent:Connect(function(s)
 if s.wanted~=nil then gui.Wanted.Text=string.rep('★',s.wanted)..string.rep('☆',5-s.wanted)..'  '..s.responder gui.Wanted.Visible=s.wanted>0 end
 if s.robbery~=nil then
  gui.Mission.Visible=s.robbery~=false
  if s.robbery then gui.Mission.Text=s.robbery.name..'  '..(s.robbery.stage=='BREACH' and ('금고 개방 '..s.robbery.remaining..'초 · E로 수령') or '160스튜드 밖으로 탈출') end
 end
 if s.message and s.message~='' then gui.Notice.Text=s.message local text=s.message task.delay(5,function() if gui.Notice.Text==text then gui.Notice.Text='' end end) end
end)
net.CrimeFX.OnClientEvent:Connect(function(kind,a,b,c,d)
 if kind=='Warning' then effects:warning(a,b,c,d)
 elseif kind=='Explosion' then effects:explode(a,b,c)
 elseif kind=='Cancel' then effects:cancel(a)
 elseif kind=='Alarm' then effects:alarm(a) end
end)
local function arrest()
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart') if not root then return end
 local nearest,distance=nil,9
 for _,target in ipairs(Players:GetPlayers()) do local r=target.Character and target.Character:FindFirstChild('HumanoidRootPart')
  if target~=player and (target:GetAttribute('RTAWanted') or 0)>0 and r and (r.Position-root.Position).Magnitude<distance then nearest=target distance=(r.Position-root.Position).Magnitude end
 end
 if nearest then request('Arrest',tostring(nearest.UserId)) end
end
UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.F then arrest() end end)
gui.Arrest.Activated:Connect(arrest)
local function job() local role=player:GetAttribute('RTAJob') gui.Arrest.Visible=role=='Police' or role=='Military' end
player:GetAttributeChangedSignal('RTAJob'):Connect(job) job()
script.Destroying:Connect(function() effects:destroy() end)
