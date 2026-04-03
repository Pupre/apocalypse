# 실내 UI 가독성 보강 후속 작업 인계

## 세션 요약

- 목표: 실내 UI를 `상시 미니맵 + 위치 스트립 + 닫을 수 있는 상태 상세 + 가방 우측 상세` 구조로 안정화
- 현재 상태: 구현과 회귀 검증까지 완료했다
- 마지막 갱신: 2026-04-03
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

- 실제 플레이테스트 기준으로 `장착중` 탭/카드 가독성을 다시 확인
- 필요하면 가방 시트 폭이나 장착 카드 높이를 한 번 더 늘리기
- 다음 큰 단계는 이 UI 안정화를 바탕으로 내부 시스템/스토리 확장 재개

## 진행 체크리스트

- [x] 새 피드백과 수정 방향 기록
- [x] 설계 문서 갱신
- [x] 구현 계획 작성
- [x] 새 UI 계약 테스트 추가
- [x] 씬 구조 재배치
- [x] `IndoorMode` / `IndoorDirector` 동작 반영
- [x] 회귀 검증 및 문서 마감
- [x] 상태칩 재탭 닫기
- [x] 소지품 `탭하여 상세 보기` 문구 제거
- [x] 장착 탭 최소 크기 확대
- [x] 장착 행 카드형 문구 정리

## 다음 세션 메모

- 상시 미니맵은 다시 메인 화면에 둔다. 다만 `전체 구조도` 오버레이는 유지한다.
- 아이템 상세는 더 이상 메인 화면 위에 뜨는 별도 패널이 아니라, 가방 내부 우측 컬럼으로 옮긴다.
- 상태칩 상세는 `닫기` 버튼이 필요하다.
- 정확한 생존 수치는 정수형만 보여준다.
- 현재 위치는 상단 바 바로 아래의 전용 위치 스트립으로 분리한다.
- 구현 시작 전 기준 문서:
  - `docs/specs/indoor-ui-clarity-follow-up-design.md`
  - `docs/superpowers/plans/2026-04-03-indoor-ui-clarity-refinement.md`
- 최근 후속 수정:
  - 같은 상태칩을 다시 누르면 상세 패널이 닫힌다.
  - 소지품 행은 버튼 라벨만 남기고, 반복 문구는 제거했다.
  - 장착중 행은 `슬롯명 / 장비명 / 효과` 구조로 바뀌었다.

## 현재 구현 요약

- `game/scenes/indoor/indoor_mode.tscn`
  - `LocationStrip` 추가
  - `BagSheet`를 `왼쪽 목록 / 오른쪽 상세` 구조로 변경
  - `StatDetailSheet`에 `닫기` 버튼 추가
- `game/scripts/indoor/indoor_mode.gd`
  - 위치 스트립 갱신
  - 가방 우측 상세 패널 렌더링
  - 상태 상세 닫기 버튼 바인딩
  - 같은 상태칩 재탭 시 상세 닫기
  - 장착 카드형 렌더링
- `game/scripts/indoor/indoor_director.gd`
  - 생존 수치 상세값 정수화
  - 소지품 행 반복 문구 제거
  - 장착 행 문구를 슬롯 중심 카드 문구로 정리
- `game/tests/unit/test_indoor_mode.gd`
  - 위치 스트립, 정수 수치, 상태 상세 토글 닫기, 가방 우측 상세, 장착 카드 검증
- `game/tests/smoke/test_first_playable_loop.gd`
  - 새 위치 스트립, 가방 경로, 장착 카드 문구를 반영한 smoke 회귀

## 검증 상태

- 최근 안정화 기준 검증:
  - `INDOOR_MODE_OK`
  - `FIRST_PLAYABLE_LOOP_OK`
  - `INDOOR_DIRECTOR_OK`
- 이번 라운드 최종 검증 명령:
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd`
  - `XDG_DATA_HOME=/tmp/codex-godot-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd`
- 결과:
  - `INDOOR_MODE_OK`
  - `FIRST_PLAYABLE_LOOP_OK`
- 보류:
  - 없음
