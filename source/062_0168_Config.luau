return {
 Brand='RTA',
 MapFolder='Pacific Hills',
 MapCenter=Vector3.new(-6,0,40),
 MapSpan=8200,
 MiniSpan=850,
 -- Move Workspace.RTAPoints anchors to the exact entrance of each facility.
 -- These are editable planning markers, not functional businesses or police systems.
 Points={
  {id='Bank',name='은행',icon='bank',color=Color3.fromRGB(89,210,81),position=Vector3.new(700,215,2250)},
  {id='Police',name='경찰서',icon='shield',color=Color3.fromRGB(63,168,245),position=Vector3.new(1050,215,2120)},
  {id='Garage',name='차량 정비소',icon='car',color=Color3.fromRGB(20,188,243),position=Vector3.new(1280,215,2390)},
  {id='Hospital',name='병원',icon='medical',color=Color3.fromRGB(244,93,104),position=Vector3.new(830,215,2640)},
  {id='Shop',name='상점',icon='bag',color=Color3.fromRGB(245,190,39),position=Vector3.new(1250,215,2690)},
  {id='House',name='주택',icon='house',color=Color3.fromRGB(184,125,76),position=Vector3.new(640,215,2500)},
 },
 WeaponSlots={
  {id='Sidearm',name='권총',icon='pistol'},
  {id='Primary',name='주무기',icon='rifle'},
  {id='Utility',name='보조 장비',icon='bag'},
  {id='Shotgun',name='산탄총',icon='shotgun'},
 },
 -- Tools may set RTAWeaponSlot = Sidearm / Primary / Utility / Shotgun,
 -- DisplayName, Ammo, ReserveAmmo. Existing Tools only; no item grants.
}
