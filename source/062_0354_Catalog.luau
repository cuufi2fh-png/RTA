-- ReplicatedStorage.RTA.Catalog. IDs are persistence keys; never rename purchased IDs.
-- Weapons added here + matching ServerStorage.RTAAssets.Weapons Tool need no engine edits.
return {
 Weapons={
  Pistol={name='R9 권총',price=700,slot='Sidearm',rpm=360,automatic=false,magazine=12,reserve=72,reload=1.6,damage=22,speed=850,range=650,spread=2.0,adsSpread=.25,recoil=1.4,adsFov=55,pellets=1},
  SMG={name='V9 기관단총',price=2600,slot='Primary',rpm=750,automatic=true,magazine=30,reserve=150,reload=2.1,damage=15,speed=950,range=700,spread=3,adsSpread=.65,recoil=1.0,adsFov=55,pellets=1},
  Rifle={name='AR4 소총',price=5000,slot='Primary',rpm=600,automatic=true,magazine=30,reserve=150,reload=2.4,damage=28,speed=1400,range=1100,spread=2.3,adsSpread=.3,recoil=1.8,adsFov=50,pellets=1},
  Shotgun={name='Model 870',price=2100,slot='Shotgun',rpm=75,automatic=false,magazine=6,reserve=36,reload=2.8,damage=12,speed=750,range=230,spread=6,adsSpread=4,recoil=4.5,adsFov=60,pellets=8},
 },
 Homes={Apartment={name='시티 아파트',price=4000,width=36,depth=40},Townhouse={name='타운하우스',price=12000,width=52,depth=48},Villa={name='힐사이드 빌라',price=28000,width=68,depth=60}},
 Vehicles={
  Compact={name='시티 컴팩트',price=1800,speed=75,acceleration=32,turnRate=1.5,health=250},
  Sedan={name='도시 세단',price=6500,speed=110,acceleration=42,turnRate=1.35,health=450},
  Sport={name='RTA GT',price=18000,speed=155,acceleration=58,turnRate=1.2,health=350},
 },
 Armor={Light={name='경량 방탄복',price=450,capacity=50},Heavy={name='중량 방탄복',price=1400,capacity=100}},
 Businesses={
  Restaurant={name='레스토랑',price=3000,product='식사',cost=45,seconds=25,revenue=150},
  CashFactory={name='현금공장',price=6500,product='현금 묶음',cost=100,seconds=45,revenue=310},
  JewelryFactory={name='보석공장',price=8000,product='가공 보석',cost=160,seconds=55,revenue=470},
  Laundromat={name='현금세탁소',price=5000,product='세탁된 물품',cost=15,seconds=30,revenue=180},
  Cafe={name='카페',price=2200,product='코피',cost=25,seconds=18,revenue=100},
 },
 Robberies={
  Restaurant={name='레스토랑',cash=450,goods=2,seconds=25,cooldown=150,wanted=1,guards=1},
  Cafe={name='카페',cash=300,goods=1,seconds=20,cooldown=120,wanted=1,guards=1},
  Jewelry={name='보석상',cash=1400,goods=8,seconds=45,cooldown=240,wanted=2,guards=2},
  Bank={name='은행',cash=3500,goods=10,seconds=70,cooldown=360,wanted=3,guards=3},
  PoliceStation={name='경찰서',cash=6500,goods=15,seconds=100,cooldown=480,wanted=3,guards=5},
  MilitaryBase={name='군부대',cash=14000,goods=25,seconds=140,cooldown=600,wanted=4,guards=7},
 },
 Wanted={policeMax=3,militaryLevel=4,bombLevel=5,bombWarning=3,bombRadius=24,bombInterval=12},
 Limits={balance=100000000,goods=1000000,inventory=256,activeNPCs=24,bullets=256},
}
