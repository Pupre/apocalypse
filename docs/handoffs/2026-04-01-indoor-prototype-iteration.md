## Session Snapshot

- Goal: 실내 마트 프로토타입의 정합성을 보정하고 파밍 흐름을 생존게임답게 수정
- Current status: 실내 파밍은 `탐색 -> 발견 -> 선택 획득`으로 전환 완료, `잠긴 길 노출 / 도구 행동 숨김`, `하단 아이템 패널`, `생활용품 코너`, `작은 배낭/운동화/작업 장갑/작업 조끼`, `소프트 한도 초과 시 실외 이동속도 저하`, `인벤토리 상태 라벨`, `인벤토리 스크롤`, `장착 장비 목록`, `보관실 열쇠 경로 수정`까지 반영 완료
- Last updated: 2026-04-01
- Primary repos: apocalypse
- Active branches: playtest-mart-indoor-content
- Last touched files:
  - `game/data/items.json`
  - `game/data/events/indoor/mart_01.json`
  - `game/scripts/run/inventory_model.gd`
  - `game/scripts/run/run_state.gd`
  - `game/scripts/outdoor/outdoor_controller.gd`
  - `game/scripts/indoor/indoor_action_resolver.gd`
  - `game/scripts/indoor/indoor_director.gd`
  - `game/scripts/indoor/indoor_mode.gd`
  - `game/scenes/indoor/indoor_mode.tscn`
  - `game/tests/unit/test_indoor_actions.gd`
  - `game/tests/unit/test_indoor_director.gd`
  - `game/tests/unit/test_run_models.gd`
  - `game/tests/unit/test_outdoor_controller.gd`
  - `game/tests/unit/test_indoor_mode.gd`
  - `game/tests/smoke/test_first_playable_loop.gd`

## Next Actions

- [ ] 다른 건물 2~3개를 외부 맵에 추가해 실내 문법을 확장하기
- [ ] 소프트 한도 초과 시 이동속도 저하 수치를 실제 플레이 체감 기준으로 튜닝하기
- [ ] 장착 아이템 슬롯과 효과를 `배낭/신발/손/몸` 외 다른 장비로 확장할지 결정하기
- [ ] 외부 HUD에도 과적 상태를 보여줄지 결정하기

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
  - 이제 소지품 행을 누르면 하단 패널에서 `먹기/장착/버리기`를 고른다
  - 발견 루팅 액션 ID는 인덱스가 아니라 `loot_uid` 기반이라, 하나 집어도 다음 액션 ID가 안 흔들린다
  - `carry_limit`까진 정상 속도, 그 이후 `max_bulk()` 범위까진 추가 획득 가능하지만 실외 이동속도가 감소한다
  - 인벤토리 패널 `StatusLabel`은 `여유 있음 / 가방이 가득 찼다 / 과적: 실외 이동속도 XX%` 규칙으로 표시된다
  - 보관실 이동 판정도 UI와 동일하게 `run_state` 기준 잠금 해제를 보도록 맞췄다
  - 인벤토리 목록은 `InventoryScroll` 아래에 있고, 장착 상태는 `EquippedItems`로 따로 노출된다
  - 장비 교체 시 기존 장비는 가방으로 되돌아가며 결과 문구에 명시된다
- 다음 작업 시작 전 확인할 것:
  - `game/data/items.json`
  - `game/data/events/indoor/mart_01.json`
  - `game/scripts/run/inventory_model.gd`
  - `game/scripts/run/run_state.gd`
  - `game/scripts/outdoor/outdoor_controller.gd`
  - `game/scripts/indoor/indoor_action_resolver.gd`
  - `game/scripts/indoor/indoor_director.gd`
  - `game/scripts/indoor/indoor_mode.gd`
  - `game/scenes/indoor/indoor_mode.tscn`
  - `game/tests/unit/test_run_models.gd`
  - `game/tests/unit/test_outdoor_controller.gd`

## Verification Status

- Commands run:
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_content_library.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_run_models.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_outdoor_controller.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_minimap.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_director.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_zone_graph.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_actions.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_indoor_mode.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/smoke/test_first_playable_loop.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home ... -s res://tests/unit/test_survivor_creator.gd`
- Results:
  - 위 테스트 전부 통과
  - 2026-04-02 기준 위 세트 전체를 다시 fresh run으로 통과 확인
- Pending verification:
  - 실제 데스크톱 플레이로 생활용품 코너 루팅 밀도, 과적 상태 문구, 조끼/운동화/장갑 효과 체감 재확인
