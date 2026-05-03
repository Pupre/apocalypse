# 2026-05-03 생존 아이템 풀 확장 1차

## 목표

- 어느 건물을 털어도 같은 물건만 반복되는 느낌을 줄인다.
- 미래 맵 확장을 전제로, 지금 당장 모든 아이템이 쓰이지 않더라도 생존 게임에 어울리는 큰 카탈로그를 먼저 깐다.
- 아이템 수 증가가 단순 목록 증가로 끝나지 않도록 조합, 장착, 도감, 파밍 후보, 아이콘 리소스까지 함께 연결한다.

## 구현

- `game/data/items_survival_expansion.json`
  - 신규 생존 아이템 500개를 추가했다.
  - 분류는 음식, 음료, 의료, 도구, 생활/보온 재료, 수납, 착용 장비, 지식/문서, 조합 결과물로 나뉜다.
  - 무게, 태그, 장착 슬롯, 장착 효과, 소모 효과, 도감 설명을 포함한다.
- `game/data/crafting_combinations_survival_expansion.json`
  - 신규 조합식 240개를 추가했다.
  - 방한 보강, 수납 개선, 응급 처치, 임시 도구, 정리 키트처럼 생존 맥락이 납득되는 방향으로 구성했다.
- `game/data/loot_profiles_survival_expansion.json`
  - 현재 구현된 건물과 미래 건물 태그를 함께 고려한 문맥형 루트 프로필을 추가했다.
  - 기존 건물의 손작성 루트 테이블을 덮지 않고, 추가 후보로 합쳐 파밍 다양성을 늘린다.
  - 문맥형 후보는 기본적으로 낮은 가중치로 섞어서, 기존 건물의 대표 물건과 장소감이 확장 아이템에 밀려 사라지지 않게 했다.
- `resources/items/icons/`
  - 신규 아이템 500개에 대해 24px/32px 컷아웃 아이콘을 각각 생성했다.
  - `item_icons_manifest.json`에 신규 아이템 아이콘 경로를 등록했다.
- `ContentLibrary`
  - 기본 아이템/조합 파일과 확장 아이템/조합 파일을 병합해서 읽는다.
  - 문맥형 루트 프로필을 건물 ID, 건물 분류, 사이트 태그 기준으로 조회한다.
- 실내 가방 UI
  - 가방 탭 상단에 장비 슬롯 스트립을 추가했다.
  - 빈 슬롯과 장착 슬롯을 분리해, 장착 시스템이 커져도 유저가 지금 몸에 걸친 장비를 먼저 파악할 수 있게 했다.

## 판단과 가정

- 500개 아이템을 모두 개별 고품질 AI 이미지로 생성하면 이번 배치가 이미지 검수에서 막힐 가능성이 높았다. 그래서 이번에는 먼저 전 아이템을 식별 가능한 대량 아이콘 팩으로 연결하고, 스토리 핵심 아이템과 자주 보이는 장비부터 고품질 AI 일러스트로 교체하는 방향을 남겼다.
- 조합식 240개는 전부 손작성 서사 조합으로 완성된 상태라기보다, 대형 아이템 풀을 실제 게임 시스템에 연결하기 위한 1차 생존 조합 그래프다. 이후 플레이 테스트에서 자주 쓰는 조합부터 더 깊은 선택지와 결과 연출을 붙이면 좋다.
- 확장 아이템은 현재 건물에 어울리는 것만 골라 노출하되, 데이터 자체는 미래 맵과 미래 건물을 상정하고 넓게 준비했다. 즉 “지금 당장 안 보이는 아이템”도 의도적으로 존재한다.

## 검증

- `res://tests/unit/test_content_library.gd`
- `res://tests/unit/test_survival_item_expansion.gd`
- `res://tests/unit/test_item_icon_resolver.gd`
- `res://tests/unit/test_crafting_resolver.gd`
- `res://tests/unit/test_crafting_codex.gd`
- `res://tests/unit/test_inventory_weight_model.gd`
- `res://tests/unit/test_heat_source_rules.gd`
- `res://tests/unit/test_supply_source_selection.gd`
- `res://tests/unit/test_life_world_item_matrix.gd`
- `res://tests/unit/test_life_world_loot_profiles.gd`
- `res://tests/unit/test_indoor_loot_tables.gd`
- `res://tests/unit/test_shared_crafting_sheet.gd`
- `res://tests/unit/test_indoor_actions.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_indoor_content_depth.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
