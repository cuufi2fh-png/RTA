-- Edit-time construction library. Coordinates are local to each surveyed plot.
-- Flush small detached batches so Studio stays responsive during construction.
local A={}
local V=Vector3.new
local CF=CFrame.new
local C=Color3.fromRGB
A.colors={stone=C(218,211,193),white=C(231,230,219),dark=C(40,48,53),glass=C(116,150,166),navy=C(35,56,78),wood=C(149,105,62),brick=C(137,78,57),teal=C(56,119,125),gold=C(202,164,85),floor=C(190,185,172),green=C(65,101,52),orange=C(213,111,42),red=C(166,55,48)}
function A.new(root,id,origin)
 local self=setmetatable({origin=origin,count=0,batchN=0,entries={},doors={}}, {__index=A})
 local m=Instance.new('Model');m.Name=id;m:SetAttribute('RTAArchitecture',true);m:SetAttribute('DesignVersion','ApprovedConcept01');m:SetAttribute('Origin',origin);m.ModelStreamingMode=Enum.ModelStreamingMode.Default;m.Parent=root;self.model=m
 self:batch('Structure');return self
end
function A:batch(name)
 if self.chunk then self.chunk.Parent=self.model;task.wait()end
 self.batchN+=1;self.chunk=Instance.new('Folder');self.chunk.Name=name or('Details_'..self.batchN);self.inBatch=0
end
function A:finish()
 if self.chunk then self.chunk.Parent=self.model;self.chunk=nil end
 self.model:SetAttribute('PartCount',self.count);return self.model
end
function A:part(name,size,cf,color,mat,collide,transparency)
 if self.inBatch>=180 then self:batch()end
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=self.origin*cf;p.Color=color or self.colors.stone;p.Material=mat or Enum.Material.Concrete;p.Anchored=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.CanCollide=collide~=false;p.CanTouch=false;p.CanQuery=collide~=false;p.CastShadow=transparency==nil or transparency<.5;p.Transparency=transparency or 0;p.Parent=self.chunk
 self.count+=1;self.inBatch+=1;return p
end
function A:b(name,x,y,z,w,h,d,col,mat,collide,alpha)return self:part(name,V(w,h,d),CF(x,y,z),col,mat,collide,alpha)end
function A:cyl(name,x,y,z,r,h,col,mat)
 local p=self:part(name,V(h,r*2,r*2),CF(x,y,z)*CFrame.Angles(0,0,math.pi/2),col,mat);p.Shape=Enum.PartType.Cylinder;return p
end
function A:beam(name,a,b,width,col,mat)
 local delta=b-a
 return self:part(name,V(width,width,delta.Magnitude),CFrame.lookAt((a+b)*.5,b),col,mat,false)
end
function A:sign(name,text,x,y,z,w,h,col,bg,face)
 local p=self:b(name,x,y,z,w,h,.16,bg or self.colors.dark,Enum.Material.SmoothPlastic,false)
 local g=Instance.new('SurfaceGui');g.Name='Lettering';g.Face=face or Enum.NormalId.Back;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=40;g.LightInfluence=.6;g.MaxDistance=850;g.Parent=p
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(.94,.85);t.Position=UDim2.fromScale(.03,.07);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=col or self.colors.white;t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.Parent=g;return p
end
function A:light(x,y,z,w,d)
 local p=self:b('RecessedLight',x,y,z,w,.12,d,C(255,231,191),Enum.Material.Neon,false)
 local l=Instance.new('SurfaceLight');l.Face=Enum.NormalId.Bottom;l.Color=C(255,230,196);l.Range=24;l.Brightness=.7;l.Angle=115;l.Shadows=false;l.Parent=p;return p
end
function A:window(x,y,z,w,h,rot)
 local frame=CF(x,y,z)*CFrame.Angles(0,math.rad(rot or 0),0)
 local pane=self:part('Glazing',V(w,h,.25),frame,self.colors.glass,Enum.Material.Glass,true,.36);pane.Reflectance=.12
 for _,dx in {-w/2,w/2}do self:part('WindowMullion',V(.32,h+.4,.65),frame*CF(dx,0,0),self.colors.dark,Enum.Material.Metal)end
 for _,dy in {-h/2,h/2}do self:part('WindowTransom',V(w+.5,.3,.65),frame*CF(0,dy,0),self.colors.dark,Enum.Material.Metal)end
