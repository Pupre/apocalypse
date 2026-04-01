# 실내 프로토타입 반복 작업 로그

- 날짜: 2026-04-01
- 작업: 실내 탐색 프로토타입 정합성 보정
- 범위: 마트 실내 탐색, 미니맵, 파밍 흐름, 텍스트/선택지 문구
- 저장소: apocalypse
- 활성 브랜치: playtest-mart-indoor-content

## 작업 배경

사용자 플레이테스트 과정에서 실내 프로토타입의 표현과 규칙이 어긋나는 지점이 연속적으로 드러났다. 대표적으로 잠긴 길이 숨겨져 구조가 이해되지 않는 문제, 용어가 일관되지 않는 문제, 탐색만으로 아이템이 자동 획득되어 생존 파밍 감각이 약한 문제, 특정 아이템이 없어도 강행 진입 선택지가 보이는 문제 등이 있었다.

## 변경 전 상태

실내 프로토타입은 구역 이동과 간단한 이벤트 소비까지는 구현되어 있었지만, 탐색 결과가 곧바로 인벤토리로 들어가는 구조였다. 또한 미니맵은 보이는 노드 간 연결선을 지나치게 많이 공개했고, 이동/탐색/강행 진입 문구는 실제 구역명과 완전히 맞물리지 않는 부분이 있었다.

## 문제점 또는 리스크

- 플레이어가 아직 지나가지 않은 연결관계까지 미니맵으로 추론할 수 있었다.
- 같은 장소를 가리키는 단어가 다르게 표기되어 공간 감각이 흔들렸다.
- 사무실 설명과 실제 보상, 보관실 잠금 해제 조건이 어긋나 서사적 설득력이 떨어졌다.
- 탐색 즉시 루팅 구조 때문에 마트가 아닌 추리형 이벤트 카드처럼 느껴질 위험이 있었다.

## 변경 전략

핵심 전략은 `공간 정보`, `탐색 결과`, `선택 획득`을 분리하는 것이다. 이동은 이동대로 시간을 쓰고, 탐색은 탐색대로 시간을 쓰며, 탐색 결과는 발견만 한 뒤 플레이어가 필요한 것만 줍게 만드는 방향으로 정리한다. 동시에 용어와 진행 조건을 실제 화면 문구와 테스트까지 함께 맞춰 정합성을 유지한다.

## 구현 메모

- 변경한 파일
  - `game/scripts/indoor/indoor_action_resolver.gd`
  - `game/scripts/indoor/indoor_director.gd`
  - `game/scripts/indoor/indoor_minimap.gd`
  - `game/data/events/indoor/mart_01.json`
  - 관련 실내/스모크 테스트
  - 무엇을 바꿨는지
    - 잠긴 이동 경로는 보이되 클릭 시 막히도록 유지했다.
    - 미니맵은 실제로 지나간 길과 현재 위치에서 직접 뻗는 길만 보여주도록 바꿨다.
    - 탐색은 `discover_loot`를 통해 아이템을 발견만 하고, `take_*` 액션으로 개별 획득하게 만들었다.
    - 보관실 열쇠는 실제 아이템으로 발견/획득하게 바꿨고, 보관실 잠금 해제는 인벤토리 소지 여부를 기준으로 바꿨다.
  - 왜 바꿨는지
    - 플레이어가 공간을 직접 이해하고, 필요한 자원을 스스로 선택하는 생존게임 감각을 만들기 위해서다.
  - 영향
    - 실내 한 턴의 의미가 `이동`, `탐색`, `선택`으로 분리되어 판단거리가 늘었다.

- 변경한 파일
  - `game/data/events/indoor/mart_01.json`
  - `game/tests/unit/test_indoor_actions.gd`
  - `game/tests/unit/test_indoor_zone_graph.gd`
  - 무엇을 바꿨는지
    - `직원 출입문을 공구로 비집는다`는 실제로 드라이버를 가진 뒤에만 보이도록 바꿨다.
    - 대신 `2층으로 올라간다`, `보관실로 이동한다` 같은 공간 경로는 잠겨 있어도 계속 보이게 유지했다.
  - 왜 바꿨는지
    - 공간 구조는 플레이어가 알아야 판단할 수 있지만, 아이템이 없으면 시도조차 할 수 없는 행동까지 미리 노출하면 오히려 읽기만 복잡해지기 때문이다.
  - 영향
    - `잠긴 길은 보이되, 도구 요구 행동은 숨김`이라는 실내 선택지 규칙이 생겼다.

