# 2026-05-04 고속도로 휴게소 다중 결과 컷신

## 목표

- 국도 휴게 구역의 휴게소 자판기 코너를 단순 간식 파밍지가 아니라, 소리를 아낄지 시간을 아낄지 선택하는 장소로 강화한다.
- 기존 대표 컷신과 범용 소음 실패 컷신을 전용 결과 컷신으로 바꿔, 이 건물만의 성공과 실패가 남게 만든다.

## 변경 내용

- 새 AI 생성 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_rest_stop_vending_panel_success.png`
  - `resources/ui/master/indoor/indoor_story_rest_stop_vending_glass_failure.png`
- `mapx_highway_rest_stop_vending_01.json`의 자판기 선택지를 보강했다.
  - `open_vending_service_panel`은 철사 고리로 서비스 패널을 조용히 여는 전용 성공 컷신을 사용한다.
  - `smash_vending_glass`는 깨진 유리와 굴러가는 캔 소리를 보여 주는 전용 실패 컷신을 사용한다.
- `ui_kit_resolver.gd`, 실내 매니페스트, 마스터 매니페스트에 신규 리소스를 등록했다.
- 야외 대지역 시나리오 테스트에 두 선택지의 전용 결과 컷신 기대값을 추가했다.

## 판단 기록

- 이 장소의 핵심은 “먹을 것을 얻었다”보다 “휴게소 전체에 소리를 냈는가”다.
- 성공 장면은 유리가 intact한 상태와 낮은 자세의 작업을 중심에 두고, 실패 장면은 깨진 유리·굴러가는 캔·국도 창밖의 노출을 중심에 두었다.

## 검증

- 이벤트 JSON 파싱
- 신규 이미지 960x480 확인
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
