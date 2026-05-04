# 2026-05-04 가방·장착 UX 분리 패스

## 문제

- 장착 슬롯이 생긴 뒤 가방 화면에서 아이템을 확인하는 공간이 크게 줄었다.
- 파밍 후 가장 자주 하는 행동은 "무엇을 주웠는지 훑기"인데, 장비 슬롯 13칸이 같은 화면 위쪽을 차지하면서 목록의 호흡이 답답해졌다.
- 장착 관리는 중요하지만, 매번 아이템 목록을 볼 때 항상 같은 무게로 노출될 필요는 없다.

## 결정

- 생존 시트를 `가방 / 장착 / 도감` 3탭 구조로 분리했다.
- `가방` 탭은 아이템 목록을 넓게 읽는 화면으로 유지한다.
- `장착` 탭은 전체 장착 슬롯을 관리하는 전용 화면으로 둔다.
- 조합은 기존처럼 아이템 상세에서 시작하되, 조합 모드로 들어가면 목록 위의 조합 카드가 기준 재료와 두 번째 재료를 명확히 보여 준다.

## 구현

- `game/scenes/shared/survival_sheet.tscn`
  - `LoadoutTabButton`을 추가했다.
  - 기존 `InventoryPane` 안에 있던 `EquipmentRows`를 제거했다.
  - 새 `LoadoutPane` 아래에 `LoadoutFrame`, `LoadoutScroll`, `EquipmentRows`를 추가했다.
  - 장착 그리드는 전용 화면에서 더 읽기 좋도록 2열 카드 구조로 바꿨다.
- `game/scripts/ui/survival_sheet.gd`
  - `open_loadout()`과 `loadout` 탭 렌더링 경로를 추가했다.
  - 가방 힌트 문구를 "장착 관리는 장착 탭에서 따로 본다"는 방향으로 바꿨다.
  - 기본 가방 스크롤 영역을 520px로 키웠다.
  - 장착 카드는 더 큰 아이콘, 더 큰 글자, 빈 슬롯 안내 문구를 갖도록 다듬었다.
- `resources/ui/master/sheet/loadout_panel_expanded.png`
  - 장착 탭 전용 배경으로 쓰기 위해 AI 이미지 생성 후 프로젝트용 604x332 패널로 가공했다.
  - `UiKitResolver` 별칭과 마스터 매니페스트에 연결했다.

## 검증

- `res://tests/unit/test_survival_sheet.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/unit/test_equipment_loadout.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 다음 개선 후보

- 장착 탭에서 슬롯별 추천 장비 후보를 바로 보여 주는 "장착 후보" 영역을 추가한다.
- 가방 탭에 검색/필터/정렬 토글을 넣어 아이템 풀이 커져도 원하는 물건을 빠르게 찾게 한다.
- 조합 모드는 별도 `조합` 탭으로 승격할지, 현재처럼 선택 상세에서 시작하는 흐름을 유지할지 실제 플레이 후 판단한다.
