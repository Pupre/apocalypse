# 실내 UI 가독성 보강 작업 기록

- 날짜: 2026-04-02
- 작업: 실내 UI clarity follow-up
- 범위: 가방 탭 세그먼트화, 소지품/장착중 행 표현 분리, 후속 테스트 및 문서 정리
- 저장소: `/home/muhyeon_shin/packages/apocalypse`
- 활성 브랜치: `playtest-mart-indoor-content`

## 작업 배경

실내 UI 1차 재구성 이후에도 사용자가 가방을 열었을 때 `소지품`과 `장착중`의 역할 차이를 즉시 읽기 어렵다는 피드백이 남아 있었다. 특히 탭은 동작은 되지만 시각적으로는 단순한 토글 버튼처럼 보였고, 행도 같은 밀도로 렌더되어 현재 소지품과 현재 장착 상태가 한눈에 구분되지 않았다.

## 변경 전 상태

가방 시트는 이미 `소지품`/`장착중` 탭으로 분리되어 있었지만, 선택 상태가 비활성 버튼처럼 보이는 부분이 있었고, 각 탭의 행도 텍스트만으로 비슷하게 보였다. 소지품 행은 상호작용 대상이지만 그 사실이 충분히 드러나지 않았고, 장착중 행은 현재 상태 요약이라기보다 단순한 목록 항목처럼 읽혔다.

## 문제점 또는 리스크

- 탭이 명시적 세그먼트 컨트롤처럼 보이지 않으면 두 보기의 성격 차이가 약해진다.
- 소지품은 눌러야 하는 항목인데, 장착중은 현재 상태를 읽는 항목이라는 차이가 화면에서 충분히 드러나지 않았다.
- 같은 밀도의 행 렌더링은 실내 UI의 핵심 목표였던 "즉시 읽힘"을 약화시킨다.

## 변경 전략

가방 탭은 상호 배타적인 세그먼트 컨트롤로 정리하고, 행은 역할에 따라 아예 다른 표정으로 렌더한다. 소지품은 명확한 상호작용 행으로, 장착중은 현재 상태를 요약하는 읽기 전용 카드로 보이게 만든다. 기능을 다시 설계하기보다는, 이미 있는 데이터 흐름을 유지하면서 시각적·문구적 단서를 추가하는 방향을 택한다.

## 구현 메모

- 시작 상태
  - 계획 기준: `docs/plans/2026-04-02-indoor-ui-restructure.md`
  - 기존 기록:
    - `docs/worklogs/2026-04-02-indoor-ui-restructure.md`
    - `docs/handoffs/2026-04-02-indoor-ui-restructure.md`
  - 이번 작업 대상:
    - `game/scenes/indoor/indoor_mode.tscn`
    - `game/scripts/indoor/indoor_mode.gd`
    - `game/scripts/indoor/indoor_director.gd`
    - `game/tests/unit/test_indoor_mode.gd`
    - `game/tests/smoke/test_first_playable_loop.gd`

- 기대되는 수정 방향
  - 가방 탭을 세그먼트 컨트롤처럼 보이도록 정리
  - 소지품 행은 누를 수 있는 inventory row로 유지하되 더 명확한 인터랙션 단서 추가
  - 장착중 행은 current-state summary처럼 읽히는 텍스트/레이아웃으로 분리
  - 테스트는 새 표현을 고정하되, 행동 계약은 흔들지 않기

- 1차 구현 반영
  - 변경한 파일:
    - `game/scenes/indoor/indoor_mode.tscn`
    - `game/scripts/indoor/indoor_mode.gd`
    - `game/scripts/indoor/indoor_director.gd`
    - `game/tests/unit/test_indoor_director.gd`
    - `game/tests/unit/test_indoor_mode.gd`
  - 무엇을 바꿨는지:
    - 가방 탭에 `ButtonGroup`을 붙여 상호 배타적인 세그먼트처럼 동작하게 했다.
    - 소지품 행은 버튼 + 힌트 라벨이 있는 상호작용 카드로, 장착중 행은 summary/state/detail을 보여주는 읽기 전용 카드로 렌더하도록 분리했다.
    - `IndoorDirector`의 장착 행 데이터는 문자열 목록 대신 구조화된 payload로 바꿔, 현재 상태 요약을 더 명확한 문구로 표현하게 했다.
    - 단위 테스트는 세그먼트 동작과 장착 행의 summary 텍스트를 검증하도록 바꿨다.
  - 왜 바꿨는지:
    - 사용자가 `소지품`은 눌러야 하는 목록, `장착중`은 현재 상태 요약이라는 차이를 즉시 읽을 수 있어야 하기 때문이다.
- 영향:
  - 탭 선택 상태가 더 명시적으로 보이고, 장착 중인 장비는 목록 항목이 아니라 현재 상태 카드로 읽힌다.

## 후속 수정 배경

첫 1차 구현 뒤에 다시 읽어보니, 탭과 행이 동작은 맞아도 여전히 Godot 기본 테마에 많이 기대고 있었다. 그 결과 소지품/장착중의 차이는 기능상 존재하지만, 테스트 코드와 UI 코드가 모두 같은 텍스트 흐름에 의존하는 부분이 남았다. 이번 후속 수정에서는 이 의존을 줄이고, 행과 탭의 구조를 더 명시적으로 만들어 다음 세션에서 유지보수하기 쉽게 만드는 방향으로 바꾼다.

## 기대 효과

- 사용자가 `소지품`과 `장착중`을 탭 제목만이 아니라 행의 톤에서도 즉시 구분할 수 있다.
- 가방 시트가 목록형 UI가 아니라 상태를 읽고 행동하는 화면처럼 보인다.
- 이후 아이템/장비가 늘어나도 역할 분리가 유지된다.

## 검증

- 실행한 명령:
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd`
- `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_director.gd`
- 결과:
  - `INDOOR_MODE_OK`
  - `FIRST_PLAYABLE_LOOP_OK`
  - `INDOOR_DIRECTOR_OK`
- 메모:
  - smoke 테스트는 실내 라벨/버튼 경로를 현재 셸 구조(`HeaderRow`, `ContextRow`, `StatusRow`)에 맞게 갱신한 뒤 통과했다.

## 최종 결과

이 후속 수정은 `소지품`과 `장착중`의 역할을 더 즉시 읽히게 만드는 데 초점을 맞췄고, 지금은 탭 구조, 명시적인 상태 행, 안정적인 행 이름, smoke 회귀까지 모두 정리된 상태다. 다음에 같은 화면을 손댈 때는 텍스트 기반을 더 보강하기보다, 새 아이콘이나 카드 간격 같은 표현만 추가하면 된다.

## 남은 리스크

- Godot 기본 테마만으로 세그먼트/카드 차이를 충분히 줄 수 있는지 최종 확인이 필요하다.
- 행을 더 두드러지게 만들수록 가방 시트 높이와 줄바꿈이 늘어날 수 있다.
