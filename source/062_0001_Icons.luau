-- Illustrated atlas, sliced into exact 256px cells. Source PNGs: assets/icons.
local I={Atlas='rbxassetid://132394993986399'}
local indices={person=0,message=1,car=2,bank=3,map=4,house=5,bag=6,gear=7,bell=8,shield=9,medical=10,package=11,pistol=12,rifle=13,shotgun=14,fist=15}
function I.draw(parent,kind,color)
 local i=indices[kind] or 7
 local image=Instance.new('ImageLabel') image.Name='Icon'
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.Image=I.Atlas image.ImageColor3=color or Color3.new(1,1,1)
 image.ImageRectOffset=Vector2.new(i%4*256,math.floor(i/4)*256)
 image.ImageRectSize=Vector2.new(256,256) image.ScaleType=Enum.ScaleType.Fit
 if kind=='rifle' or kind=='shotgun' then image.ImageRectOffset+=Vector2.new(0,64) image.ImageRectSize=Vector2.new(256,128) end
 image.Parent=parent return image
end
return I
