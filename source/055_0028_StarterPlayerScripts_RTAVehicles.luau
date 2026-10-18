local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local net=game:GetService('ReplicatedStorage'):WaitForChild('RTA')
local p=Players.LocalPlayer local elapsed=0
local connection=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.06 then return end elapsed=0
 local ch=p.Character local h=ch and ch:FindFirstChildOfClass('Humanoid') local seat=h and h.SeatPart
 if not seat or not seat:IsA('VehicleSeat') or not seat.Parent or seat.Parent:GetAttribute('OwnerUserId')~=p.UserId then return end
 net.VehicleInput:FireServer(seat.ThrottleFloat,seat.SteerFloat)
end)
script.Destroying:Connect(function() connection:Disconnect() end)
