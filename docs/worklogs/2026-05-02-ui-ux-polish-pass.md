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

## 후속 패스: 보행 방향과 실내 UX 재정렬

사용자 확인에서 주인공 발 모양이 모든 방향에서 오른쪽 이동 기준으로 보인다는 문제가 드러났다. `scripts/generate_player_walk_sprites.ps1`를 추가하고 주인공 4방향 idle/walk PNG를 다시 생성해, 좌우 이동은 각 방향으로 발이 뻗고 상하 이동은 하체가 좌우로 교차하도록 조정했다. `test_outdoor_controller.gd`에는 하체 픽셀 범위를 검사하는 회귀 테스트를 추가해 같은 문제가 다시 들어오지 않게 했다.

UI는 컨셉 일치보다 가독성과 흐름이 부족하다는 피드백을 반영했다. HUD, 생존 시트, 실내 화면의 주요 라벨 크기와 외곽선 대비를 올렸고, 실내 본문에는 장소 설명만 남기고 남은 물건/설치물/소란/완료 상태는 `ZoneStatusRow` 칩으로 분리했다.

실내 탐색 UX는 사용자가 먼저 “지금 이 장소에서 무엇을 할 수 있는지” 판단하도록 섹션 순서를 바꾸었다. 기존 이동 우선 흐름은 `여기서 할 일 -> 챙길 물건 -> 다른 구역 -> 막힌 길` 순서로 재정렬했고, 섹션 제목도 기능명이 아니라 플레이어 의도에 가까운 문장으로 바꾸었다. 이 변경은 아직 첫 구조 개선이므로, 이후 패스에서는 행동 카드 선택 전 미리보기, 위험 비교, 수량 선택, 지도/가방 전환 흐름까지 더 크게 손볼 수 있다.

추가 검증:

- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_survival_sheet.gd`
- `res://tests/unit/test_hud_presenter.gd`
- `res://tests/unit/test_survivor_creator.gd`
- `res://tests/unit/test_ui_theme.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 후속 패스: 시작 흐름과 야외 지도 UX

시작 화면과 생존자 생성 화면은 아직 기본 Godot 위젯 느낌이 강했고, 특히 생존자 생성은 선택지가 나열되어 있을 뿐 “이 사람이 어떻게 살아남는가”가 바로 읽히지 않았다. 타이틀 화면에는 결빙 휴대폰 UI 톤의 패널과 시작 버튼을 적용했고, 생존자 생성 화면도 같은 패널/버튼 계열로 맞추었다.

생존자 생성 UX는 직업, 난이도, 특성의 의미를 짧은 생존 문장으로 바꿔 보여준다. 선택 하단에는 `직업 / 난이도 / 특성 · 출발 가능 여부` 요약을 추가했고, 특성 포인트도 `남은 포인트`보다 `균형: 맞음 / 강점 대가 부족 / 약점 보상 남음`으로 표시한다. 목표는 사용자가 수치 계산보다 “이 사람은 어떤 방식으로 버틸 것인가”를 먼저 느끼게 하는 것이다.

야외 지도 오버레이는 이동 계획 도구로 읽히도록 보강했다. 헤더에 `탐색 블록 수 / 전체 블록 수 / 표시 건물 수`를 보여주고, 노란 점/밝은 구역/검은 구역의 의미를 범례로 노출했다. 또한 현재 위치로 다시 초점을 맞추는 아이콘 버튼을 추가해 지도를 드래그한 뒤 길을 잃는 느낌을 줄였다. 건물 상세 문구도 확인한 구역 수를 함께 보여주도록 정리했다.

추가 검증:

- `res://tests/unit/test_survivor_creator.gd`
- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_outdoor_map_view.gd`
- `res://tests/unit/test_hud_presenter.gd`
- `res://tests/smoke/test_bootstrap.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 후속 패스: 가방과 수량 획득의 판단 순서

이번 패스는 사용자가 좋아한 `여기서 할 일 -> 챙길 물건 -> 다른 구역` 재배치의 같은 원칙을 가방에 적용했다. 가방은 더 이상 획득 순서나 내부 데이터 순서 그대로 읽히지 않고, 플레이어가 먼저 묻게 되는 생존 질문에 맞춰 묶인다. 기본 탐색 상태에서는 `먹고 마실 것`, `불과 도구`, `입고 버틸 것`, `읽을 것`, `무거운 짐`, `재료와 기타` 섹션으로 나뉜다.

조합 모드에서는 일반 분류보다 “지금 조합을 완성하려는 목적”을 우선한다. 기준 재료를 맨 위에 고정하고, 실제로 조합 가능한 물건을 `조합 가능` 섹션으로 끌어올린 다음, 나머지는 `다른 물건`으로 내려 보낸다. 작은 변경이지만 사용자가 두 번째 재료를 찾는 시간을 줄이고, 조합 가능한 재료가 있다는 사실을 더 강하게 보여준다.

수량 보급 팝업도 손봤다. 생수처럼 여러 개 챙길 수 있는 물건은 `+` 버튼을 반복해서 누르는 대신 `최대` 버튼으로 바로 최대 유효 수량을 고를 수 있다. 상태 문구에는 선택한 수량이 가방에 더하는 무게를 표시해, “더 챙기면 얼마나 무거워지는가”를 결정 전에 읽게 했다.

추가 검증:

- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_survival_sheet.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
