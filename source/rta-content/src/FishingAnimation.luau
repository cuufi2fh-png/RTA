-- Plays the actual embedded KeyframeSequences supplied with the rod.
-- No external animation upload or asset permission is required.
local Run=game:GetService('RunService')
local Clips=game.ReplicatedStorage.FishingSystem.AnimationClips
local A={}
local names={Idle='Idle',IdleFishing='Idle Fishing',Walk='Walk',Cast='Cast',Reel='Reel',Struggle='Struggle'}
local cache={}
local function clip(name)
 if cache[name]then return cache[name]end
 local frames={};local seq=Clips[names[name]]
 for _,k in seq:GetKeyframes()do
  local poses={};for _,p in k:GetDescendants()do if p:IsA('Pose')then poses[p.Name]={cf=p.CFrame,weight=p.Weight,style=p.EasingStyle,direction=p.EasingDirection}end end
  table.insert(frames,{time=k.Time,poses=poses})
 end
 table.sort(frames,function(a,b)return a.time<b.time end);cache[name]=frames;return frames
end
local function sample(frames,t,key)
 local a,b=frames[1],frames[#frames]
 for i=2,#frames do if frames[i].time>=t then a=frames[i-1];b=frames[i];break end end
 local pa,pb=a.poses[key],b.poses[key];if not pa then return nil end;if not pb then return pa.cf end
 local alpha=b.time>a.time and math.clamp((t-a.time)/(b.time-a.time),0,1)or 0
 if pb.style==Enum.PoseEasingStyle.Constant then alpha=0 elseif pb.style==Enum.PoseEasingStyle.Cubic then alpha=alpha*alpha*(3-2*alpha)end
 return pa.cf:Lerp(pb.cf,alpha)
end
function A.Load(animator)
 local ch=animator.Parent.Parent;local motors={};local original={}
 local aliases={RightUpperArm='Right Arm',LeftUpperArm='Left Arm',RightHand='__skip',LeftHand='__skip'}
 for _,m in ch:GetDescendants()do
  if m:IsA('Motor6D')and m.Part1 then local name=aliases[m.Part1.Name]or m.Part1.Name
   if name=='Right Arm'or name=='Left Arm'or name=='Head'then motors[m]=name;original[m]=m.Transform end
  end
 end
 local t={character=ch,motors=motors,original=original,name=nil,time=0,speed=1,connection=nil,blend=0,frames=nil}
 local function step(dt)
  if not t.name or not ch.Parent then return end
  t.time+=dt*t.speed;t.blend=math.min(1,t.blend+dt*9)
  local frames=t.frames;local length=frames[#frames].time
  local at=length>0 and(t.name=='Cast'and math.min(t.time,length)or t.time%length)or 0
  for motor,key in motors do if motor.Parent then local cf=sample(frames,at,key);if cf then motor.Transform=motor.Transform:Lerp(cf,t.blend)end end end
  local arm=ch:FindFirstChild('Right Arm')or ch:FindFirstChild('RightHand');local rod=arm and arm:FindFirstChild('StylizedFishingRod')
  if rod and rod:IsA('Motor6D')then local cf=sample(frames,at,'StylizedFishingRod');if cf then rod.Transform=cf end end
 end
 t.step=step
 return t
end
function A.Preload()for name in names do clip(name)end end
function A.PlayOnly(t,name)
 t.name=name;t.time=0;t.speed=1;t.blend=0;t.frames=clip(name)
 if not t.connection then t.connection=Run.PreSimulation:Connect(t.step)end
end
function A.SetSpeed(t,_,speed)t.speed=speed end
function A.StopAll(t)
 t.name=nil;if t.connection then t.connection:Disconnect();t.connection=nil end
 for m in t.motors do if m.Parent then m.Transform=CFrame.identity end end
 local arm=t.character:FindFirstChild('Right Arm')or t.character:FindFirstChild('RightHand');local r=arm and arm:FindFirstChild('StylizedFishingRod');if r then r.Transform=CFrame.identity end
end
return A
