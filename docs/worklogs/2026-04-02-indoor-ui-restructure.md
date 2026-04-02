# 실내 UI 재구성 작업 기록

- 날짜: 2026-04-02
- 작업: 실내 UI/UX 재구성
- 범위: 실내 화면 레이아웃, 구조도/가방 노출 방식, shared HUD 경계 정리
- 저장소: `/home/muhyeon_shin/packages/apocalypse`
- 활성 브랜치: `playtest-mart-indoor-content`

## 작업 배경

실내 프로토타입은 기능적으로는 계속 확장되고 있었지만, 한 화면에 구조도, 소지품, 장착 장비, shared HUD, 현재 위치 설명, 결과 텍스트, 행동 버튼이 동시에 떠 있어서 읽기가 매우 어려워졌다. 사용자는 특히 "무엇이 현재 위치 설명인지", "무엇이 상태 정보인지", "지금 당장 어떤 행동을 해야 하는지"를 구분하려면 집중해서 읽어야 한다고 피드백했다.

## 변경 전 상태

기존 `IndoorMode`는 메인 컬럼과 우측 사이드바로 구성되어 있었고, 우측에는 구조도와 인벤토리/장착 상태가 항상 노출되어 있었다. 또한 `RunShell`의 shared HUD도 실내에서 계속 살아 있었기 때문에 실내 UI 자체가 별도 모드라기보다 여러 정보 패널이 겹쳐 있는 대시보드처럼 동작했다.

## 문제점 또는 리스크

- 정보 계층이 무너져서 현재 위치 설명과 행동 선택지가 중심에 오지 못했다.
- 모바일 기준으로는 항상 보이는 사이드바가 지나치게 답답했다.
- shared HUD와 실내 UI가 같은 정보를 다른 톤으로 반복 노출해 중복이 심했다.
- 앞으로 시스템이 더 늘어나면 화면이 더 복잡해질 가능성이 높았다.

## 변경 전략

실내 화면을 "대시보드"가 아니라 "읽기와 선택" 중심 화면으로 재정의한다. 메인 화면에는 건물/위치/시각/생존 수치, 현재 구역 설명, 최근 결과, 행동 선택지만 남기고, 구조도와 가방은 필요할 때만 여는 오버레이/시트로 뺀다. shared HUD는 실내에서 경쟁하지 않도록 숨기거나 완전히 축소한다.

## 구현 메모

- 시작 상태
  - 계획 문서: `docs/specs/indoor-ui-restructure-design.md`
  - 구현 계획: `docs/superpowers/plans/2026-04-02-indoor-ui-restructure.md`
  - 현재 핵심 파일:
    - `game/scenes/indoor/indoor_mode.tscn`
    - `game/scripts/indoor/indoor_mode.gd`
    - `game/scripts/indoor/indoor_director.gd`
    - `game/scripts/indoor/indoor_minimap.gd`
    - `game/scripts/run/run_controller.gd`
    - `game/scripts/run/hud_presenter.gd`

- 테스트 계약 고정
  - 변경한 파일:
    - `game/tests/unit/test_indoor_mode.gd`
    - `game/tests/unit/test_run_controller_live_transition.gd`
  - 무엇을 바꿨는지:
    - 실내 사이드바 제거
    - 실내 전용 상단바 존재
    - `구조도` 버튼, `가방` 버튼, 구조도 오버레이, 가방 시트 존재
    - 실내 진입 시 shared HUD가 숨겨져야 한다는 조건을 테스트에 추가
  - 왜 바꿨는지:
    - UI를 바꾸기 전에 새 화면 구조를 테스트 계약으로 잠가두지 않으면, 중간에 레이아웃이 흔들려도 놓치기 쉽다.
  - 영향:
    - 이후 실내 UI 작업은 이 새 계약을 기준으로만 진행된다.

