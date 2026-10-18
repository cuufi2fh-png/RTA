-- Select the imported RTA_IslandPackage and run: require(game:GetService('Selection'):Get()[1].InstallMap).install()
local package=script.Parent
local M={}
function M.install()
 assert(not game:GetService('RunService'):IsRunning(),'Stop Play mode before installing the map')
 assert(not workspace:FindFirstChild('RTA_IslandMap'),'A map with this name already exists; keep the installed version')
 local model=package:FindFirstChild('RTA_IslandMap');local region=package:FindFirstChildWhichIsA('TerrainRegion')
 assert(model and region,'Map or terrain payload missing')
 local min=package:GetAttribute('TerrainMinCell');assert(typeof(min)=='Vector3','Missing terrain origin')
 local history=game:GetService('ChangeHistoryService');history:SetWaypoint('Before RTA island import')
 workspace.Terrain:PasteRegion(region,Vector3int16.new(min.X,min.Y,min.Z),true)
 local clone=model:Clone();clone.Parent=workspace
 local mapUI=package:FindFirstChild('PhoneMap');local gui=game.StarterGui:FindFirstChild('RTA_UI')
 if mapUI and gui then for _,name in {'Config','MapGeometry'}do local src=mapUI:FindFirstChild(name);if src then local old=gui:FindFirstChild(name);if old then old:Destroy()end;src:Clone().Parent=gui end end end
 for _,name in {'RTAPoints','PlayOSWorld'}do local points=package:FindFirstChild(name);if points and not workspace:FindFirstChild(name)then points:Clone().Parent=workspace end end
 history:SetWaypoint('Import RTA island map');game:GetService('Selection'):Set({clone})
 return clone
end
return M
