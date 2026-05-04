# 2026-05-04 대피선 급수 초소 다중 결과 컷신

## 목표

- 서쪽 대피선의 급수 초소를 “물 아이템을 얻는 장소”에서 “물의 무게와 공동성을 동시에 판단하는 장소”로 강화한다.
- 기존 대표 컷신과 범용 과적 컷신을 전용 결과 컷신으로 바꿔, 이 건물만의 선택 기억을 만든다.

## 변경 내용

- 새 AI 생성 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_shelter_water_prefilter_success.png`
  - `resources/ui/master/indoor/indoor_story_shelter_water_heavy_take_failure.png`
- `mapx_shelter_water_checkpoint_01.json`의 물 선택지를 보강했다.
  - `repair_prefilter_and_mark_share`는 프리필터를 고치고 공동 몫을 표시하는 전용 성공 컷신을 사용한다.
  - `take_all_checkpoint_water`는 너무 많은 물을 들고 문턱을 나서는 전용 실패 컷신을 사용한다.
- `ui_kit_resolver.gd`, 실내 매니페스트, 마스터 매니페스트에 신규 리소스를 등록했다.
- 야외 대지역 시나리오 테스트에 두 선택지의 전용 결과 컷신 기대값을 추가했다.

## 판단 기록

- 이 장소에서는 “물을 많이 얻었다”가 곧 좋은 결과가 아니다. 물은 가장 확실한 생존 자원이지만, 동시에 가장 즉각적으로 이동력을 망가뜨리는 무게이기도 하다.
- 그래서 성공 장면은 필터·표식·공동 몫을 중심에 두고, 실패 장면은 물통을 든 몸의 자세와 미끄러운 문턱을 중심에 두었다.

## 검증

- 이벤트 JSON 파싱
- 신규 이미지 960x480 확인
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
