local RS=game:GetService('ReplicatedStorage');local Tween=game:GetService('TweenService');local Debris=game:GetService('Debris')
local active=0
RS:WaitForChild('RTA'):WaitForChild('WeaponFX').OnClientEvent:Connect(function(kind,pos)
 if kind~='Blast'or typeof(pos)~='Vector3'or active>=16 then return end
 active+=1
 local p=Instance.new('Part');p.Name='LocalBlast';p.Shape=Enum.PartType.Ball;p.Size=Vector3.one*2;p.Position=pos;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Color=Color3.fromRGB(255,186,77);p.Material=Enum.Material.Neon;p.Transparency=.2;p.Parent=workspace
 local light=Instance.new('PointLight');light.Color=p.Color;light.Brightness=5;light.Range=26;light.Parent=p
 local sound=Instance.new('Sound');sound.SoundId='rbxasset://sounds/impact_explosion_03.mp3';sound.Volume=.6;sound.RollOffMaxDistance=160;sound.Parent=p;sound:Play()
 Tween:Create(p,TweenInfo.new(.35),{Size=Vector3.one*25,Transparency=1}):Play();Tween:Create(light,TweenInfo.new(.35),{Brightness=0}):Play()
 Debris:AddItem(p,2);task.delay(2,function()active-=1 end)
end)
