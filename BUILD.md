# 설치와 확인

이 자료는 Roblox Studio용 RBXM 모델 두 개입니다. 전체 게임 place 파일 또는 독립 실행 빌드는 아닙니다. 저장된 패키지 원본을 복사했으며 이번 작업에서 새로 내보내거나 실행 검증하지 않았습니다.

1. Roblox Studio에서 별도 빈 테스트 장소를 엽니다.
2. `build/RTA_PoliceHills_Systems_20261018.rbxm`을 Insert from File로 삽입하고 최상위 폴더를 선택합니다.
3. Command Bar에서 실행합니다.

```lua
require(game:GetService('Selection'):Get()[1].InstallSystems).install()
```

4. `build/RTA_PoliceHills_Map_20261018.rbxm`을 삽입하고 최상위 폴더를 선택합니다.
5. Command Bar에서 실행합니다.

```lua
require(game:GetService('Selection'):Get()[1].InstallMap).install()
```

동일 이름 맵·시스템이 있으면 설치가 중단됩니다. 기존 작업 장소에 중복 설치하지 마십시오. 외부 이미지·사운드·애니메이션의 권한, 경험 서비스 설정 및 상품 ID는 원본 경험에 종속될 수 있습니다. 별도 장소에서는 추가 설정이 필요합니다. 실제 구매를 검증 목적으로 수행하지 마십시오.

PC 조작 참고: W/A/S/D 이동·운전, E 상호작용, P 휴대폰, M 지도, F 낚싯대. 낚시는 캐스팅·챔질·릴 조작 후 FISHING 시설에서 물고기를 판매합니다.

학교가 실행 가능한 전체 빌드를 요구한다면 이 모델 패키지만으로 충족한다고 판단하지 말고, 완전한 place 파일 또는 학교가 허용하는 Roblox 실행 방식과 플레이 영상을 추가해야 합니다.
