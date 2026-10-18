-- In-place buildings replace the removed off-map private-room implementation.
-- Purchase records remain valid. Physical doorway integration is in progress.
local H={}
function H.start(P,C)
 local self={}
 function self.enter(p,id)
  local d=P.get(p)
  if not d or not C.Homes[id] or not d.rta.ownedHomes[id] then return false,'소유한 주택이 아닙니다.' end
  return false,'주택은 건물 현관에서 출입하세요.'
 end
 return self
end
return H