end
function A:door(x,y,z,w,h,label,rot)
 local cf=CF(x,y,z)*CFrame.Angles(0,math.rad(rot or 0),0)
 for _,side in {-1,1}do
  local p=self:part('SlidingGlassDoor',V(w/2-.15,h,.45),cf*CF(side*w/4,h/2,0),self.colors.glass,Enum.Material.Glass,true,.6)
  p:SetAttribute('ArchitectureDoor',true);p:SetAttribute('ClosedCFrame',p.CFrame);p:SetAttribute('OpenCFrame',self.origin*cf*CF(side*(w*.75+.3),h/2,0));p:SetAttribute('AutoDoor',true)
  for _,dx in {-w/4+.2,w/4-.2}do
   local edge=self:part('DoorRail',V(.25,h,.6),cf*CF(side*w/4+dx,h/2,0),self.colors.dark,Enum.Material.Metal,false)
   local owner=Instance.new('ObjectValue');owner.Name='DoorOwner';owner.Value=p;owner.Parent=edge
  end
  local handle=self:part('DoorHandle',V(.15,2.5,.4),cf*CF(side*.7,h/2,.5),self.colors.gold,Enum.Material.Metal,false)
  local owner=Instance.new('ObjectValue');owner.Name='DoorOwner';owner.Value=p;owner.Parent=handle
 end
 self:part('DoorHeader',V(w+1,1.1,1),cf*CF(0,h+.5,0),self.colors.dark,Enum.Material.Metal)
 local entry=self.origin*cf*CF(0,3,4);table.insert(self.entries,entry.Position)
 self.model:SetAttribute('Entrance',entry.Position)
 if label then self:sign('EntranceSign',label,x,y+h+2,z+.65,w+3,2)end
end
function A:counter(x,y,z,w,label,col)
 self:b('CounterBase',x,y+1.6,z,w,3.2,3.2,col or self.colors.wood,Enum.Material.Wood)
 self:b('CounterTop',x,y+3.35,z,w+.5,.3,3.7,self.colors.stone,Enum.Material.Marble)
 self:b('CounterKickplate',x,y+.2,z+1.65,w,.35,.12,self.colors.gold,Enum.Material.Metal,false)
 self:b('TerminalStand',x,y+3.7,z,1.2,.6,.8,self.colors.dark,Enum.Material.Metal,false)
 self:sign('Terminal','RTA',x,y+4.5,z,.9,.65,C(100,191,180),self.colors.dark)
 if label then self:sign('CounterLabel',label,x,y+1.8,z+1.7,w*.8,1.1,self.colors.dark,self.colors.stone)end
end
function A:bench(x,y,z,w,rot)
 local f=CF(x,y,z)*CFrame.Angles(0,math.rad(rot or 0),0)
 self:part('BenchSeat',V(w,.7,2.3),f*CF(0,1.6,0),self.colors.wood,Enum.Material.WoodPlanks)
 self:part('BenchBack',V(w,2,.5),f*CF(0,2.6,-1),self.colors.wood,Enum.Material.WoodPlanks)
 for _,s in {-1,1}do self:part('BenchLeg',V(.4,1.6,2),f*CF(s*(w/2-.8),.8,0),self.colors.dark,Enum.Material.Metal)end
end
function A:planter(x,y,z,w,d,tall)
 self:b('Planter',x,y+1.3,z,w,2.6,d,self.colors.dark,Enum.Material.Concrete)
 self:b('Soil',x,y+2.65,z,w-.6,.15,d-.6,C(62,50,39),Enum.Material.Ground,false)
 local n=math.max(1,math.floor(w/4))
 for i=1,n do local xx=x-w/2+(i-.5)*w/n
  local p=self:b('Hedge',xx,y+3.8,z,w/n,2.6,d-.7,self.colors.green,Enum.Material.Grass,false);p.Shape=Enum.PartType.Ball
 end
 if tall then
  self:cyl('Trunk',x,y+7,z,.4,9,C(103,82,55),Enum.Material.Wood)
  for _,v in {{-2,11,0,6},{2,12,0,6},{0,14,1,6}}do local p=self:b('Canopy',x+v[1],y+v[2],z+v[3],v[4],5,6,C(72+v[1]*3,116,62),Enum.Material.Grass,false);p.Shape=Enum.PartType.Ball end
 end
end
function A:rail(a,b)
 self:beam('Handrail',a+V(0,3.2,0),b+V(0,3.2,0),.18,self.colors.dark,Enum.Material.Metal)
 local n=math.max(1,math.ceil((b-a).Magnitude/4))
 for i=0,n do local p=a:Lerp(b,i/n);self:b('Baluster',p.X,p.Y+1.6,p.Z,.16,3.2,.16,self.colors.dark,Enum.Material.Metal,false)end
