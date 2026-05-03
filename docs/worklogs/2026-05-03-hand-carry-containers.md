# 2026-05-03 손짐 컨테이너 장착 보정

## 배경

- 사용자가 `plastic bag`을 주웠지만 장착할 수 없다고 지적했다.
- 기존 장착 UX는 등, 몸, 외투, 손, 발 같은 착용 장비 중심이라서 손에 들고 물건을 나눠 담는 봉투/바구니의 현실적인 가치가 빠져 있었다.
- 이벤트 데이터에는 `plastic_bag` 보상이 이미 등장했지만 기본 아이템 정의가 없어서, 파밍 결과와 아이템 데이터 계약도 어긋날 수 있었다.

## 변경

- `plastic_bag` 기본 아이템을 추가했다.
- `plastic_bag`, `shopping_bag`, `market_basket`, `cooler_bag`, `paper_bag`에 `equip_slot: hand_carry`와 운반 보너스를 부여했다.
- 생존 아이템 확장 생성기에서 일부 컨테이너 계열을 손짐/등/허리 장착 장비로 생성하도록 보정했다.
- 인벤토리 장착 UI와 실내 장착 요약에 `손짐` 슬롯을 추가했다.
- 장착 로드아웃, 콘텐츠 로딩, 생존 아이템 확장, 생존 시트 테스트에 손짐 컨테이너 검증을 추가했다.

## 의도

- 플레이어가 “가방을 안 챙겼는데 봉투라도 들고 가자”는 판단을 자연스럽게 할 수 있게 한다.
- 손짐 슬롯은 등 장비와 별개라서, 배낭을 멘 상태에서도 손에 봉투나 바구니를 들 수 있다.
- 수치는 임시 1차 밸런스다. 비닐봉투는 작지만 즉시 의미가 있고, 바구니/보냉 가방은 조금 더 무겁지만 더 많은 물건을 안정적으로 옮긴다.

## 검증

- `res://tests/unit/test_equipment_loadout.gd`
- `res://tests/unit/test_inventory_weight_model.gd`
- `res://tests/unit/test_survival_item_expansion.gd`
- `res://tests/unit/test_content_library.gd`
- `res://tests/unit/test_item_icon_resolver.gd`
- `res://tests/unit/test_survival_sheet.gd`
- `res://tests/unit/test_indoor_actions.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
