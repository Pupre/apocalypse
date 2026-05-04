# 2026-05-04 비닐하우스 다중 결과 컷신

## 목표

- 농촌·비닐하우스 대지역이 도시형 건물과 다른 감정을 갖도록, 식량과 물, 다음 가능성의 선택을 컷신으로 분리한다.
- 같은 비닐하우스 안에서도 신중한 분류, 급한 파밍, 물 확보가 서로 다른 결과처럼 느껴지게 한다.

## 변경 사항

- AI 이미지 생성으로 비닐하우스 전용 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_greenhouse_fast_strip_failure.png`
  - `resources/ui/master/indoor/indoor_story_greenhouse_water_barrel_success.png`
- `game/data/events/indoor/mapx_rural_greenhouse_01.json`을 확장했다.
  - `strip_seedling_trays_fast` 선택지는 선반을 급하게 훑다가 상토와 얼음 조각을 쏟는 실패 컷신을 띄운다.
  - `chip_water_barrel_ice` 선택지는 얼어붙은 물통을 조심히 깨 쓸 수 있는 물을 확보하는 컷신을 띄운다.
- `game/scripts/ui/ui_kit_resolver.gd`와 UI 마스터 매니페스트에 신규 이미지 별칭을 추가했다.
- `game/tests/unit/test_outdoor_map_expansion.gd`에 비닐하우스 전용 결과 컷신 자산 검증을 추가했다.

## 설계 판단

- 비닐하우스의 핵심 재미는 “무엇을 먹을 것인가”보다 “지금 먹을 것과 다음 가능성을 어떻게 나눌 것인가”에 가깝다.
- 그래서 빠른 선반 훑기는 단순 보상 선택이 아니라, 소음과 손실을 남기는 선택으로 연출했다.
- 물통 얼음 깨기는 대단한 보상은 아니지만 실제 재난 상상에서 매우 납득 가능한 행동이다.
  - 작은 피로와 소리를 감수하고 물을 얻는 순간을 컷신으로 승격해 생활감 있는 파밍 기대를 강화했다.

## 검증

- 이벤트 JSON 파싱 확인.
- 신규 컷신 이미지 2장 960x480 확인.
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

모두 통과.
