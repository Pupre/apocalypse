# 2026-05-04 대지역 랜드마크 이벤트와 컷신 1차

## 목표

야외 대지역 세계화 1차에서 만든 랜드마크가 이름만 다른 건물이 아니라, 실제로 들어갔을 때 다른 판단과 장면을 주는 목적지가 되도록 만들었다. 이번 작업은 이후 자동화가 각 지역별 일러스트와 실내 이벤트를 계속 늘릴 수 있는 기준 샘플 역할도 한다.

## 구현

- 새 전용 실내 이벤트 4개를 추가했다.
  - `game/data/events/indoor/mapx_logistics_cold_chain_hub_01.json`
  - `game/data/events/indoor/mapx_power_plant_control_01.json`
  - `game/data/events/indoor/mapx_rural_greenhouse_01.json`
  - `game/data/events/indoor/mapx_highway_checkpoint_01.json`
- `tools/generate_outdoor_map_expansion.py`의 랜드마크 오버라이드를 갱신해, 다음 재생성 때도 전용 이벤트 연결이 유지되게 했다.
- 생성기를 다시 실행해 `game/data/buildings.json`의 랜드마크 연결을 갱신했다.
- AI 이미지 생성으로 새 컷신 일러스트 4장을 만들고 `resources/ui/master/indoor/`에 저장했다.
  - `indoor_story_logistics_cold_chain_choice.png`
  - `indoor_story_power_control_warmth_success.png`
  - `indoor_story_greenhouse_seed_cache_success.png`
  - `indoor_story_checkpoint_detour_choice.png`
- `game/scripts/ui/ui_kit_resolver.gd`와 UI 마스터 매니페스트를 갱신해 새 이미지가 `indoor/...` 경로로 로드되도록 했다.
- `game/tests/unit/test_outdoor_map_expansion.gd`가 새 랜드마크의 전용 이벤트, 큰 결정 선택지, 컷신 이미지 로딩까지 검증하도록 확장했다.

## 디자인 판단

- 물류 허브는 "많은 물건이 있는데 전부 가져갈 수 없다"는 재미를 전면에 세웠다.
- 발전소는 "도시 전체를 복구하는 판타지"가 아니라 "작은 온기 하나를 살리는 현실적인 성공"으로 잡았다.
- 비닐하우스는 즉시 식량과 장기 가능성 사이의 판단을 만들었다.
- 검문소는 단순 파밍지가 아니라 길 선택, 노출, 우회로 정보가 걸린 장소로 잡았다.

## 검증

- 신규 `mapx_` 실내 이벤트 JSON 9개 파싱 확인.
- 신규 이벤트의 아이템 참조가 현재 아이템 풀에 존재하는지 확인.
- 신규 컷신 이미지 4장 모두 960x480 확인.
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_content_library.gd`
- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

`test_content_library.gd`는 의도적으로 깨진 회귀 샘플을 읽으며 오류 로그를 내지만, 테스트 자체는 `CONTENT_LIBRARY_OK`로 통과했다.

## Git

사용자 지시에 따라 `git add`, `git commit`, `git push`는 하지 않았다.
