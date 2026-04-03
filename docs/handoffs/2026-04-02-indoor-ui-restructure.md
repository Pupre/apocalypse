# Indoor UI Restructure Handoff

## Session Snapshot

- Goal: 실내 UI를 읽기 중심 모바일형 레이아웃으로 재구성
- Current status: 실내 reading-first 셸, 구조도 오버레이, 가방 시트, 실내 shared HUD 비활성화까지 구현 완료
- Last updated: 2026-04-02
- Primary repos: `/home/muhyeon_shin/packages/apocalypse`
- Active branches: `playtest-mart-indoor-content`
- Last touched files:
  - `game/scenes/indoor/indoor_mode.tscn`
  - `game/scripts/indoor/indoor_mode.gd`
  - `game/scripts/indoor/indoor_director.gd`
  - `game/scripts/indoor/indoor_minimap.gd`
  - `game/scripts/run/hud_presenter.gd`
  - `game/tests/unit/test_indoor_mode.gd`
  - `game/tests/unit/test_run_controller_live_transition.gd`
  - `game/tests/smoke/test_first_playable_loop.gd`
  - `docs/worklogs/2026-04-02-indoor-ui-restructure.md`
  - `docs/handoffs/2026-04-02-indoor-ui-restructure.md`

## Next Actions

- [ ] 실제 플레이테스트 기준으로 실내 상단바 여백/글줄 길이/버튼 높이 튜닝
- [ ] 가방 시트와 아이템 시트 동시 노출 밀도 재조정
- [ ] 이후 외부 요소나 추가 생존 시스템 확장 전에 현재 실내 UI 피드백 수집

## Progress Checklist

- [x] Confirm starting context
- [x] Document current risks and planned edits
- [x] Implement first change set
- [x] Verify first change set
- [x] Implement remaining change set(s)
- [x] Verify final state
- [x] Refresh worklog summary

## Notes for Next Session

- 계획 기준 문서: `docs/superpowers/plans/2026-04-02-indoor-ui-restructure.md`
- 스펙 기준 문서: `docs/specs/indoor-ui-restructure-design.md`
- 실내는 이제 permanent sidebar가 없고, `TopBar + ReadingCard + ActionButtons + optional surfaces` 구조로 바뀌어 있음
- shared HUD는 indoor에서 숨기고 outdoor에서만 보임
- 이후 조정은 레이아웃 세부 튜닝 중심으로 보면 됨

## Verification Status

- Commands run:
  - `... --headless ... -s res://tests/unit/test_indoor_mode.gd`
  - `... --headless ... -s res://tests/unit/test_run_controller_live_transition.gd`
  - `... --headless ... -s res://tests/smoke/test_first_playable_loop.gd`
- Results:
  - `INDOOR_MODE_OK`
  - `RUN_CONTROLLER_LIVE_TRANSITION_OK`
  - `FIRST_PLAYABLE_LOOP_OK`
- Pending verification:
  - 실제 데스크톱/모바일 체감 플레이테스트
