# Cleanup Pass 1 Design

- Status: draft
- Created: 2026-04-10
- Last updated: 2026-04-10
- Scope: 런타임에 영향을 주지 않으면서 현재 작업 기준선을 오염시키는 생성물과 legacy UI 경로를 제거하는 1차 cleanup
- Depends on:
  - `AGENTS.md`
  - `docs/CURRENT_STATE.md`
  - `docs/superpowers/specs/2026-04-07-indoor-portrait-survival-sheet-design.md`
  - `docs/superpowers/specs/2026-04-09-contextual-crafting-ui-design.md`

## 목적

이 문서는 지금 프로젝트 안에 남아 있는 두 종류의 잡음을 줄이기 위한 설계다.

- 이미 새 흐름으로 대체됐는데 코드와 씬에 남아 있는 legacy 경로
- 빌드/에디터/로컬 실행이 만든 생성물과 캐시

이 둘은 모두 다음 작업에 악영향을 준다.

- 읽어야 할 코드 양이 불필요하게 늘어난다.
- 에이전트와 사람이 모두 낡은 패턴을 따라 새 코드를 쓰기 쉬워진다.
- `git status`가 기준선 역할을 못 하게 된다.

이번 pass의 목적은 “코드베이스를 더 영리하게 보이게 만드는 것”이 아니라, 지금 실제로 쓰는 경로만 남겨 다음 작업의 기준선을 깨끗하게 만드는 것이다.

## 목표

- 실내에서 `SurvivalSheet`로 대체된 `BagSheet` legacy 경로를 제거한다.
- `.godot`, Android build 출력물, `.uid`, export 산출물 같은 생성물을 정리한다.
- 생성물이 다시 작업트리를 오염시키지 않도록 `.gitignore`를 보강한다.
- 아직 실제로 쓰는 실외 조합/도감 경로는 유지한다.

## 비목표

이번 pass는 아래를 하지 않는다.

- 실외 `CraftingSheet` / `CodexPanel` 제거
- 대형 untracked 아트팩 전체 삭제
- UI 리디자인
- 기능 추가

즉 이번 작업은 `cleanup pass 1`이며, 현재 살아 있는 기능을 바꾸는 작업이 아니다.

## 정리 원칙

### 1. 현재 런타임이 실제로 쓰는 경로만 남긴다

실내 인벤토리/조합 흐름은 이제 `SurvivalSheet`가 기준이다.

따라서 아래는 제거 대상이다.

- `indoor_mode.tscn` 안의 `BagSheet` 노드 트리
- `indoor_mode.gd` 안의 `_bag_*`, `_refresh_bag_sheet`, `_refresh_item_sheet`, bag tab 핸들러 등 `BagSheet` 전용 코드

반대로 아래는 유지 대상이다.

- `SurvivalSheet`
- 실외 런타임이 아직 직접 쓰는 `CraftingSheet`
- 실외 런타임이 아직 직접 쓰는 `CodexPanel`

### 2. 생성물은 코드처럼 취급하지 않는다

다음 항목은 코드베이스의 일부가 아니라 생성물로 본다.

- `game/.godot/`
- `game/android/build/` 하위 빌드 출력물
- `game/builds/`
- `*.uid`
- import/캐시/로컬 상태 파일

이들은 작업 산출물은 될 수 있어도, 기본적으로 버전 관리 기준선의 일부가 아니다.

### 3. cleanup은 관련 범위 안에서만 한다

이번 pass는 실내 legacy UI와 생성물 정리에 집중한다.

참조 여부가 아직 불분명한 대형 untracked 자산은 이번 pass에서 건드리지 않는다. 그런 자산은 별도 스캔과 근거를 가진 cleanup 2차로 넘긴다.

## 구체적 대상

### A. 실내 legacy UI 제거

대상 파일:

- `game/scenes/indoor/indoor_mode.tscn`
- `game/scripts/indoor/indoor_mode.gd`
- 관련 테스트

예상 결과:

- 실내는 `SurvivalSheet`만 사용한다.
- `BagSheet` 경로를 찾는 코드가 사라진다.
- 실내 테스트는 새 흐름만 검증한다.

### B. ignore 규칙 보강

대상 파일:

- `.gitignore`

추가 대상 패턴:

- Godot cache / import / uid
- Android build 출력물
- export builds
- local tool state

예상 결과:

- 생성물 때문에 `git status`가 항상 시끄러운 상태를 줄인다.

### C. 현재 workspace 생성물 정리

정리 대상 예시:

- `game/.godot/`
- `game/android/build/` 내부 빌드 산출물
- `game/builds/`
- `*.uid`

주의:

- 추적 중인 실제 소스 파일은 건드리지 않는다.
- 참조 여부가 불명확한 대형 자산은 이번 pass에서 삭제하지 않는다.

## 검증 기준

cleanup pass 1은 아래가 모두 맞아야 완료로 본다.

- 실내 씬과 스크립트에서 `BagSheet` legacy 경로가 제거된다.
- 실내 관련 테스트가 새 구조 기준으로 통과한다.
- `.gitignore`가 생성물을 다시 숨길 수 있게 보강된다.
- cleanup 대상 생성물이 실제로 정리된다.
- 실외 조합/도감 흐름은 그대로 살아 있다.

## 위험과 대응

### 위험 1. 아직 살아 있는 경로를 legacy로 오판할 수 있다

대응:

- 제거 전 `rg`로 실제 참조를 확인한다.
- 실외에서 직접 쓰는 `CraftingSheet` / `CodexPanel`은 유지한다.

### 위험 2. generated와 source를 혼동할 수 있다

대응:

- 삭제 전 경로를 분류한다.
- pass 1에서는 cache/build/output 성격이 명확한 것만 정리한다.

### 위험 3. 테스트가 오래된 경로를 기대할 수 있다

대응:

- cleanup과 함께 관련 테스트 기대치도 같이 정리한다.

## 완료 정의

이 pass가 끝나면 다음이 성립해야 한다.

- 실내 inventory/crafting 기준 코드는 `SurvivalSheet` 하나로 읽힌다.
- legacy `BagSheet` 흔적 때문에 새 구현 패턴이 오염되지 않는다.
- 생성물 때문에 작업트리 기준선이 흐려지지 않는다.
