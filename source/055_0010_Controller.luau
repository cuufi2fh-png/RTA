local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local RS=game:GetService('ReplicatedStorage')
local StarterGui=game:GetService('StarterGui')
local player=Players.LocalPlayer
local gui=script.Parent
local C=require(gui.Config)
local Icons=require(gui.Icons)
local hud,phone,menu,wheel=gui.HUD,gui.Phone,gui.Menu,gui.WeaponWheel
local pages=menu.Inner.Pages
local content=phone.Screen.AppPage.Content
local app='Home'
local activeTab='MAP'
local state=nil
local alive=true
local connections={}
local function connect(signal,fn) local c=signal:Connect(fn) table.insert(connections,c) return c end
local function new(cls,parent,props) local v=Instance.new(cls) for k,x in pairs(props or {}) do v[k]=x end v.Parent=parent return v end
local yellow=Color3.fromRGB(255,185,0)
local white=Color3.fromRGB(243,243,244)
local selectedPoint=nil
local blur=new('BlurEffect',Lighting,{Name='RTA_UI_Blur',Size=0})
local request,update
local toastToken=0
local function toast(text)
 toastToken+=1 local token=toastToken gui.Toast.Text=text gui.Toast.Visible=true
 task.delay(4,function() if alive and token==toastToken then gui.Toast.Visible=false end end)
end
local function ask(action,arg) if request then request:FireServer(action,arg) else toast('도시 서비스 연결 중입니다.') end end
local function overlay()
 blur.Size=(wheel.Visible or menu.Visible) and 15 or 0
 hud.Visible=not menu.Visible and not wheel.Visible
end
local function clear(c) for _,v in ipairs(c:GetChildren()) do if v:IsA('GuiObject') then v:Destroy() end end end
local seq=0
local function text(c,value,height)
 seq+=1 return new('TextLabel',c,{Name='Info',LayoutOrder=seq,Size=UDim2.new(1,-8,0,height or 45),BackgroundTransparency=1,Text=value,TextWrapped=true,TextColor3=Color3.fromRGB(208,211,219),Font=Enum.Font.GothamMedium,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left})
end
local function action(c,value,fn)
 seq+=1 local b=new('TextButton',c,{Name='Action',LayoutOrder=seq,Size=UDim2.new(1,-8,0,43),BackgroundColor3=Color3.fromRGB(46,48,57),BorderSizePixel=0,Text=value,TextColor3=white,TextSize=15,Font=Enum.Font.GothamMedium})
 new('UICorner',b,{CornerRadius=UDim.new(0,7)}) b.Activated:Connect(fn) return b
