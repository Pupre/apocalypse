# 2026-05-02 시각 리소스 및 체감 피드백 패스

## 작업 맥락

이번 패스는 작은 시스템 개선에서 멈추지 않고, 플레이어가 실행 화면에서 바로 알아볼 수 있는 변화에 우선순위를 두었다. 목표는 “재난 이후의 차가운 도시를 실제로 걷고 있다”는 감각과 “실내 탐색이 장소와 사건을 가진다”는 감각을 강화하는 것이다.

## 구현 내용

- 새 AI 생성 리소스 `resources/ui/master/feedback/frost_screen_overlay_phone_ice.png`를 추가했다.
  - 휴대폰 화면 가장자리가 얼어붙고 균열이 번지는 형태의 투명 오버레이다.
  - 기존 `feedback/frost_screen_overlay.png` 별칭은 새 리소스를 기본으로 가리키도록 변경했다.
- 야외 위험 구역의 시각 존재감을 키웠다.
  - 빙판/틈바람 위험에 반투명 경고 영역, 큰 데칼, 글로우 데칼을 함께 그린다.
  - 위험 접촉 시 새 결빙 오버레이가 즉시 강하게 번지고, 카메라가 짧게 흔들린다.
- 새 AI 생성 리소스 `resources/ui/master/indoor/indoor_event_convenience_frozen.png`를 추가했다.
  - 실내 읽기 카드 상단에 표시되는 재난 직후 편의점 내부 일러스트다.
  - 실내 탐색 화면이 단순 텍스트 카드가 아니라 장소 분위기를 가진 화면으로 보이게 한다.
- 실내 결과 메시지에 상황 태그와 색상 톤을 붙였다.
  - 발견/획득/위험/상황을 구분해 같은 텍스트라도 사건 피드백처럼 읽히게 했다.

## 생성 리소스 메모

- 결빙 오버레이는 `imagegen` 기본 도구로 생성한 뒤, 마젠타 크로마키 배경을 로컬에서 제거해 투명 PNG로 만들었다.
- 실내 편의점 일러스트는 `imagegen` 기본 도구로 생성하고, UI 패널에 맞게 `960x480`으로 축소했다.
- 두 리소스 모두 최종본은 프로젝트 `resources/ui/master/...` 아래에 저장했고, 생성 원본은 `.codex/generated_images`에 그대로 남겨 두었다.

## 검증

- `res://tests/unit/test_inventory_weight_model.gd`
- `res://tests/unit/test_heat_source_rules.gd`
- `res://tests/unit/test_supply_source_selection.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 남은 판단

- 실내 일러스트는 현재 모든 실내 건물에 공통으로 쓰인다. 다음 패스에서는 건물 분류별 일러스트를 나누거나, 이벤트 중요도에 따라 다른 장면을 보여주는 구조로 확장하는 편이 좋다.
- 야외 위험 피드백은 체감 우선으로 강하게 잡았다. 실제 플레이 확인 후 너무 과하면 알파와 흔들림 강도를 낮추면 된다.
