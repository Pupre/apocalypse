# 2026-05-04 백색 물류 허브 다중 결과 컷신

## 목표

- 사용자가 요청한 “하나의 건물에도 여러 장의 일러스트가 나오는 감성”을 실제 이벤트 구조에 반영한다.
- 백색 물류 허브를 첫 사례로 삼아, 같은 장소 안에서도 선택의 성격에 따라 서로 다른 결과 장면이 나오게 만든다.

## 변경 사항

- AI 이미지 생성으로 물류 허브 전용 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_logistics_dispatch_routes_success.png`
  - `resources/ui/master/indoor/indoor_story_logistics_pallet_crash_failure.png`
- `game/data/events/indoor/mapx_logistics_cold_chain_hub_01.json`을 확장했다.
  - `copy_dispatch_routes` 선택지는 배차 데스크에서 운송 경로를 베껴 적는 성공 컷신을 띄운다.
  - `drag_full_pallet` 선택지는 팔레트가 무너지는 실패 컷신을 띄운다.
- `game/scripts/ui/ui_kit_resolver.gd`와 UI 마스터 매니페스트에 신규 이미지 별칭을 추가했다.
- `game/tests/unit/test_outdoor_map_expansion.gd`에 전용 결과 컷신 자산 검증을 추가했다.

## 설계 판단

- 물류 허브는 “많이 발견했지만 전부 들 수 없다”는 게임의 핵심 재미와 잘 맞기 때문에 다중 컷신 첫 대상으로 골랐다.
- 새 컷신은 모두 보상 컷신이 아니다.
  - 운송 경로 컷신은 당장 물건보다 다음 선택지를 넓히는 지식 보상이다.
  - 팔레트 추락 컷신은 큰 욕심의 실패를 전체화면으로 보여 주어, 위험 선택이 단순 수치 손실보다 더 기억되게 한다.

## 검증

- 이벤트 JSON 파싱 확인.
- 신규 컷신 이미지 2장 960x480 확인.
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

모두 통과.
