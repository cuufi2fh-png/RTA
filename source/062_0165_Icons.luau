local I={}
local function rect(p,x,y,w,h,c,r)
 local f=Instance.new('Frame') f.BorderSizePixel=0 f.BackgroundColor3=c f.Position=UDim2.fromScale(x,y) f.Size=UDim2.fromScale(w,h) f.Rotation=r or 0 f.Parent=p return f
end
local function round(f,n) local c=Instance.new('UICorner') c.CornerRadius=UDim.new(n or 1,0) c.Parent=f end
function I.draw(parent,kind,color)
 local c=color or Color3.new(1,1,1)
 local f=Instance.new('Frame') f.Name='Icon' f.BackgroundTransparency=1 f.Size=UDim2.fromScale(1,1) f.Parent=parent
 local function R(x,y,w,h,r) return rect(f,x,y,w,h,c,r) end
 local function O(x,y,w,h) local v=R(x,y,w,h) round(v) return v end
 if kind=='pistol' then R(.13,.25,.69,.19) R(.73,.22,.1,.12) R(.18,.42,.19,.38,12) R(.34,.43,.24,.055) R(.53,.43,.05,.17) R(.33,.57,.25,.045)
 elseif kind=='rifle' then R(.08,.38,.68,.14) R(.72,.39,.24,.055) R(.19,.33,.32,.06) R(.39,.5,.09,.22,-13) R(.56,.51,.12,.25,-15) R(.02,.41,.12,.2) R(.12,.5,.12,.06)
 elseif kind=='shotgun' then R(.09,.45,.83,.045) R(.33,.50,.44,.055) R(.18,.49,.3,.10) R(.02,.56,.23,.10,-20) R(.39,.53,.23,.065)
 elseif kind=='car' then round(R(.12,.42,.76,.31),.15) R(.25,.24,.5,.25) R(.20,.30,.1,.20,26) R(.70,.30,.1,.20,-26) O(.18,.69,.14,.13) O(.68,.69,.14,.13)
 elseif kind=='house' then R(.22,.45,.56,.4) R(.17,.28,.43,.13,-43) R(.43,.28,.43,.13,43)
 elseif kind=='bank' then
  local t=Instance.new('TextLabel') t.BackgroundTransparency=1 t.Size=UDim2.fromScale(1,1) t.Text='$' t.TextScaled=true t.Font=Enum.Font.GothamBold t.TextColor3=c t.Parent=f
 elseif kind=='shield' then R(.23,.18,.54,.45) R(.3,.49,.4,.3,45) 
 elseif kind=='medical' then R(.39,.13,.22,.74) R(.13,.39,.74,.22)
 elseif kind=='bag' then round(R(.20,.35,.60,.48),.12) R(.33,.20,.08,.22) R(.59,.20,.08,.22) R(.33,.18,.34,.07)
 elseif kind=='person' then O(.34,.12,.32,.32) round(R(.20,.49,.60,.36),.4)
 elseif kind=='message' then round(R(.13,.2,.74,.53),.35) R(.22,.64,.18,.20,20)
 elseif kind=='map' then R(.12,.25,.25,.55,-10) R(.38,.2,.25,.55,10) R(.64,.25,.24,.55,-10) O(.38,.2,.25,.25)
 elseif kind=='gear' then O(.27,.27,.46,.46) for i=0,7 do local a=math.rad(i*45) R(.45+math.cos(a)*.29,.45+math.sin(a)*.29,.1,.1,i*45) end
 elseif kind=='fist' then round(R(.26,.38,.51,.44),.25) for i=0,3 do round(R(.23+i*.14,.22,.13,.37),.4) end round(R(.14,.42,.18,.26),.4)
 elseif kind=='phone' then round(R(.27,.1,.46,.8),.18)
 elseif kind=='bell' then round(R(.29,.23,.42,.46),.45) R(.18,.65,.64,.08) O(.43,.75,.14,.12)
 else O(.3,.3,.4,.4) end
 return f
end
return I
