## Session Snapshot

- Goal: 실내 마트 프로토타입의 정합성을 보정하고 파밍 흐름을 생존게임답게 수정
- Current status: 실내 파밍은 `탐색 -> 발견 -> 선택 획득`으로 전환 완료, `잠긴 길 노출 / 도구 행동 숨김`, `버리기 가능한 인벤토리`, `하단 아이템 패널`, `작은 배낭 장착`까지 반영 완료
- Last updated: 2026-04-01
- Primary repos: apocalypse
- Active branches: playtest-mart-indoor-content
- Last touched files:
  - `game/data/events/indoor/mart_01.json`
  - `game/scripts/indoor/indoor_action_resolver.gd`
  - `game/scripts/indoor/indoor_director.gd`
  - `game/scripts/indoor/indoor_minimap.gd`
  - `game/tests/unit/test_indoor_actions.gd`
  - `game/tests/unit/test_indoor_mode.gd`
  - `game/tests/smoke/test_first_playable_loop.gd`

## Next Actions

- [ ] 생활용품 코너와 식품 진열대 쪽 루팅 풀을 더 풍부하게 늘리기
- [ ] `잠긴 길은 노출, 아이템 요구 행동은 숨김` 규칙을 다른 실내 구역에도 일반화하기
- [ ] 소지 한도 초과 시 이동속도 저하 같은 소프트 제한을 외부 시스템과 연결할지 결정하기
- [ ] 장착 아이템 슬롯과 효과를 `배낭` 외 다른 장비로 확장할지 결정하기

## Progress Checklist

- [x] Confirm starting context
- [x] Document current risks and planned edits
- [x] Implement first change set
- [x] Verify first change set
- [x] Implement remaining change set(s)
- [x] Verify final state
- [x] Refresh worklog summary

## Notes for Next Session

- 현재 브랜치 `playtest-mart-indoor-content`
- `docs/plans/`는 원래부터 untracked 상태였으니 건드리지 말 것
- Godot headless 테스트는 기본 로그 경로에서 크래시가 날 수 있어 `XDG_DATA_HOME=/tmp/codex-godot-home`를 붙여서 실행하는 편이 안전
- 현재 규칙:
  - `2층으로 올라간다`, `보관실로 이동한다` 같은 공간 경로는 잠겨도 보여준다
  - `직원 출입문을 공구로 비집는다` 같은 도구 요구 행동은 아이템 없으면 숨긴다
  - 사이드바 소지품은 각 행에서 바로 `버린다`를 눌러 비울 수 있다
  - 이제 소지품 행을 누르면 하단 패널에서 `먹기/장착/버리기`를 고른다
- 다음 작업 시작 전 확인할 것:
  - `game/data/items.json`
  - `game/data/events/indoor/mart_01.json`
  - `game/scripts/indoor/indoor_action_resolver.gd`
  - `game/scripts/indoor/indoor_minimap.gd`
  - `game/scripts/indoor/indoor_director.gd`
  - `game/scripts/indoor/indoor_mode.gd`

## Verification Status

- Commands run:
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_minimap.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_director.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_zone_graph.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_actions.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_mode.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/smoke/test_first_playable_loop.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_survivor_creator.gd`
- Results:
  - 위 테스트 전부 통과
- Pending verification:
  - 실제 데스크톱 플레이로 하단 아이템 패널의 버튼 밀도와 아이템 설명 문구 체감 재확인
