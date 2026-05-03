# 2026-05-03 맵 다양화와 성능 최적화 패스

## 배경

플레이 테스트에서 두 가지 문제가 확인되었다.

- 맵은 12x12로 커졌지만 시작 지역과 먼 지역의 배치 차이가 약해, 멀리 이동하는 맛이 부족했다.
- 큰 맵을 한 번에 다루는 방식과 반복적인 UI 재구성 때문에 야외 이동, 아이템 줍기, 실내 행동에서 체감 렉이 있었다.

## 작업 내용

- 야외 맵 생성 규칙을 지구별로 분리했다.
  - 북부 시장가: 상점가 도로, 뒷골목, 아케이드 보도, 쇼핑카트/상자/간판 소품.
  - 중앙 환승로: 버스 루프, 언더패스, 정류장형 소품, 넓은 환승 광장.
  - 남동 공업지: 적재 야드, 연료 앞마당, 서비스 도로, 드럼통/상자/차량 소품.
  - 동부 의료지구: 클리닉 진입로, 구급차 차선, 의료지구 광장.
  - 남부 주거지: 좁은 주거 골목, 안마당, 막다른 길.
  - 서부 대피선: 통제선, 바리케이드, 대피 광장.
- 각 블록에 `layout_id`를 추가해 지구별 배치 의도를 데이터로 추적할 수 있게 했다.
- 생성 건물 수를 168개에서 282개로 늘렸다. 모든 신규 건물은 기존처럼 `scenario_hook`, 진입 브리핑, 지구 태그를 가진다.
- 야외 스트리밍을 최적화했다.
  - 활성 블록 창이 바뀔 때만 지형, 건물, 소품, 위협 노드를 재구성한다.
  - 전체 12x12 크기의 눈 배경 폴리곤 대신 현재 활성 블록 주변만 배경으로 만든다.
  - 전체 지도 오버레이는 매 프레임 재구성하지 않고 열 때 갱신한다.
- 실내 UI 렌더링을 최적화했다.
  - 가방 시트가 닫혀 있으면 실내 행동마다 인벤토리/도감 UI를 다시 그리지 않는다.
  - 아이템 선택은 전체 목록 재생성 대신 선택 상태, 상세 패널, 스크롤 여백만 갱신한다.
- 테스트용 이동속도 부스트는 `--playtest-speed` 실행 인자로만 켜지게 유지했다.

## 검증

- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_outdoor_world_runtime.gd`
- `res://tests/unit/test_outdoor_map_view.gd`
- `res://tests/unit/test_content_library.gd`
- `res://tests/unit/test_inventory_weight_model.gd`
- `res://tests/unit/test_heat_source_rules.gd`
- `res://tests/unit/test_supply_source_selection.gd`
- `res://tests/unit/test_indoor_loot_tables.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_survival_sheet.gd`
- `res://tests/unit/test_shared_crafting_sheet.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

`test_content_library`의 오류 로그는 고의로 잘못된 회귀 데이터를 거절하는지 확인하는 테스트 출력이며, 종료 코드는 정상이다.

## 남은 판단

- 이번 패스는 구조적 렉을 먼저 줄인 1차 최적화다. 실제 기기에서 여전히 끊긴다면 다음 병목은 전체 지도 오버레이의 스냅샷 캐싱, 인벤토리 대량 보유 시 행 가상화, 실내 액션 버튼 풀링 순서로 보는 것이 좋다.
- 지구별 배치 차이는 데이터 생성 규칙으로 크게 벌려 두었지만, 이후에는 특정 지구 전용 건물 일러스트와 이벤트를 추가해 “여기는 다른 동네다”라는 인상을 더 강하게 만들 수 있다.
