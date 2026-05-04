# 2026-05-04 의료·대피·외곽 주거 랜드마크 확장

## 목표

직전 패스에서 물류, 발전소, 농촌, 검문소 랜드마크에 전용 이벤트와 컷신을 붙였다. 이번 패스는 아직 상대적으로 비어 있던 의료·관공 지구, 서부 대피선, 남서 외곽 주거지에도 같은 수준의 목적지를 추가하는 것이다.

## 구현

- 새 전용 실내 이벤트 3개를 추가했다.
  - `game/data/events/indoor/mapx_civic_triage_clinic_01.json`
  - `game/data/events/indoor/mapx_west_shelter_registration_01.json`
  - `game/data/events/indoor/mapx_outer_row_house_garage_01.json`
- `tools/generate_outdoor_map_expansion.py`에 새 랜드마크 오버라이드를 추가했다.
  - `mapx_09_01_b` 응급 분류 진료소
  - `mapx_00_05_a` 임시 대피 등록소
  - `mapx_02_09_b` 차고 딸린 연립 주택
- AI 이미지 생성으로 새 컷신 일러스트 3장을 만들고 `resources/ui/master/indoor/`에 저장했다.
  - `indoor_story_civic_triage_sort_choice.png`
  - `indoor_story_shelter_registration_choice.png`
  - `indoor_story_outer_garage_sling_success.png`
- `game/scripts/ui/ui_kit_resolver.gd`와 UI 마스터 매니페스트를 갱신해 새 컷신이 게임에서 로드되도록 했다.
- 생성기를 다시 실행해 `game/data/buildings.json`과 외곽 블록 데이터를 현재 생성 규칙 기준으로 맞췄다.
- `game/tests/unit/test_outdoor_map_expansion.gd`에 새 전용 이벤트와 컷신 이미지 해석 검증을 추가했다.

## 디자인 판단

- 응급 분류 진료소는 "약품을 많이 줍는 장소"가 아니라 잘못된 약품과 오염된 물자를 걸러내는 장소로 잡았다.
- 임시 대피 등록소는 사용자가 말한 재난 시뮬레이션의 핵심인 "내가 가져갈 몫"과 "남에게 남길 몫" 사이의 불편하지만 몰입되는 판단을 다룬다.
- 차고 딸린 연립 주택은 생활 아이템과 장착·운반 UX를 연결하기 위한 샘플이다. 단순히 물자를 얻는 대신 손짐 슬링을 만들어 다음 이동의 제약을 바꾸게 했다.

## 검증

- 신규 `mapx_` 실내 이벤트 JSON 12개 파싱 확인.
- 신규 이벤트의 아이템 참조가 현재 아이템 풀에 존재하는지 확인.
- 신규 컷신 이미지 3장 모두 960x480 확인.
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_content_library.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

`test_content_library.gd`는 의도적으로 깨진 회귀 샘플을 읽으며 오류 로그를 내지만, 테스트 자체는 `CONTENT_LIBRARY_OK`로 통과했다.

## Git

사용자 지시에 따라 `git add`, `git commit`, `git push`는 하지 않았다.
