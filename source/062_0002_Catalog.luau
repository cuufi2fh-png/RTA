local C=require(script.Parent.Parent.RTAContent.Catalog)
local W=table.clone(C.Weapons)
W.Grenade={name='수류탄',price=0,slot='Utility',rpm=35,automatic=false,magazine=1,reserve=0,reload=1,damage=65,speed=85,range=160,spread=0,adsSpread=0,recoil=1,adsFov=60,pellets=1,explosive=true,consumable=true,gravity=1}
W.Launcher={name='유탄 발사기',price=0,slot='Primary',rpm=45,automatic=false,magazine=4,reserve=12,reload=3,damage=70,speed=150,range=360,spread=1,adsSpread=.5,recoil=4,adsFov=55,pellets=1,explosive=true,gravity=.4}
return {Weapons=W,Vehicles=C.Vehicles,Homes=C.Homes,Limits={bullets=256,balance=100000000,inventory=256,goods=1000000},Armor={Light={name='경량 방탄복',price=450,capacity=50},Heavy={name='중량 방탄복',price=1400,capacity=100}}}
