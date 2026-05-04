# 2026-05-04 임시 대피 등록소 다중 결과 컷신

## 목표

- 서쪽 대피선의 임시 대피 등록소를 단순 보급 상자 파밍지가 아니라, 공동 물자를 어떻게 다룰지 묻는 장소로 강화한다.
- 같은 건물 안에서도 “남겨 두는 선택”과 “전부 쓸어 담는 선택”이 서로 다른 전체화면 장면으로 기억되게 만든다.

## 변경 내용

- 새 AI 생성 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_shelter_personal_share_success.png`
  - `resources/ui/master/indoor/indoor_story_shelter_empty_boxes_failure.png`
- `mapx_west_shelter_registration_01.json`의 공동 보급 상자 선택지를 보강했다.
  - `take_only_personal_share`는 전용 성공 컷신을 사용한다.
  - `empty_relief_boxes_fast`는 전용 실패 컷신과 전체화면 스토리 문구를 사용한다.
- `ui_kit_resolver.gd`, 실내 매니페스트, 마스터 매니페스트에 신규 리소스를 등록했다.
- 야외 대지역 시나리오 테스트에 두 선택지의 전용 결과 컷신 기대값을 추가했다.

## 판단 기록

- 기존 `indoor_story_shelter_registration_choice.png`는 장소 대표 일러스트로 남기고, 실제 결과는 새 성공/실패 컷신으로 분리했다.
- 이 장소의 핵심 감정은 “얼마나 많이 얻었는가”보다 “내가 떠난 뒤 이곳이 어떤 상태로 남는가”라고 보고, 빈 상자·다시 묶은 상자·젖은 명단·접이식 의자를 시각 키워드로 잡았다.

## 검증

- 이벤트 JSON 파싱
- 신규 이미지 960x480 확인
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