end
local jobs={Citizen='시민',Taxi='택시 기사',Delivery='배달 기사',Public='공공근무자'}
local titles={Bank='은행',Jobs='직업',Business='사업체',Recruit='채용',Vehicles='차량',Contacts='연락처',Messages='도시 알림',Settings='설정'}
local refreshApp,openApp,showTab
local pointFolder=workspace:WaitForChild('RTAPoints',10)
local poi={}
local function diamond(parent,p,size)
 local b=new('TextButton',parent,{Name=p.id,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(size,size),BackgroundColor3=Color3.fromRGB(12,14,18),BorderSizePixel=0,Text='',Rotation=45})
 new('UIStroke',b,{Color=Color3.fromRGB(7,8,10),Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
 local inner=new('Frame',b,{Name='Outline',BackgroundTransparency=1,Position=UDim2.fromOffset(4,4),Size=UDim2.new(1,-8,1,-8),BorderSizePixel=0})
 new('UIStroke',inner,{Color=p.color,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
 local symbol=new('Frame',b,{BackgroundTransparency=1,Position=UDim2.fromScale(.17,.17),Size=UDim2.fromScale(.66,.66),Rotation=-45}) Icons.draw(symbol,p.icon,p.color)
 b.Activated:Connect(function() selectedPoint=p.id pages.MAP.Selected.Text=p.name toast(p.name..' 목적지 설정') end)
 return b
end
local worldMarkers=new('Frame',gui,{Name='WorldMarkers',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
for _,p in ipairs(C.Points) do
 local part=pointFolder and pointFolder:FindFirstChild(p.id)
 poi[p.id]={config=p,part=part,world=diamond(worldMarkers,p,34),mini=diamond(hud.Minimap.Markers,p,18),map=diamond(pages.MAP.MapSquare.Markers,p,29)}
 local distance=new('TextLabel',poi[p.id].world,{Name='Distance',Position=UDim2.new(.5,-42,1,18),Size=UDim2.fromOffset(84,20),BackgroundTransparency=1,Rotation=-45,Text='',TextColor3=white,TextSize=12,Font=Enum.Font.GothamMedium,TextStrokeTransparency=.3,Visible=false})
 connect(pages.MAP.Locations[p.id].Activated,function() selectedPoint=p.id pages.MAP.Selected.Text=p.name toast(p.name..' 목적지 설정') end)
end
connect(pages.MAP.Clear.Activated,function() selectedPoint=nil pages.MAP.Selected.Text='자유 탐색' end)
local mapGeometry=gui:WaitForChild('MapGeometry')
local miniCamera=new('Camera',hud.Minimap.Map,{Name='MapCamera',FieldOfView=2})
local fullCamera=new('Camera',pages.MAP.MapSquare.Map,{Name='MapCamera',FieldOfView=20})
hud.Minimap.Map.CurrentCamera=miniCamera pages.MAP.MapSquare.Map.CurrentCamera=fullCamera
local fullSpan=C.MapSpan
local function positionOf(entry) return entry.part and entry.part.Position or entry.config.position end
local function project(pos,center,span) return Vector2.new(.5+(pos.X-center.X)/span,.5+(pos.Z-center.Z)/span) end
local function setCamera(camera,center,span)
 local height=30000
 camera.FieldOfView=math.deg(2*math.atan(span/(2*height)))
 camera.CFrame=CFrame.lookAt(Vector3.new(center.X,height,center.Z),Vector3.new(center.X,0,center.Z),Vector3.new(0,0,-1))
end
local function cameraMap()
 local isFull=menu.Visible and activeTab=='MAP'
 local target=isFull and pages.MAP.MapSquare.Map or hud.Minimap.Map
 if mapGeometry.Parent~=target then mapGeometry.Parent=target end
end
local settings={markers=true,mini=true}
local function format(n) local s=tostring(math.floor(n or 0)) while true do local count; s,count=s:gsub('^(-?%d+)(%d%d%d)','%1,%2') if count==0 then break end end return s end
refreshApp=function()
 if app=='Home' then return end
 clear(content) seq=0 phone.Screen.AppPage.Title.Text=titles[app] or app
 local d=state and state.data
 if app=='Bank' then
  text(content,'현금  ₩'..format(d and d.cash)..'\n계좌  ₩'..format(d and d.bank),65)
  seq+=1 local amount=new('TextBox',content,{Name='Amount',LayoutOrder=seq,Size=UDim2.new(1,-8,0,45),BackgroundColor3=Color3.fromRGB(28,30,39),TextColor3=white,Text='',PlaceholderText='금액 입력',TextSize=20,Font=Enum.Font.Gotham,ClearTextOnFocus=false})
  action(content,'입금',function() ask('Deposit',tonumber(amount.Text)) end) action(content,'출금',function() ask('Withdraw',tonumber(amount.Text)) end)
 elseif app=='Jobs' then
  text(content,'현재 직업  /  '..(d and jobs[d.job] or '연결 중'),50)
  for _,j in ipairs({'Citizen','Taxi','Delivery','Public'}) do action(content,jobs[j],function() ask('Job',j) end) end
  if d and d.job~='Citizen' then action(content,'업무 시작',function() ask('Begin',d.job) end) action(content,'목적지에서 완료',function() if state and state.task then ask('Interact',state.task.target) else toast('진행 중인 업무가 없습니다.') end end) action(content,'업무 취소',function() ask('Cancel') end) end
 elseif app=='Business' then
  text(content,d and d.business and '내 사업체 · 운영 중' or '은행 잔액 ₩3,000으로 사업체 개설',65)
  action(content,'사업체 개설  ·  ₩3,000',function() ask('BuyBusiness') end)
  action(content,'주문 처리',function() ask('BusinessOrder') end)
  action(content,'채용 공고 등록',function() ask('Advertise') end)
  action(content,'직원 근무',function() ask('EmployeeWork') end)
 elseif app=='Recruit' then
  text(content,'현재 서버 채용 공고')
  for _,a in ipairs(state and state.ads or {}) do action(content,a.name..' · 지원',function() ask('Apply',a.owner) end) end
  if not state or #state.ads==0 then text(content,'아직 등록된 공고가 없습니다.',60) end
  for _,a in ipairs(state and state.candidates or {}) do action(content,a.name..' · 채용',function() ask('Hire',a.id) end) end
 elseif app=='Vehicles' then
  text(content,'택시 서비스',40)
  action(content,'택시 기사로 취업',function() ask('Job','Taxi') end)
  action(content,'차고에서 택시 생성',function() ask('Car') end)
  action(content,'업무 시작',function() ask('Begin','Taxi') end)
  text(content,'차량 구매와 개인 차고는 추후 연결됩니다.',70)
 elseif app=='Contacts' then
  text(content,'현재 도시에 있는 플레이어')
  for _,p in ipairs(Players:GetPlayers()) do text(content,p.DisplayName..'  @'..p.Name,43) end
 elseif app=='Messages' then
  text(content,state and state.message~='' and state.message or '새 도시 알림이 없습니다.',100)
 elseif app=='Settings' then
  action(content,'건물 표시  '..(settings.markers and 'ON' or 'OFF'),function() settings.markers=not settings.markers refreshApp() end)
  action(content,'미니맵  '..(settings.mini and 'ON' or 'OFF'),function() settings.mini=not settings.mini hud.Minimap.Visible=settings.mini refreshApp() end)
  text(content,'P  휴대폰\nM  지도\nQ  장비 휠\nEsc  닫기',110)
 end
end
openApp=function(name)
 menu.Visible=false wheel.Visible=false phone.Visible=true app=name
 phone.Screen.HomePage.Visible=name=='Home' phone.Screen.AppPage.Visible=name~='Home'
 refreshApp() overlay() cameraMap()
end
local function toolsOwned()
 local result={}
 for _,parent in ipairs({player:FindFirstChildOfClass('Backpack'),player.Character}) do if parent then for _,v in ipairs(parent:GetChildren()) do if v:IsA('Tool') then table.insert(result,v) end end end end
 table.sort(result,function(a,b) return a.Name<b.Name end) return result
end
local assigned={}
local selectedSlot=0
local function slotIndex(tool)
 local attr=tool:GetAttribute('RTAWeaponSlot')
 for i,s in ipairs(C.WeaponSlots) do if s.id==attr then return i end end
 local n=tool.Name:lower()
 if n:find('shotgun') or n:find('870') or n:find('산탄') then return 4 end
 if n:find('pistol') or n:find('glock') or n:find('revolver') or n:find('권총') then return 1 end
 if n:find('rifle') or n:find('ak') or n:find('smg') or n:find('m4') then return 2 end
 return 3
end
local function choose(index)
 selectedSlot=index
 local tool=assigned[index]
 wheel.Dial.WeaponName.Text=index==0 and '비무장' or tool and (tool:GetAttribute('DisplayName') or tool.Name) or C.WeaponSlots[index].name..' · 미보유'
 for _,arc in ipairs(wheel.Dial.Segments:GetChildren()) do local yes=arc:GetAttribute('Sector')==index arc.BackgroundColor3=yes and yellow or Color3.fromRGB(160,162,172) arc.BackgroundTransparency=yes and .10 or .81 end
end
local function updateWeapons()
 assigned={}
 for _,t in ipairs(toolsOwned()) do local index=slotIndex(t) if not assigned[index] then assigned[index]=t end end
 for i,s in ipairs(C.WeaponSlots) do local b=wheel.Dial[s.id] local t=assigned[i] local ammo=t and t:GetAttribute('Ammo') local reserve=t and t:GetAttribute('ReserveAmmo')
  b.Ammo.Text=t and (type(ammo)=='number' and tostring(ammo)..' / '..tostring(reserve or 0) or '보유') or '미보유'
  b.Symbol.Icon.Visible=true
  for _,v in ipairs(b.Symbol.Icon:GetDescendants()) do if v:IsA('Frame') then v.BackgroundTransparency=t and 0 or .62 end end
 end
 choose(selectedSlot)
end
local function equip(tool)
 local character=player.Character local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 if not humanoid or humanoid.Health<=0 then return end
 if not tool then humanoid:UnequipTools() return end
 if tool.Parent==player.Backpack or tool.Parent==character then humanoid:EquipTool(tool) end
end
local function closeWheel(commit)
 if commit then if selectedSlot==0 then equip(nil) elseif assigned[selectedSlot] then equip(assigned[selectedSlot]) else toast('아직 보유하지 않은 장비입니다.') end end
 wheel.Visible=false overlay()
end
local function openWheel()
 menu.Visible=false phone.Visible=false wheel.Visible=true selectedSlot=0 updateWeapons() overlay() cameraMap()
end
for i,s in ipairs(C.WeaponSlots) do connect(wheel.Dial[s.id].MouseEnter,function() choose(i) end) connect(wheel.Dial[s.id].Activated,function() choose(i) closeWheel(true) end) end
connect(wheel.Dial.Unarmed.Activated,function() choose(0) closeWheel(true) end)
connect(wheel.Close.Activated,function() closeWheel(false) end)
showTab=function(tab)
 activeTab=tab menu.Visible=true phone.Visible=false wheel.Visible=false
 for _,p in ipairs(pages:GetChildren()) do if p:IsA('Frame') then p.Visible=p.Name==tab end end
 for _,b in ipairs(menu.Inner.Tabs:GetChildren()) do if b:IsA('TextButton') then b.TextColor3=b.Name==tab and yellow or Color3.fromRGB(170,170,173) b.Stroke.Color=b.Name==tab and yellow or Color3.fromRGB(85,86,89) end end
 if pages[tab]:FindFirstChild('Content') then
  local c=pages[tab].Content clear(c) seq=0
  if tab=='INVENTORY' then
   local list=toolsOwned() if #list==0 then text(c,'보유한 장비가 없습니다. 획득한 Tool은 여기에 자동으로 표시됩니다.',70) end
   for _,tool in ipairs(list) do action(c,tool.Name..'  /  장착',function() equip(tool) menu.Visible=false overlay() cameraMap() end) end
  elseif tab=='PLAYERS' then for _,p in ipairs(Players:GetPlayers()) do text(c,p.DisplayName..'    @'..p.Name,50) end
  elseif tab=='MISSIONS' then text(c,state and state.task and (state.task.kind..'  →  '..state.task.target..'  /  ₩'..state.task.reward) or '진행 중인 임무가 없습니다.',70) action(c,'휴대폰에서 직업 찾기',function() openApp('Jobs') end)
  elseif tab=='SETTINGS' then
   action(c,'건물 표시  '..(settings.markers and 'ON' or 'OFF'),function() settings.markers=not settings.markers showTab('SETTINGS') end)
   action(c,'미니맵  '..(settings.mini and 'ON' or 'OFF'),function() settings.mini=not settings.mini hud.Minimap.Visible=settings.mini showTab('SETTINGS') end)
   text(c,'P 휴대폰    M 지도    Q 장비 휠    마우스 휠 지도 확대/축소',65)
  end
 end
 overlay() cameraMap()
end
connect(hud.TopBar.Menu.Activated,function() showTab('MAP') end)
connect(hud.TopBar.Shop.Activated,function() showTab('SHOP') end)
connect(hud.Phone.Activated,function() if phone.Visible then phone.Visible=false else openApp('Home') end end)
connect(hud.Weapons.Activated,openWheel)
connect(phone.Screen.Home.Activated,function() openApp('Home') end)
connect(phone.Screen.Close.Activated,function() phone.Visible=false end)
connect(menu.Inner.Close.Activated,function() menu.Visible=false overlay() cameraMap() end)
for _,b in ipairs(menu.Inner.Tabs:GetChildren()) do if b:IsA('TextButton') then connect(b.Activated,function() showTab(b.Name) end) end end
for _,b in ipairs(phone.Screen.HomePage:GetChildren()) do if b:IsA('TextButton') then connect(b.Activated,function() if b.Name=='Map' then showTab('MAP') else openApp(b.Name) end end) end end
connect(pages.SHOP.Business.Action.Activated,function() openApp('Business') end)
connect(pages.SHOP.Vehicles.Action.Activated,function() openApp('Vehicles') end)
for _,name in ipairs({'Jobs','Bank','Recruit'}) do connect(pages.SHOP[name].Activated,function() openApp(name) end) end
connect(UIS.InputBegan,function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.P then if phone.Visible then phone.Visible=false else openApp('Home') end
 elseif input.KeyCode==Enum.KeyCode.M then if menu.Visible then menu.Visible=false overlay() cameraMap() else showTab('MAP') end
 elseif input.KeyCode==Enum.KeyCode.Q or input.KeyCode==Enum.KeyCode.ButtonL1 then openWheel()
 elseif input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB then menu.Visible=false phone.Visible=false closeWheel(false) cameraMap()
 end
end)
connect(UIS.InputEnded,function(input) if input.KeyCode==Enum.KeyCode.Q or input.KeyCode==Enum.KeyCode.ButtonL1 then if wheel.Visible then closeWheel(true) end end end)
connect(UIS.InputChanged,function(input)
 if input.UserInputType==Enum.UserInputType.MouseWheel and menu.Visible and activeTab=='MAP' then fullSpan=math.clamp(fullSpan*(input.Position.Z>0 and .85 or 1.15),2500,12000)
 elseif input.KeyCode==Enum.KeyCode.Thumbstick2 and wheel.Visible then local p=input.Position if p.Magnitude>.35 then local a=(math.atan2(p.X,p.Y)+math.pi*2)%(math.pi*2) choose(math.floor((a+math.pi/4)/(math.pi/2))%4+1) end end
end)
local function resize()
 local camera=workspace.CurrentCamera if not camera then return end local v=camera.ViewportSize
 phone.Scale.Scale=math.clamp(math.min((v.Y-115)/590,(v.X-35)/306),.45,1)
 menu.Inner.Scale.Scale=math.min((v.X-32)/1180,(v.Y-50)/730,1.35)
 wheel.Dial.Scale.Scale=math.min((v.X-50)/600,(v.Y-90)/600,1.4)
 hud.TopBar.Size=UDim2.fromOffset(math.min(428,v.X-190),44) hud.TopBar.Position=UDim2.new(1,-math.min(450,v.X-168),0,18)
 hud.TopBar.Balance.Size=UDim2.new(1,-202,1,0) hud.TopBar.Balance.TextSize=v.X<700 and 14 or 21
 hud.Mission.Visible=v.X>=700 hud.Alert.Visible=v.X>=700
 local miniSize=v.X<700 and 128 or 204 hud.Minimap.Size=UDim2.fromOffset(miniSize,miniSize) hud.Minimap.Position=UDim2.new(0,18,1,-miniSize-30)
 hud.Location.Size=UDim2.fromOffset(miniSize,20)
 gui.Toast.Size=UDim2.fromOffset(math.min(520,v.X-40),44) gui.Toast.Position=UDim2.new(.5,-math.min(520,v.X-40)/2,0,78)
end
local previousCamera=nil
local tickTime=0
connect(Run.RenderStepped,function(dt)
 if not alive then return end
 local camera=workspace.CurrentCamera if not camera then return end
 if camera~=previousCamera then previousCamera=camera resize() end
 if wheel.Visible and UIS.MouseEnabled and not UIS:GetFocusedTextBox() then
  local center=wheel.Dial.AbsolutePosition+wheel.Dial.AbsoluteSize/2 local delta=UIS:GetMouseLocation()-center
  if delta.Magnitude<70*wheel.Dial.Scale.Scale then choose(0) else local a=(math.atan2(delta.X,-delta.Y)+math.pi*2)%(math.pi*2) choose(math.floor((a+math.pi/4)/(math.pi/2))%4+1) end
 end
 tickTime+=dt if tickTime<.1 then return end tickTime=0
 local character=player.Character local root=character and character:FindFirstChild('HumanoidRootPart')
 local pos=root and root.Position or C.MapCenter
 local fullCenter=selectedPoint and positionOf(poi[selectedPoint]) or C.MapCenter
 local full=menu.Visible and activeTab=='MAP'
 setCamera(miniCamera,pos,C.MiniSpan) if full then setCamera(fullCamera,fullCenter,fullSpan) end
 worldMarkers.Visible=settings.markers and not menu.Visible and not wheel.Visible
 for id,entry in pairs(poi) do
  local at=positionOf(entry) local miniPos=project(at,pos,C.MiniSpan) local mapPos=project(at,fullCenter,fullSpan)
  entry.mini.Position=UDim2.fromScale(miniPos.X,miniPos.Y) entry.mini.Visible=miniPos.X>.04 and miniPos.X<.96 and miniPos.Y>.04 and miniPos.Y<.96
  entry.map.Position=UDim2.fromScale(mapPos.X,mapPos.Y) entry.map.Visible=mapPos.X>.03 and mapPos.X<.97 and mapPos.Y>.03 and mapPos.Y<.97
  local projected,onScreen=camera:WorldToViewportPoint(at+Vector3.new(0,20,0))
  local distance=(at-pos).Magnitude
  entry.world.Visible=onScreen and distance<4500 and projected.Z>0
  entry.world.Position=UDim2.fromOffset(projected.X,projected.Y)
  entry.world.Distance.Visible=selectedPoint==id entry.world.Distance.Text=math.floor(distance)..' studs'
 end
 local ppos=project(pos,fullCenter,fullSpan) pages.MAP.MapSquare.Player.Position=UDim2.new(ppos.X,-13,ppos.Y,-13) pages.MAP.MapSquare.Player.Visible=ppos.X>=0 and ppos.X<=1 and ppos.Y>=0 and ppos.Y<=1
 if root then local look=root.CFrame.LookVector local rotation=math.deg(math.atan2(look.X,-look.Z)) hud.Minimap.Player.Rotation=rotation pages.MAP.MapSquare.Player.Rotation=rotation end
 local minutes=Lighting:GetMinutesAfterMidnight() phone.Screen.Clock.Text=string.format('%02d:%02d',math.floor(minutes/60)%24,math.floor(minutes)%60)
end)
local screenSizeConnection
local function bindCamera()
 if screenSizeConnection then screenSizeConnection:Disconnect() end
 local camera=workspace.CurrentCamera if camera then screenSizeConnection=camera:GetPropertyChangedSignal('ViewportSize'):Connect(resize) end resize()
end
connect(workspace:GetPropertyChangedSignal('CurrentCamera'),bindCamera) bindCamera()
connect(player.CharacterAdded,function() closeWheel(false) end)
-- Preserve the default inventory until the RTA interface has initialized successfully.
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
task.spawn(function()
 local net=RS:WaitForChild('PlayOS',15) if not alive or not net then toast('도시 서비스가 아직 설치되지 않았습니다.') return end
 request=net:WaitForChild('Request',10) update=net:WaitForChild('Update',10)
 if not alive or not request or not update then return end
 connect(update.OnClientEvent,function(s)
  state=s hud.TopBar.Balance.Text='₩'..format(s.data.cash)
  hud.Mission.Title.Text=s.task and '진행 중인 업무' or 'RTA  /  '..(jobs[s.data.job] or 'CITY LIFE')
  hud.Mission.Detail.Text=s.task and (s.task.target..'\n보상 ₩'..format(s.task.reward)) or '휴대폰에서 직업을 선택하고\n도시 생활을 시작하세요.'
  if s.message~='' then hud.Alert.Message.Text=s.message toast(s.message) end
  if phone.Visible and app~='Home' then refreshApp() end
 end)
 for _=1,6 do if not alive then return end ask('Sync') if state then break end task.wait(2) end
end)
connect(gui.Destroying,function()
 alive=false for _,c in ipairs(connections) do c:Disconnect() end if screenSizeConnection then screenSizeConnection:Disconnect() end blur:Destroy()
 pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,true) end)
end)
cameraMap() overlay()
