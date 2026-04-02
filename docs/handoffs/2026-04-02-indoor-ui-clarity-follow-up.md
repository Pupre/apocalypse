# Indoor UI Clarity Follow-up Handoff

## Session Snapshot

- Goal: 실내 가방 UI에서 `소지품`과 `장착중`의 역할 차이를 즉시 읽히게 정리
- Current status: 탭 세그먼트와 row 표현 분리를 반영하는 1차 구현 완료, 검증 전
- Last updated: 2026-04-02
- Primary repos: `/home/muhyeon_shin/packages/apocalypse`
- Active branches: `playtest-mart-indoor-content`
- Last touched files:
  - `docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md`
  - `docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md`

## Next Actions

- [x] `test_indoor_mode.gd`와 `test_indoor_director.gd`를 새 표현에 맞게 최종 확인
- [x] `test_first_playable_loop.gd`를 돌려 전 플레이 루프 회귀가 없는지 확인
- [ ] 테스트 결과와 함께 worklog/handoff를 마무리한다

## Progress Checklist

- [x] Confirm starting context
- [x] Document current risks and planned edits
- [x] Implement first change set
- [x] Verify first change set
- [x] Implement remaining change set(s)
- [x] Verify final state
- [x] Refresh worklog summary

## Notes for Next Session

- 기존 실내 재구성 문서는 별도로 유지한다.
- 이번 follow-up은 구조를 다시 뒤엎기보다 가방 탭/행의 시각적 차이를 좁히는 작업이다.
- `ButtonGroup`으로 탭을 묶었고, `IndoorDirector.get_equipped_rows()`는 구조화된 summary payload를 돌려준다.
- UI 수정 후에는 `res://tests/unit/test_indoor_mode.gd`와 `res://tests/smoke/test_first_playable_loop.gd`를 반드시 다시 돌린다.

## Verification Status

- Commands run:
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd`
- Results:
  - `INDOOR_MODE_OK`
  - `FIRST_PLAYABLE_LOOP_OK`
- Pending verification:
  - 없음