- 읽기 중심 실내 셸 재구성
  - 변경한 파일:
    - `game/scenes/indoor/indoor_mode.tscn`
    - `game/scripts/indoor/indoor_mode.gd`
    - `game/scripts/indoor/indoor_director.gd`
  - 무엇을 바꿨는지:
    - 기존 `MainColumn + Sidebar` 구조를 없애고 단일 컬럼 레이아웃으로 바꿨다.
    - 상단바에 `건물명 / 위치 / 시각 / 생존 수치 칩 / 구조도 / 가방`만 남겼다.
    - 본문은 `현재 구역 설명`과 `최근 결과`, `행동`만 남겼다.
    - 생존 수치는 `IndoorDirector.get_survival_chip_rows()`를 통해 실내 전용 상단바에서 직접 그리도록 바꿨다.
  - 왜 바꿨는지:
    - 실내는 대시보드가 아니라 "읽고 선택하는 화면"이어야 하기 때문이다.
  - 영향:
    - 구조도/가방이 메인 독해 흐름을 방해하지 않게 되었고, 실내 메인 화면이 훨씬 단순해졌다.

- 구조도 오버레이와 가방 시트 분리
  - 변경한 파일:
    - `game/scripts/indoor/indoor_mode.gd`
    - `game/scripts/indoor/indoor_minimap.gd`
  - 무엇을 바꿨는지:
    - 구조도는 버튼으로 여는 오버레이가 됐다.
    - 가방은 하단 시트가 되었고, `소지품`과 `장착중` 탭을 한곳에서 전환해 볼 수 있게 됐다.
    - `IndoorMinimap`은 크기 변경 시 다시 배치/리드로우하도록 보강했다.
  - 왜 바꿨는지:
    - 필요할 때만 정보를 여는 쪽이 실내 메인 흐름을 덜 망가뜨린다.
  - 영향:
    - 항상 보이는 우측 패널이 사라졌고, 모바일형 인터랙션에 더 가까워졌다.

- shared HUD 경계 정리
  - 변경한 파일:
    - `game/scripts/run/hud_presenter.gd`
    - `game/tests/smoke/test_first_playable_loop.gd`
  - 무엇을 바꿨는지:
    - shared HUD는 outdoor에서만 보이고, indoor에선 `visible = false`로 완전히 접힌다.
    - 스모크 테스트는 이제 실내 전용 상단바/오버레이 흐름을 기준으로 확인한다.
  - 왜 바꿨는지:
    - outdoor HUD가 실내 상단바와 경쟁하면 정보 계층이 다시 무너진다.
  - 영향:
    - 실내는 독립된 표현 모드가 되었고, outdoor HUD는 outdoor 전용 상태 패널로 정리됐다.

## 기대 효과

- 플레이어가 실내에서 "지금 어디에 있는지", "무슨 일이 벌어졌는지", "무엇을 할 수 있는지"를 더 빨리 읽을 수 있다.
- 구조도와 가방이 필요할 때만 열리므로 메인 독해 흐름이 끊기지 않는다.
- 향후 더 많은 생존 시스템과 스탯, 장비 요소가 들어와도 메인 화면이 덜 무너진다.

## 검증

- 실행한 명령:
  - `... --headless ... -s res://tests/unit/test_indoor_mode.gd`
  - `... --headless ... -s res://tests/unit/test_run_controller_live_transition.gd`
  - `... --headless ... -s res://tests/smoke/test_first_playable_loop.gd`
- 결과:
  - `INDOOR_MODE_OK`
  - `RUN_CONTROLLER_LIVE_TRANSITION_OK`
  - `FIRST_PLAYABLE_LOOP_OK`
- 수동 확인:
  - 사용자가 shared HUD가 다시 보이는지 직접 확인했고, 보인다고 피드백함
  - 그 수정은 이후 `run_shell` 렌더 순서/실내 HUD 분리 설계에도 반영됨

## 남은 리스크

- 실제 모바일 크기에서 버튼 높이와 글줄 길이는 추가 플레이테스트가 필요하다.
- 가방 시트와 아이템 시트가 동시에 열릴 때의 시각적 밀도는 추가 조정 여지가 있다.
- 새 실내 셸이 안정화되면 다음 단계로 실제 폰 UX 기준의 폰트/여백 조정이 필요하다.
