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

## 2026-04-03 후속 작업 재개

사용자 플레이테스트 기준으로, 4월 2일 후속 수정만으로는 실내 UI가 아직 충분히 빠르게 읽히지 않았다. 특히 다음 문제가 남아 있었다.

- 작은 미니맵이 상시로 보이지 않아 매번 `구조도`를 눌러야 했다.
- 상태칩 상세는 열리지만 닫기 버튼이 없었다.
- 가방에서 아이템 상세가 별도 겹침 패널로 떠서 본문과 충돌했다.
- `장착중` 탭과 장착 행은 여전히 집중해서 읽어야 차이가 보였다.
- 정확한 생존 수치가 소수점까지 보여서 필요 이상으로 시선을 잡아먹었다.
- 위치 텍스트가 행동 영역과 같은 밀도로 보여 현재 위치를 빠르게 읽기 어려웠다.

이번 라운드의 목적은 기능을 더 넣는 것이 아니라, 이미 있는 실내 루프를 `읽기 쉽고, 닫기 쉽고, 비교하기 쉬운` UI로 안정화하는 것이다.

## 이번 라운드 변경 방향

- 상시 미니맵을 다시 메인 화면에 둔다.
  - 단, 전체 구조를 다 보여주는 것이 아니라 현재 위치 중심의 작은 미니맵만 상시 유지한다.
  - 전체 구조 확인은 기존 `구조도` 오버레이로 분리한다.
- 상태칩 상세에는 명시적인 `닫기` 버튼을 넣는다.
- 가방은 `왼쪽 목록 / 오른쪽 상세` 구조로 바꿔, 아이템 상세가 메인 화면을 덮지 않게 한다.
- `장착중`은 버튼 리스트보다 상태 카드처럼 보이게 만든다.
- 생존 수치 정확값은 정수형만 보여준다.
- 현재 위치는 상단 아래 별도 위치 스트립으로 분리한다.

## 기대 효과

- 플레이어가 행동을 고르기 전에 현재 위치와 상태를 더 짧은 시선 이동으로 파악할 수 있다.
- 가방에서 `소지품`, `장착중`, `선택한 아이템 상세`를 한 번에 비교할 수 있다.
- 작은 미니맵은 계속 보이지만, 전체 구조를 너무 빨리 누설하지는 않는다.

## 이번 라운드 구현 결과

- `위치 스트립`을 상단 아래 별도 줄로 추가했다.
  - 기존 상단 위치 라벨은 숨기고, 실제 위치 표시는 `정문 진입부`, `계산대`처럼 순수 구역명만 보여주게 바꿨다.
- `상시 미니맵`은 메인 화면 우측 카드에 유지하고, 전체 구조도는 기존 오버레이 버튼으로 분리했다.
- `상태칩 상세`는 `닫기` 버튼을 가진 별도 패널로 정리했고, 정확한 수치는 소수점 없이 정수형으로만 보이게 했다.
- `가방`은 `왼쪽 목록 / 오른쪽 상세` 구조로 바꿨다.
  - 기존처럼 메인 화면 위에 따로 뜨는 `ItemSheet`는 제거하고, 가방 내부 우측 패널에서 상세를 읽게 만들었다.
- `장착중`은 기존과 같은 데이터 계약을 유지하되, 슬롯 중심 카드 문구(`등 · 작은 배낭`)로 정리했다.

## 왜 이 방식이 더 나은가

- 위치, 상태, 행동, 가방 상세가 서로 다른 레이어로 분리되어 더 이상 한 화면에서 같은 밀도로 충돌하지 않는다.
- 작은 미니맵은 계속 보이므로 동선 판단이 끊기지 않고, 전체 구조 파악은 여전히 별도 오버레이에서 할 수 있다.
- 아이템 상세가 가방 내부 우측에 붙으면서, 선택한 아이템과 상세 설명을 같은 시선 흐름으로 읽을 수 있게 됐다.

## 현재 남은 리스크

- 상시 미니맵을 메인 화면에 다시 넣으면 본문 폭이 너무 줄어들 수 있다.
- 가방 우측 상세 패널이 모바일 폭에서 너무 비좁게 느껴질 수 있다.
- 위치 스트립과 상태칩이 둘 다 상단에 들어오므로, 실제 체감상 어느 쪽이 더 눈에 잘 들어오는지 플레이테스트가 필요하다.

## 검증

- 실행한 명령:
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd`
- 결과:
  - `INDOOR_MODE_OK`
  - `FIRST_PLAYABLE_LOOP_OK`
