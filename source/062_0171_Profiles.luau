local DSS = game:GetService('DataStoreService')
local Http = game:GetService('HttpService')
local Run = game:GetService('RunService')
local C = require(script.Parent.Config)
local P = { loaded = {}, busy = {} }
local store = DSS:GetDataStore(C.DataStoreName)
local session = Http:GenerateGUID(false)
local temporary = Run:IsStudio() and not C.StudioPersistence
local function defaults()
 return {version=1,cash=C.StartingCash,bank=C.StartingBank,job='Citizen',business=false,orders=0}
end
local function valid(d)
 if type(d)~='table' or d.version~=1 then return false end
 for _,k in ipairs({'cash','bank','orders'}) do local n=d[k] if type(n)~='number' or n~=n or n<0 or n>C.MaxBalance or n%1~=0 then return false end end
 return C.Jobs[d.job]~=nil and type(d.business)=='boolean'
end
function P.load(player)
 if temporary then P.loaded[player]={data=defaults(),expires=math.huge} return true end
 local key='u_'..player.UserId
 for attempt=1,3 do
  local ok,result=pcall(function() return store:UpdateAsync(key,function(old)
   if old and (not valid(old.data) or (old.lock and old.lock.id~=session and old.lock.expires>os.time())) then return nil end
   return {data=old and old.data or defaults(),lock={id=session,expires=os.time()+180}}
  end) end)
  if ok and result and result.lock and result.lock.id==session then P.loaded[player]={data=result.data,expires=result.lock.expires} return true end
  task.wait(attempt)
 end
 return false
end
function P.get(player)
 local p=P.loaded[player]
 if p and p.expires>os.time()+15 and not p.closing then return p.data end
 return nil
end
function P.save(player,release)
 local p=P.loaded[player] if not p then return true end
 if p.closing and not release then return true end
 if release then p.closing=true end
 local deadline=os.clock()+20
 while P.busy[player] and os.clock()<deadline do task.wait(.1) end
 if P.busy[player] then return false end
 if P.loaded[player]~=p then return true end
 if p.closing and not release then return true end
 P.busy[player]=true
 if temporary then P.busy[player]=nil if release then P.loaded[player]=nil end return true end
 local snapshot=table.clone(p.data)
 local success=false
 for attempt=1,3 do
  local ok,result=pcall(function() return store:UpdateAsync('u_'..player.UserId,function(old)
   if not old or not old.lock or old.lock.id~=session or old.lock.expires<=os.time() then return nil end
   return {data=snapshot,lock=not release and {id=session,expires=os.time()+180} or nil}
  end) end)
  if ok and result and ((release and not result.lock) or (not release and result.lock and result.lock.id==session)) then success=true if not release then p.expires=result.lock.expires end break end
  task.wait(attempt)
 end
 P.busy[player]=nil
 if release and success then P.loaded[player]=nil end
 return success
end
P.temporary=temporary
return P