- 변경한 파일
  - `game/scripts/run/inventory_model.gd`
  - `game/scripts/indoor/indoor_director.gd`
  - `game/scripts/indoor/indoor_mode.gd`
  - `game/data/events/indoor/mart_01.json`
  - `game/tests/unit/test_run_models.gd`
  - `game/tests/unit/test_indoor_mode.gd`
  - `game/tests/smoke/test_first_playable_loop.gd`
  - `game/tests/unit/test_survivor_creator.gd`
  - 무엇을 바꿨는지
    - 인벤토리에서 아이템을 하나씩 버릴 수 있게 했다.
    - 사이드바 제목에 현재 소지량을 `현재/최대` 형태로 보이게 했다.
    - 소지품 목록은 단순 텍스트가 아니라 `아이템명 + 버린다 버튼` 행으로 바꿨다.
    - 식품 진열대, 매장 뒤편, 휴게실, 창고 등 구역별 루팅 풀을 더 마트답게 늘렸다.
    - 스모크/플로우 테스트에서 `행동 개수`를 정확히 고정해 검증하던 부분은 제거했다.
  - 왜 바꿨는지
    - 생존게임에서는 줍는 선택만큼 버리는 선택도 중요하고, 루팅 풀이 늘어날수록 테스트를 `액션 수`에 묶어두면 확장 때마다 쓸데없이 깨지기 때문이다.
  - 영향
    - 플레이어는 필요한 물건만 챙기고, 공간이 모자라면 곧바로 버리면서 루팅 우선순위를 조정할 수 있다.

- 변경한 파일
  - `game/data/items.json`
  - `game/scripts/autoload/content_library.gd`
  - `game/scripts/run/run_state.gd`
  - `game/scripts/indoor/indoor_director.gd`
  - `game/scripts/indoor/indoor_mode.gd`
  - `game/scenes/indoor/indoor_mode.tscn`
  - 관련 테스트 전반
  - 무엇을 바꿨는지
    - 아이템 공통 메타데이터 파일을 추가해 설명, 포만감 회복량, 장착 슬롯, 소지 한도 보너스를 중앙에서 정의했다.
    - 소지품 목록은 `버린다` 고정 버튼 대신 아이템 버튼으로 바꾸고, 탭하면 하단 패널이 열리도록 했다.
    - 하단 패널에서 아이템 설명, 효과, `먹는다`, `장착한다`, `버린다`, `닫기` 액션을 보여주게 했다.
    - `작은 배낭`을 넣고 장착 시 소지 한도가 늘어나게 했다.
  - 왜 바꿨는지
    - 모바일 게임 기준으로는 좁은 사이드바에 즉시 버튼을 나열하는 것보다, 아이템을 고른 뒤 하단 패널에서 결정하게 하는 쪽이 훨씬 자연스럽기 때문이다.
  - 영향
    - 인벤토리 UI가 모바일 친화적인 형태로 한 단계 이동했고, 아이템마다 서로 다른 상호작용을 붙일 기반이 생겼다.

- 변경한 파일
  - `game/data/events/indoor/mart_01.json`
  - 무엇을 바꿨는지
    - `음료/후면 통로`를 `매장 뒤편`으로, `직원 통로 입구`를 `직원 출입문`으로 바꾸는 등 용어를 통일했다.
    - `식품 코너를 탐색한다`처럼 라벨과 구역명이 어긋나는 문구를 정리했다.
    - `직원 출입문을 공구로 비집는다`처럼 대상이 분명한 문구로 바꿨다.
  - 왜 바꿨는지
    - 플레이어가 텍스트만 읽고도 현재 위치와 행동 대상을 즉시 이해할 수 있어야 하기 때문이다.
  - 영향
    - 읽기 피로가 줄고, 선택지 해석 오류 가능성이 낮아진다.

## 기대 효과

- 마트가 단순 이벤트 카드 묶음이 아니라 실제 파밍 장소처럼 느껴진다.
- 실내 확장 시 `탐색 -> 발견 -> 선택 획득` 문법을 다른 건물에도 그대로 복제할 수 있다.
- 용어/진행 조건/테스트가 함께 묶여 있어 이후 리팩터링 시 회귀 가능성이 줄어든다.
- 다음 건물 확장 때도 `공간 정보`, `행동 조건`, `획득 로직`을 분리해서 보게 되어 같은 표현 오류를 줄일 수 있다.
- 인벤토리 관리가 `줍기만 하는 구조`에서 벗어나 실제 선택 문제로 바뀐다.
- 아이템별 설명과 효과를 한 곳에서 관리하게 되어 이후 다른 건물/스토리 확장 때 재사용이 쉬워진다.

## 검증

- 실행 명령
  - `XDG_DATA_HOME=/tmp/codex-godot-home Godot --headless --path ... -s res://tests/unit/test_indoor_minimap.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home Godot --headless --path ... -s res://tests/unit/test_indoor_director.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home Godot --headless --path ... -s res://tests/unit/test_indoor_zone_graph.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home Godot --headless --path ... -s res://tests/unit/test_indoor_actions.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home Godot --headless --path ... -s res://tests/unit/test_indoor_mode.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home Godot --headless --path ... -s res://tests/smoke/test_first_playable_loop.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home Godot --headless --path ... -s res://tests/unit/test_survivor_creator.gd`
- 결과
  - 위 테스트 모두 통과했다.

## 남은 리스크

- 아직 `가방 초과 시 이동속도 저하` 같은 소프트 제한은 없다.
- 모바일 기준 UI 밀도는 아직 높아서, 추후 하단 패널/탭 구조로 다시 다듬어야 한다.
- `잠긴 길은 보이고 도구 행동은 숨긴다`는 원칙은 잡혔지만, 앞으로 열쇠/도구 종류가 늘면 UI 규칙을 더 일반화해야 한다.
- 장착 아이템은 현재 `작은 배낭` 한 종류만 실효성이 있고, 다른 장비 슬롯 효과는 아직 비어 있다.
