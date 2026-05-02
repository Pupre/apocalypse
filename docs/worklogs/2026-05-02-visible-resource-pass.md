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

- 실내 일러스트의 공통 사용 문제는 추가 패스에서 건물 분류별 선택 구조로 해소했다. 이후에는 이벤트 중요도나 스토리 컷신에 따라 더 특수한 장면을 보여주는 방향이 좋다.
- 야외 위험 피드백은 체감 우선으로 강하게 잡았다. 실제 플레이 확인 후 너무 과하면 알파와 흔들림 강도를 낮추면 된다.

## 추가 패스: 건물 분류별 실내 일러스트

편의점 패널의 방향성이 좋았기 때문에, 같은 톤의 AI 생성 일러스트를 건물 분류별로 확장했다. 목표는 실내 탐색 화면이 항상 같은 이미지로 보이지 않고, “지금 들어온 장소가 어디인지”를 읽기 카드 상단에서 즉시 느끼게 하는 것이다.

### 구현 내용

- 새 AI 생성 리소스 네 장을 추가했다.
  - `resources/ui/master/indoor/indoor_event_medical_clinic.png`: 의원/약국 계열의 얼어붙은 진료실과 약품 보관 공간.
  - `resources/ui/master/indoor/indoor_event_residential_stairwell.png`: 아파트/주거 계열의 재난 이후 공동 복도와 계단참.
  - `resources/ui/master/indoor/indoor_event_industrial_garage.png`: 차고/창고/철물점 계열의 차가운 작업장과 보관소.
  - `resources/ui/master/indoor/indoor_event_food_kitchen.png`: 식당/카페 계열의 얼어붙은 주방.
- `IndoorDirector.get_event_illustration_asset()`을 추가해 이벤트 지정값, 건물 지정값, 건물 ID, 건물 분류 순서로 일러스트를 고르게 했다.
- `IndoorMode`가 고정 편의점 이미지를 쓰지 않고, 현재 건물에 맞는 일러스트를 읽기 카드에 갱신하도록 바꾸었다.
- `UiKitResolver`와 리소스 매니페스트에 새 실내 일러스트 별칭과 메타데이터를 등록했다.

### 검증

- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 추가 패스: 식당 주방 분기와 행동 위험 미리보기

건물별 일러스트가 붙은 뒤에는, 그 이미지가 단순 장식으로 끝나지 않도록 식당 내부의 선택 구조를 먼저 깊게 만들었다. 작은 식당은 이제 홀과 보관실 사이에 주방이 있고, 주방 수색은 “빨리 뒤져서 다칠 위험을 감수한다”와 “작업 장갑으로 시간을 더 쓰고 조용히 연다” 사이의 선택으로 바뀌었다.

### 구현 내용

- `restaurant_01` 실내 이벤트를 홀, 주방, 안쪽 보관실 3구역 구조로 확장했다.
- 주방 수색에 두 가지 분기를 추가했다.
  - 빠른 수색: 25분, 소란, 손등 부상, 피로 증가를 감수하고 조리 도구와 온식 재료를 찾는다.
  - 작업 장갑 수색: 작업 장갑이 필요하고 35분이 걸리지만 소란과 부상 없이 같은 핵심 재료를 찾는다.
- 행동 버튼에 보조 라벨을 붙여 `필요: 작업 장갑`, `소란 +2`, `체력 -1`, `피로 +1` 같은 위험 정보를 행동 전에 볼 수 있게 했다.
- 이 보조 라벨은 기존 행동명 텍스트를 바꾸지 않아서 기존 UI 테스트와 버튼 탐색 흐름을 유지한다.

### 검증

- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_indoor_content_depth.gd`
- `res://tests/unit/test_indoor_actions.gd`
- `res://tests/unit/test_indoor_loot_tables.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 추가 패스: 야외 위험 예고와 외곽 위험 밀도

야외 위험은 접촉 후 피드백만 강한 상태였기 때문에, 플레이어가 위험을 밟기 전에 판단할 수 있는 예고를 HUD에 추가했다. 이제 건물 진입 힌트가 없는 상황에서 위험 구역 근처에 접근하면 `위험: 검은 빙판 · 체온 -1.5 · 피로 +1.5 · 부상 -0.5`처럼 예상 압력이 먼저 표시된다.

### 구현 내용

- 야외 HUD가 근처 위험 구역을 감지해 체온 손실, 피로 증가, 부상, 지연 시간을 미리 요약한다.
- 기존 빙판/틈바람 외에 `snow_drift`, `whiteout` 위험 타입을 시각 색상과 데칼 선택에 연결했다.
- `0_2`, `1_2`, `2_0`, `2_2` 외곽 블록에 눈더미와 시야 불량 위험을 추가했다.
- 위험 접촉 카메라 흔들림도 위험 종류에 따라 강도를 다르게 잡았다.

### 검증

- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_outdoor_world_runtime.gd`
- `res://tests/unit/test_outdoor_map_view.gd`
