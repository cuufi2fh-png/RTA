local DSS = game:GetService('DataStoreService')
local Http = game:GetService('HttpService')
local Run = game:GetService('RunService')
local C = require(script.Parent.Config)
local Schema = require(script.Parent.ProfileSchema)
local P = { loaded = {}, busy = {} }
local store = DSS:GetDataStore(C.DataStoreName)
local session = Http:GenerateGUID(false)
local temporary = Run:IsStudio() and not C.StudioPersistence
local function defaults()
 return Schema.normalize({version=1,cash=C.StartingCash,bank=C.StartingBank,job='Citizen',business=false,orders=0},C)
end
local function lockedByOther(old)
 if type(old)~='table' then return true end
 local lock=old.lock
 if lock==nil then return false end
 if type(lock)~='table' or type(lock.id)~='string' or type(lock.expires)~='number'
  or lock.expires~=lock.expires or lock.expires==math.huge then return true end
 return lock.id~=session and lock.expires>os.time()
end
function P.load(player)
 if temporary then P.loaded[player]={data=defaults(),expires=math.huge} return true end
 local key='u_'..player.UserId
 for attempt=1,3 do
  local ok,result=pcall(function() return store:UpdateAsync(key,function(old)
   if old and lockedByOther(old) then return nil end
   local data=old and Schema.normalize(old.data,C) or (old==nil and defaults())
   if not data then return nil end
   return {data=data,lock={id=session,expires=os.time()+180}}
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
 local snapshot=Schema.normalize(p.data,C)
 if not snapshot then P.busy[player]=nil return false end
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
