local package=script.Parent
local M={}
function M.install()
 assert(not game:GetService('RunService'):IsRunning(),'Stop Play before installing systems')
 local order={'ReplicatedStorage','ServerStorage','StarterGui','StarterPlayer','ServerScriptService'}
 -- This package is intended for a blank place. Existing names require explicit manual merge.
 for _,service in order do
  local src=package:FindFirstChild(service);local dst=game:GetService(service)
  if src then for _,child in src:GetChildren()do
   if service=='StarterPlayer'and(child.Name=='StarterPlayerScripts'or child.Name=='StarterCharacterScripts')then
    for _,v in child:GetChildren()do assert(not dst[child.Name]:FindFirstChild(v.Name),'Already installed: '..service..'.'..child.Name..'.'..v.Name)end
   else assert(not dst:FindFirstChild(child.Name),'Already installed: '..service..'.'..child.Name)end
  end end
 end
 game:GetService('ChangeHistoryService'):SetWaypoint('Before RTA systems import')
 for _,service in order do
  local src=package:FindFirstChild(service);local dst=game:GetService(service)
  if src then for _,child in src:GetChildren()do
   if service=='StarterPlayer'and(child.Name=='StarterPlayerScripts'or child.Name=='StarterCharacterScripts')then for _,v in child:GetChildren()do v:Clone().Parent=dst[child.Name]end
   else child:Clone().Parent=dst end
  end end
 end
 game:GetService('ChangeHistoryService'):SetWaypoint('Import RTA systems')
 return true
end
return M
