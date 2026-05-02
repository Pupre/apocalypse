# 2026-05-02 UI/UX 고급화 1차 패스

## 작업 맥락

이번 패스는 “모든 이미지 리소스 교체와 UI 전체 고급화” 요청의 첫 실행 단위다. 한 번에 모든 화면을 완성했다고 보지 않고, 앞으로 모든 UI를 맞춰 갈 기준선을 먼저 세웠다. 기준은 차가운 휴대폰 화면, 결빙된 유리, 어두운 도시 생존 장비, 그리고 선택 전 위험/보상/시간이 빨리 읽히는 구조다.

## 생성 리소스

- `imagegen`으로 새 UI 방향 레퍼런스 `resources/ui/master/reference/ui_survival_phone_direction.png`를 만들었다.
- 이 레퍼런스를 기준으로 HUD, 실내 행동 카드, 가방 시트용 게임 UI PNG를 재생성했다.
- 새로 연결한 핵심 리소스:
  - `resources/ui/master/hud/*`: HUD 헤더, 게이지 프레임/필, 버튼, 상태 pill.
  - `resources/ui/master/indoor/indoor_action_row_*.png`: 기본/위험/획득/잠김 행동 행.
  - `resources/ui/master/indoor/indoor_location_strip_compact.png`
  - `resources/ui/master/indoor/indoor_reading_panel_plain.png`
  - `resources/ui/master/indoor/indoor_minimap_frame.png`
  - `resources/ui/master/sheet/*`: 가방 시트, 상세 패널, 탭, 행, 버튼, 조합 카드.
- `scripts/generate_ui_polish_assets.ps1`를 추가해 같은 톤의 PNG를 반복 생성할 수 있게 했다.

## UX 변경

- 실내 행동 버튼을 더 “게임다운 선택 카드”로 바꾸었다.
  - 행동 오른쪽에 `이동`, `탐색`, `획득`, `위험`, `막힘` 칩을 표시한다.
  - 행동의 시간은 칩 아래에 별도 표시해 라벨을 읽지 않아도 비용이 보인다.
  - 위험 행동은 새 위험 행 텍스처와 경고색 보조 라벨을 사용한다.
  - 발견한 물건과 수량 공급원은 획득 행 텍스처와 실제 아이템 아이콘을 우선 사용한다.
- HUD에 상태 요약 라벨을 추가했다.
  - 야외에서는 `추위`, `가방`, `속도`를 한 줄로 요약한다.
  - 기존 게이지는 유지하되, 숫자를 보지 않아도 현재 압력이 읽히게 했다.
- 가방 시트의 상태 요약을 강화했다.
  - `가방 적정/과중/과적`, 현재 무게, 야외 이동속도를 함께 표시한다.
  - 인벤토리 행에는 최대 3개의 아이템 태그 칩을 보여준다.
  - 조합 가능한 재료 강조와 기존 상세/조합 흐름은 유지했다.

## 검증

- `res://tests/unit/test_ui_kit_resolver.gd`
- `res://tests/unit/test_hud_presenter.gd`
- `res://tests/unit/test_survival_sheet.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 남은 판단

- 이번 패스는 HUD/실내/가방 기준선이다. 다음 UI 패스에서는 타이틀, 생존자 생성, 야외 지도 오버레이, 수량 선택 팝업, 도감 패널을 같은 톤으로 맞추는 것이 좋다.
- 모든 이미지 리소스의 완전 교체는 한 번의 커밋보다 여러 안정 단위가 낫다. 이번 패스에서 반복 생성 스크립트를 만들었으므로 이후 패스에서 UI와 월드 리소스 교체 속도를 더 높일 수 있다.
