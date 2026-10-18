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
 if p and p.expires>os.time()+15 and not p.closing and not p.transaction and not p.receiptUncertain then return p.data end
 return nil
end
function P.save(player,release)
 local p=P.loaded[player] if not p then return true end
 if p.receiptUncertain then return false end
 if p.closing and not release then return true end
 if release then p.closing=true end
 local deadline=os.clock()+20
 while P.busy[player] and os.clock()<deadline do task.wait(.1) end
 if P.busy[player] then return false end
 if P.loaded[player]~=p then return true end
 if p.receiptUncertain then return false end
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

-- Receipt delivery and its ledger entry commit in one session-locked UpdateAsync.
-- P.get is closed while the transaction yields, preventing stale snapshot overwrites.
function P.commitReceipt(player,receiptId,grant)
 if type(receiptId)~='string' or #receiptId<1 or #receiptId>80 or not receiptId:match('^[%w_%-]+$') then return false end
 local profile=P.loaded[player]
 if not profile or profile.closing then return false end
 if profile.receiptUncertain and profile.receiptUncertain~=receiptId then return false end
 local deadline=os.clock()+12
 while P.busy[player]and os.clock()<deadline do task.wait(.1)end
 if P.busy[player]or P.loaded[player]~=profile or profile.closing then return false end
 if profile.data.content.receipts[receiptId]then return true end
 local count=0;for _ in profile.data.content.receipts do count+=1 end
 if count>=20000 then warn('RTA receipt ledger capacity reached; refusing to lose purchase history');return false end
 P.busy[player]=true;profile.transaction=true
 local snapshot=Schema.copy(profile.data)
 local ok,granted=pcall(grant,snapshot)
 if not ok or not granted then profile.transaction=nil;P.busy[player]=nil;return false end
 snapshot.content.receipts[receiptId]=true
 snapshot=Schema.normalize(snapshot,C)
 if not snapshot then profile.transaction=nil;P.busy[player]=nil;return false end
 local success=false
 if temporary then success=true else
  for attempt=1,3 do
   local saved,result=pcall(function()return store:UpdateAsync('u_'..player.UserId,function(old)
    if not old or not old.lock or old.lock.id~=session or old.lock.expires<=os.time()then return nil end
    if old.data.content and old.data.content.receipts and old.data.content.receipts[receiptId]then return old end
    return {data=snapshot,lock={id=session,expires=os.time()+180}}
   end)end)
   if saved and result and result.lock and result.lock.id==session and result.data.content.receipts[receiptId]then
    snapshot=result.data;profile.expires=result.lock.expires;success=true;break
   end
   task.wait(attempt)
  end
 end
 if success then profile.data=snapshot;profile.receiptUncertain=nil else profile.receiptUncertain=receiptId end
 profile.transaction=nil;P.busy[player]=nil
 return success
end

P.temporary=temporary
return P