end
function A:stairs(x,y,z,rise,width)
 -- Switchback stair, 24 risers. Both floor slabs leave a real opening.
 local n=12;local step=1.5;local half=rise/2;local flight=width/2-.5
 for i=1,n do
  self:b('StairTread',x-width/4,y+i*half/n-.12,z+i*step,flight,.24,step+.06,self.colors.stone,Enum.Material.Concrete)
  self:b('StairRiser',x-width/4,y+(i-.5)*half/n,z+(i-.5)*step,flight,half/n,.15,self.colors.floor,Enum.Material.Concrete)
  self:b('StairTread',x+width/4,y+half+i*half/n-.12,z+(n+1-i)*step,flight,.24,step+.06,self.colors.stone,Enum.Material.Concrete)
  self:b('StairRiser',x+width/4,y+half+(i-.5)*half/n,z+(n+1.5-i)*step,flight,half/n,.15,self.colors.floor,Enum.Material.Concrete)
 end
 self:b('StairLanding',x,y+half-.35,z+n*step+2,width,.7,4,self.colors.stone,Enum.Material.Concrete)
 self:b('UpperStairLanding',x,y+rise-.35,z-1,width,.7,4,self.colors.stone,Enum.Material.Concrete)
 for _,dx in {-width/2,0,width/2}do
  self:rail(V(x+dx,y,z),V(x+dx,y+half,z+n*step))
  if dx>=0 then self:rail(V(x+dx,y+rise,z),V(x+dx,y+half,z+n*step))end
 end
end
function A:slabHole(y,w,d,hx,hz,hw,hd,col)
 local left=hx-hw/2;local right=hx+hw/2;local back=hz-hd/2;local front=hz+hd/2
 if left>-w/2 then self:b('FloorSlab',(-w/2+left)/2,y,0,left+w/2,.6,d,col or self.colors.floor,Enum.Material.Concrete)end
 if right<w/2 then self:b('FloorSlab',(right+w/2)/2,y,0,w/2-right,.6,d,col or self.colors.floor,Enum.Material.Concrete)end
 if back>-d/2 then self:b('FloorSlab',hx,y,(-d/2+back)/2,hw,.6,back+d/2,col or self.colors.floor,Enum.Material.Concrete)end
 if front<d/2 then self:b('FloorSlab',hx,y,(front+d/2)/2,hw,.6,d/2-front,col or self.colors.floor,Enum.Material.Concrete)end
end
function A:desk(x,y,z)
 self:b('DeskTop',x,y+2.8,z,7,.3,3.6,self.colors.wood,Enum.Material.Wood)
 for _,dx in {-2.8,2.8}do self:b('DeskLeg',x+dx,y+1.3,z,.35,2.6,2.8,self.colors.dark,Enum.Material.Metal)end
 self:sign('Workstation','RTA',x,y+4,z-1.1,2.2,1.4,C(126,190,191),self.colors.dark)
 self:b('Keyboard',x,y+3,z+.3,2.1,.12,.7,self.colors.dark,Enum.Material.SmoothPlastic,false)
 self:b('OfficeSeat',x,y+1.7,z+3,2.3,.6,2.3,self.colors.navy,Enum.Material.Fabric)
 self:b('OfficeBack',x,y+3,z+4,2.3,2.6,.5,self.colors.navy,Enum.Material.Fabric)
 self:cyl('SeatLeg',x,y+.8,z+3,.2,1.4,self.colors.dark,Enum.Material.Metal)
end
function A:parking(x,z,n,angle)
 local cf=CF(x,.12,z)*CFrame.Angles(0,math.rad(angle or 0),0)
 self:part('ParkingAsphalt',V(n*11+6,.35,24),cf,self.colors.dark,Enum.Material.Asphalt)
 for i=0,n do self:part('ParkingLine',V(.22,.02,20),cf*CF((i-n/2)*11,.19,0),self.colors.white,Enum.Material.SmoothPlastic,false)end
 for i=1,n do self:part('WheelStop',V(7,.5,.8),cf*CF((i-.5-n/2)*11,.45,-9),self.colors.floor,Enum.Material.Concrete)end
end
function A:roofPlant(x,y,z)
 self:b('HVAC',x,y+1.6,z,8,3.2,5,C(137,145,143),Enum.Material.Metal)
 for i=1,5 do self:b('HVACLouvre',x-3+i,y+1.7,z+2.55,.18,2.2,.13,self.colors.dark,Enum.Material.Metal,false)end
end
function A:site(w,d)
 self:b('PavedForecourt',0,-.15,0,w,.6,d,C(174,174,164),Enum.Material.Pavement)
 self:b('PerimeterKerb',0,.25,d/2,w,.5,.8,self.colors.stone,Enum.Material.Concrete)
end
return A
