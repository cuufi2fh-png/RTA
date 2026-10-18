-- Pure schema. Persistent receipts live in the same atomic profile write as purchased grants.
local S={}
local function num(n,max)return type(n)=='number'and n==n and n>=0 and n<=max and n%1==0 end
local function id(k)return type(k)=='string'and #k>0 and #k<=80 and k:match('^[%w_%-]+$')~=nil end
local function copy(v)if type(v)~='table'then return v end local t={}for k,x in v do t[k]=copy(x)end return t end
local function map(t,maxCount,bool,maxValue)
 if type(t)~='table'then return false end local n=0
 for k,v in t do n+=1;if n>maxCount or not id(k)or (bool and v~=true)or(not bool and not num(v,maxValue))then return false end end return true
end
function S.new()
 return {version=1,seeds={Crop01=6,Crop02=6},fish={},foods={},boats={},aircraft={},businesses={},entitlements={},tokens={},boosts={},stocks={},garden={},receipts={},production=false,laundry=false,selectedHome=false,selectedBusiness=false,homePlot=false,businessPlot=false,farmPlot=false}
end
function S.normalize(v)
 if v==nil then return S.new()end
 if type(v)~='table'or v.version~=1 then return nil end
 local allowed={version=true,seeds=true,fish=true,foods=true,boats=true,aircraft=true,businesses=true,entitlements=true,tokens=true,boosts=true,stocks=true,garden=true,receipts=true,production=true,laundry=true,selectedHome=true,selectedBusiness=true,homePlot=true,businessPlot=true,farmPlot=true}
 for k in v do if not allowed[k]then return nil end end
 for _,k in {'seeds','fish','foods','tokens','stocks'}do if not map(v[k],256,false,1000000)then return nil end end
 for _,k in {'boats','aircraft','businesses','entitlements'}do if not map(v[k],256,true)then return nil end end
 if not map(v.boosts,32,false,99999999999)or not map(v.receipts,20000,true)then return nil end
 for _,k in {'selectedHome','selectedBusiness','homePlot','businessPlot','farmPlot'}do if v[k]~=false and not id(v[k])then return nil end end
 if type(v.garden)~='table'then return nil end
 local count=0;for k,p in v.garden do count+=1
  if count>12 or not id(k)or type(p)~='table'or not id(p.crop)or not num(p.readyAt,99999999999)then return nil end
 end
 for _,k in {'production','laundry'}do local p=v[k]
  if p~=false and (type(p)~='table'or not id(p.kind)or not num(p.readyAt,99999999999)or not num(p.amount,1000000))then return nil end
 end
 return copy(v)
end
S.copy=copy
return S
