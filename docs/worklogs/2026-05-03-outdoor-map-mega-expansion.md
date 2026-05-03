# 2026-05-03 야외 맵 대확장 1차

## 목표

- 사용자가 요청한 “맵의 대확장”을 첫 번째 안정 배치로 시작한다.
- 기존 중심 3x3 야외 구역은 보존하고, 바깥 도시를 실제 블록 파일과 건물 데이터로 크게 늘린다.
- 새 지형, 위험, 건물, 지구 감각, 향후 시나리오 확장을 위한 후킹 정보를 함께 넣는다.

## 구현

- `tools/generate_outdoor_map_expansion.py`를 추가했다.
  - 월드를 12x12로 갱신한다.
  - 기존 0_0부터 2_2까지의 중심 블록은 그대로 둔다.
  - 나머지 외곽 135개 블록을 결정적으로 생성한다.
  - 생성 건물은 `mapx_` 접두사를 쓰며 재실행 시 같은 ID로 교체된다.
- `game/data/outdoor/world_layout.json`의 `city_blocks`를 12x12로 확장했다.
- `game/data/outdoor/blocks/`에 외곽 블록을 추가해 총 144개 블록이 실제 데이터로 존재한다.
- `game/data/buildings.json`에 새 건물 168개를 추가했다.
  - 총 건물 수는 197개가 되었다.
  - 북쪽 상권, 동쪽 의료/업무 지구, 남쪽 주거 밀집지, 남동쪽 창고/정비 지대, 서쪽 대피 흔적, 중앙 환승로 같은 지구 구분을 넣었다.
  - 새 건물은 기존 실내 이벤트 템플릿을 연결받되, 독립 건물 ID와 위치를 가진다.
  - 모든 새 건물에 `entry_briefing`, `site_tags`, `scenario_hook`을 넣어 파밍 맥락과 다음 이벤트 심화 작업의 기준점을 남겼다.
- 지구별 대표 건물 5곳에는 전용 실내 사건 파일을 새로 연결했다.
  - `mapx_03_00_a` 재난 안내 서점: 무너진 책장을 힘으로 밀지, 테이프로 조용히 묶어 치울지 고른다.
  - `mapx_06_06_a` 환승로 구멍가게: 정류장 안내판을 읽고 큰길과 골목 우회 사이의 위험을 판단한다.
  - `mapx_11_11_a` 멈춘 연료 야드: 연료 잔량을 시끄럽게 흔들어 뺄지, 호스와 빈 통으로 조용히 받을지 고른다.
  - `mapx_00_08_a` 임시 대피 잡화점: 보급 상자를 전부 가져갈지, 필요한 것만 챙기고 남길지 고른다.
  - `mapx_09_04_a` 의료지구 편의점: 오염된 처치대를 급히 뒤질지, 장갑을 끼고 안전하게 분류할지 고른다.
- 대표 사건은 전부 큰 결정 결과를 보여주는 `story_cutscene`을 가진다.
  - 이번에는 이미 존재하는 실내 일러스트 자산을 연결했다.
  - 다음 시각 패스에서 대표 사건 전용 AI 일러스트를 생성해 교체하면 몰입도가 더 올라간다.

## 검증

- `res://tests/unit/test_content_library.gd`가 12x12 월드, 확장 블록, 190개 이상 건물 로딩을 확인하도록 갱신했다.
- `res://tests/unit/test_outdoor_map_expansion.gd`를 추가했다.
  - 대표 외곽 블록의 도로/위험/소품/건물 앵커를 확인한다.
  - 생성 건물 160개 이상과 `scenario_hook` 존재를 확인한다.
  - 먼 남동쪽 건물이 옛 8x8 경계 밖 좌표로 해석되고, 기존 건물 아트 폴백으로 렌더 가능함을 확인한다.
  - 전용 실내 사건이 붙은 대표 5개 건물의 이벤트 파일과 `story_cutscene` 선택지를 확인한다.
- 실행한 테스트:
  - `res://tests/unit/test_outdoor_map_expansion.gd`
  - `res://tests/unit/test_content_library.gd`
  - `res://tests/unit/test_outdoor_controller.gd`
  - `res://tests/unit/test_indoor_mode.gd`
  - `res://tests/unit/test_outdoor_world_runtime.gd`
  - `res://tests/unit/test_outdoor_map_view.gd`
  - `res://tests/unit/test_indoor_loot_tables.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`
- 검증 중 `test_indoor_loot_tables.gd`에서 마트 식품 진열대의 생활감 아이템 보장이 확률 롤에만 의존하는 문제가 드러났다.
  - `search_food_aisle`에서 `tea_bag` 하나를 확정 발견물로 추가해, 생존 식량뿐 아니라 일상적인 작은 물건이 항상 섞이게 했다.

## 다음 배치

- 새로 늘어난 건물은 아직 기존 실내 템플릿을 많이 재사용한다.
- 다음 배치는 지구별 대표 건물을 골라 전용 실내 사건, 큰 결정 선택지, 성공/실패 전체화면 일러스트를 붙이는 쪽이 좋다.
- 지도 뷰와 야외 이동 UX는 12x12 크기에서 글자/마커 밀도가 답답하지 않은지 실제 실행으로 봐야 한다.
