# 2026-05-04 국도 검문소 다중 결과 컷신

## 목표

- 국도 검문·휴게 구역이 단순 통로가 아니라, 빠른 길과 안전한 우회, 버려진 이동수단의 작은 보급 사이를 고르는 장소처럼 느껴지게 한다.
- 같은 검문소 안에서도 노출 위험, 우회 판단, 생활감 있는 버스 수색이 서로 다른 장면으로 남게 한다.

## 변경 사항

- AI 이미지 생성으로 국도 검문소 전용 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_checkpoint_exposed_crossing_failure.png`
  - `resources/ui/master/indoor/indoor_story_checkpoint_bus_seat_cache_success.png`
- `game/data/events/indoor/mapx_highway_checkpoint_01.json`을 확장했다.
  - `cross_roadblock_now` 선택지는 바리케이드를 넘어 노출된 큰길로 나가는 위험 컷신을 띄운다.
  - `search_bus_seats` 선택지는 버려진 버스 좌석 밑에서 작은 생필품을 찾는 컷신을 띄운다.
- `game/scripts/ui/ui_kit_resolver.gd`와 UI 마스터 매니페스트에 신규 이미지 별칭을 추가했다.
- `game/tests/unit/test_outdoor_map_expansion.gd`에 국도 검문소 전용 결과 컷신 자산 검증을 추가했다.

## 설계 판단

- 빠른 큰길 선택은 이동 시간을 줄이지만, 재난 상황에서 “넓고 드러난 곳”이 주는 공포를 가져야 한다.
  - 그래서 수치상 체온·피로 손실뿐 아니라, 눈보라 한가운데 드러나는 장면을 전체화면 컷신으로 보여 준다.
- 버스 수색은 큰 결정보다는 작은 생활 흔적의 보상이다.
  - 사용자가 원한 일상 물건 파밍 감각에 맞춰, 생수와 담요, 꺼진 보조배터리 같은 평범한 물건이 재난 속에서 기대가 되는 순간을 강화했다.

## 검증

- 이벤트 JSON 파싱 확인.
- 신규 컷신 이미지 2장 960x480 확인.
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

모두 통과.
