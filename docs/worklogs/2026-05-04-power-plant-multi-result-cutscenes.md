# 2026-05-04 발전소 제어동 다중 결과 컷신

## 목표

- 백색 물류 허브에서 시작한 “한 건물 안 여러 결과 컷신” 패턴을 발전소 지대에도 확장한다.
- 발전소 제어동의 핵심 감정인 작은 온기, 정비 기록, 위험한 배관 통로를 서로 다른 장면으로 분리한다.

## 변경 사항

- AI 이미지 생성으로 발전소 전용 컷신 2장을 추가했다.
  - `resources/ui/master/indoor/indoor_story_power_heat_trace_note_success.png`
  - `resources/ui/master/indoor/indoor_story_power_pipe_gallery_slip_failure.png`
- `game/data/events/indoor/mapx_power_plant_control_01.json`을 확장했다.
  - `read_heat_trace_note` 선택지는 죽은 계기판 옆 정비 기록을 읽고 온기의 단서를 발견하는 컷신을 띄운다.
  - `salvage_pipe_parts` 선택지는 얼어붙은 배관 통로에서 부품을 떼어내다 미끄러지는 위험 결과 컷신을 띄운다.
- `game/scripts/ui/ui_kit_resolver.gd`와 UI 마스터 매니페스트에 신규 이미지 별칭을 추가했다.
- `game/tests/unit/test_outdoor_map_expansion.gd`에 발전소 전용 결과 컷신 자산 검증을 추가했다.

## 설계 판단

- 정비 기록 읽기는 작은 행동처럼 보이지만, 이후 히터 선택을 가능하게 하는 정보 보상이다.
  - 그래서 단순 텍스트 피드백이 아니라 “죽은 계기판에서 아직 읽을 수 있는 질서를 찾았다”는 컷신으로 격상했다.
- 배관 부품 회수는 성공과 실패가 섞인 선택이다.
  - 부품은 얻지만 얼음과 금속 통로가 위험하다는 사실을 보여 주어, 발전소 지대가 물류 허브와 다른 압박을 갖도록 했다.

## 검증

- 이벤트 JSON 파싱 확인.
- 신규 컷신 이미지 2장 960x480 확인.
- `res://tests/unit/test_outdoor_map_expansion.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

모두 통과.
