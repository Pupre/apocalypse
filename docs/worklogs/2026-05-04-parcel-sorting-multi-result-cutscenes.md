# 2026-05-04 택배 분류 센터 다중 결과 컷신

## 목표

- 남부 물류 벨트의 택배 분류 센터를 단순 랜덤 박스 파밍지가 아니라, 배송 흐름을 읽어 다음 목적지를 정하는 장소로 강화한다.
- 기존 대표 컷신을 전용 성공 컷신으로 승격하고, 빠른 랜덤 파밍에도 결과 컷신을 붙여 선택의 대가가 장면으로 남게 만든다.

## 변경 내용

- 새 AI 생성 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_parcel_route_map_success.png`
  - `resources/ui/master/indoor/indoor_story_parcel_random_boxes_failure.png`
- `mapx_parcel_sorting_center_01.json`의 핵심 선택지를 보강했다.
  - `map_parcel_routes`는 배송 철망과 라벨을 읽어 다음 목적지를 찾는 전용 성공 컷신을 사용한다.
  - `open_random_parcels`는 작은 물건을 얻지만 포장재 소음과 불확실성을 남기는 전용 결과 컷신을 사용한다.
- `ui_kit_resolver.gd`, 실내 매니페스트, 마스터 매니페스트에 신규 리소스를 등록했다.
- 야외 대지역 시나리오 테스트에 두 선택지의 전용 결과 컷신 기대값을 추가했다.

## 판단 기록

- 이 장소의 재미는 “상자 안에 뭐가 들었을까”도 있지만, 더 중요한 축은 “배송 동선 자체가 정보가 된다”는 점이다.
- 그래서 성공 장면은 지도와 철망 카트를 중심에 두고, 실패 장면은 케이블·마스크·죽은 보조배터리·완충재가 뒤섞인 작은 득실을 중심에 두었다.

## 검증

- 이벤트 JSON 파싱
- 신규 이미지 960x480 확인
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
