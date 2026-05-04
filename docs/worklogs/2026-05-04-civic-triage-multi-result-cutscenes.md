# 2026-05-04 응급 분류 진료소 다중 결과 컷신

## 목표

- 의료·관공 지구의 응급 분류 진료소가 단순한 약품 파밍지가 아니라, 안전한 분류와 성급한 회수 사이의 차이를 장면으로 체감하게 만든다.
- 한 건물 안에서도 선택마다 다른 결과 일러스트가 나오도록 다중 컷신 패턴을 확장한다.

## 변경 내용

- 새 AI 생성 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_civic_triage_gloved_sort_success.png`
  - `resources/ui/master/indoor/indoor_story_civic_triage_fast_sweep_failure.png`
- `mapx_civic_triage_clinic_01.json`의 약품 분류 선택지를 보강했다.
  - `sort_safe_medicine_with_gloves`는 전용 성공 컷신을 사용한다.
  - `sweep_medicine_fast`는 전용 실패 컷신과 전체화면 스토리 문구를 사용한다.
- `ui_kit_resolver.gd`, 실내 매니페스트, 마스터 매니페스트에 신규 리소스를 등록했다.
- 야외 대지역 시나리오 테스트에 두 선택지의 전용 결과 컷신 기대값을 추가했다.

## 판단 기록

- 이미 존재하던 기본 `indoor_story_civic_triage_sort_choice.png`는 장소의 대표 선택 일러스트로 남기고, 실제 선택 결과는 새 성공/실패 컷신으로 분리했다.
- 의료 구역의 재미는 “약이 있다”보다 “지금 들고 나가도 되는 약인지 판단한다”에 가깝다고 보고, 장갑·라벨·젖은 포장·소음 같은 현실적인 기준을 강조했다.

## 검증

- 이벤트 JSON 파싱
- 신규 이미지 960x480 확인
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
