# 실내 UI 가독성 보강 후속 작업 인계

## 세션 요약

- 목표: 실내 가방 UI에서 `소지품`과 `장착중`의 역할 차이를 더 즉시 읽히게 정리
- 현재 상태: 탭 세그먼트, 고정 이름이 있는 행 구조, 선택 상태 스타일, smoke 회귀까지 모두 반영되어 있고 검증도 통과한 상태다
- 마지막 갱신: 2026-04-02
- 저장소: `/home/muhyeon_shin/packages/apocalypse`
- 활성 브랜치: `playtest-mart-indoor-content`
- 이번 세션에 주로 손댄 파일:
  - `game/scenes/indoor/indoor_mode.tscn`
  - `game/scripts/indoor/indoor_mode.gd`
  - `game/tests/unit/test_indoor_mode.gd`
  - `game/tests/smoke/test_first_playable_loop.gd`
  - `docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md`
  - `docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md`

## 다음 작업

- 없음. 이번 후속 작업 범위는 종료되었고, 다음 세션에서는 다른 기능을 시작하면 된다.

## 진행 체크리스트

- [x] 시작 문맥 확인
- [x] 위험과 수정 방향 기록
- [x] 1차 변경 반영
- [x] 1차 변경 검증
- [x] 후속 변경 반영
- [x] 후속 상태 검증
- [x] worklog 요약 갱신

## 다음 세션 메모

- 기존 실내 재구성 문서는 별도로 유지한다.
- 이번 후속 작업은 구조를 다시 뒤엎기보다 가방 탭/행의 시각적 차이를 좁히는 작업이다.
- `ButtonGroup`으로 탭을 묶었고, `IndoorDirector.get_equipped_rows()`는 구조화된 summary payload를 돌려준다.
- UI 수정 후에는 `res://tests/unit/test_indoor_mode.gd`와 `res://tests/smoke/test_first_playable_loop.gd`를 반드시 다시 돌린다.
- 위 두 테스트와 `res://tests/unit/test_indoor_director.gd`는 이번 세션에서 재검증했고 모두 통과했다.

## 검증 상태

- 실행한 명령:
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd`
- 결과:
  - `INDOOR_MODE_OK`
  - `FIRST_PLAYABLE_LOOP_OK`
- `INDOOR_DIRECTOR_OK`
- 보류:
  - 없음
