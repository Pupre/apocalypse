# Context Routing Docs Design

- Status: draft
- Created: 2026-04-10
- Last updated: 2026-04-10
- Scope: `AGENTS.md`를 짧은 라우터로 두고 기존 `docs/` 구조 위에 문서 맵과 현재 상태 문서를 덧씌우는 설계
- Depends on:
  - `docs/README.md`
  - `docs/specs/core-gameplay-design.md`
  - `docs/superpowers/specs/2026-04-07-portrait-phase1-shell-design.md`
  - `docs/superpowers/specs/2026-04-09-contextual-crafting-ui-design.md`

## 목적

이 문서는 이 리포지터리의 장기 기억 구조를 정리하기 위한 설계다.

핵심 문제는 단순하다.

- 대화 컨텍스트는 사라진다.
- 코드만으로는 의도와 우선순위가 남지 않는다.
- 모든 문서를 매번 읽을 수는 없다.

따라서 이 리포지터리는 `모든 것을 담은 하나의 거대한 지침 파일`이 아니라, `짧은 진입점 + 역할이 분리된 문서 묶음`으로 기억을 유지해야 한다.

## 목표

이번 설계의 목표는 아래 네 가지다.

- `AGENTS.md`를 짧은 라우터로 만든다.
- 기존 `docs/` 폴더 구조를 유지하면서도, 무엇이 현재 기준 문서인지 빠르게 찾을 수 있게 만든다.
- “장기 배경 문서”, “현재 활성 설계”, “현재 구현 상태”, “이력성 문서”를 구분한다.
- 새 문서가 추가될 때 어디에 두고 어떤 색인만 갱신하면 되는지 명확히 한다.

## 비목표

이번 설계는 아래를 의도적으로 하지 않는다.

- 기존 `docs/specs`, `docs/superpowers/specs`, `docs/handoffs`, `docs/worklogs`의 폴더 이동
- 기존 문서의 대규모 리라이트
- 이 리포지터리 전체 문서 체계의 물리적 통합

즉 이번 작업은 `재배치`가 아니라 `덧씌우는 라우팅층 추가`다.

## 핵심 원칙

### 1. `AGENTS.md`는 백과사전이 아니라 목차다

`AGENTS.md`는 짧아야 한다.

- 길이는 대략 80-120줄을 목표로 한다.
- 이 파일에 장문의 설계 배경을 직접 넣지 않는다.
- 에이전트가 처음 읽고 “어디를 더 읽어야 하는지”를 판단하는 지도 역할만 맡긴다.

### 2. 진짜 지식은 `docs/`에 남긴다

지속적인 지식은 모두 `docs/` 쪽에 남긴다.

- 제품/UX 원칙
- 현재 활성 설계
- 현재 구현 상태
- 작업 이력
- 설정 참고 문서

즉 `AGENTS.md`는 메모리가 아니라 인덱서다.

### 3. 문서는 역할별로 해석 우선순위가 있어야 한다

같은 주제를 다루는 문서가 여러 개 있더라도, 어떤 문서를 현재 기준으로 읽어야 하는지 우선순위를 문서 시스템이 직접 선언해야 한다.

이번 설계의 우선순위는 아래와 같다.

1. `docs/superpowers/specs/`
   - 현재 활성 기능 설계
2. `docs/superpowers/plans/`
   - 현재 활성 구현 계획
3. `docs/CURRENT_STATE.md`
   - 지금 실제 구현/우선순위/임시 결정
4. `docs/specs/`
   - 장기 배경 설계와 기초 철학
5. `docs/handoffs/`, `docs/worklogs/`
   - 이력성 문서
6. `docs/setup/`
   - 개발 환경 참고

### 4. 새 문서가 생겨도 진입점은 적게 바뀌어야 한다

새 설계 문서나 계획 문서는 계속 생길 수 있다.

하지만 에이전트가 매번 새로운 문서를 “우연히” 발견하도록 두면 안 된다.

따라서 새 문서가 생길 때 직접 갱신해야 하는 라우팅 지점은 제한한다.

- `docs/INDEX.md`
- 필요 시 `docs/CURRENT_STATE.md`

`AGENTS.md`는 가능한 한 자주 바뀌지 않는 얇은 진입점으로 유지한다.

## 선택된 구조

기존 폴더는 유지한 채, 아래 세 파일을 추가한다.

- `AGENTS.md`
- `docs/INDEX.md`
- `docs/CURRENT_STATE.md`

그리고 기존 `docs/README.md`는 세부 목록을 직접 품는 파일이 아니라, `INDEX.md`로 보내는 얇은 문서로 정리한다.

## 파일별 역할

### `AGENTS.md`

역할:

- 이 리포에서 작업할 때의 기본 작업 규칙 제공
- 문서 탐색 시작점 제공
- 어떤 종류의 작업에 어떤 문서를 먼저 읽어야 하는지 안내

반드시 포함할 내용:

- 작업 규칙
  - 중간 커밋 지양, 마무리 후 정리
  - 테스트 우선
  - 기존 문서 구조 유지
- 현재 문서 우선순위
  - `docs/superpowers/specs` / `docs/superpowers/plans`가 active
  - `docs/specs`는 background
- 작업 유형별 시작 문서
  - UI/UX 작업
  - 생존/조합 시스템 작업
  - Android/export 작업
  - 상태 확인 작업

반드시 제외할 내용:

- 장문의 기능 설계 전문
- 세부 구현 절차
- 오래 변하는 상세 상태 목록

### `docs/INDEX.md`

역할:

- 전체 문서 목차
- 각 폴더/문서군의 성격 설명
- 최신 문서로 가는 허브

섹션은 아래처럼 둔다.

- `Current`
  - 지금 가장 먼저 읽어야 하는 문서
- `Active Specs`
  - 현재 활성 설계 문서
- `Active Plans`
  - 현재 활성 구현 계획
- `Background`
  - 장기 배경 설계
- `History`
  - worklogs / handoffs
- `Setup`
  - 개발 환경 문서

즉 `INDEX.md`는 실제 탐색 허브다.

### `docs/CURRENT_STATE.md`

역할:

- 지금 이 프로젝트가 어디까지 와 있는지 한 페이지로 보여주는 문서
- 세션이 바뀌어도 가장 먼저 읽으면 현재 상태를 빠르게 파악할 수 있는 문서

반드시 포함할 내용:

- 현재 게임 방향
  - 세로 전용 지향
  - 가방이 메인, 조합은 보조
- 현재 구현 완료 큰 축
  - 생존 스탯
  - indoor/outdoor 전환
  - shared crafting / codex / lighter
  - portrait phase 1
- 현재 활성 설계 문서 링크
- 현재 작업 중이거나 다음 우선순위인 항목
- 임시 개발용 결정
  - 예: 개발 테스트용 시작 아이템 지급 같은 것

즉 `CURRENT_STATE.md`는 프로젝트 상태 스냅샷이다.

## 기존 폴더 해석 규칙

이번 설계는 기존 폴더를 아래처럼 해석한다.

### `docs/specs/`

- 장기 배경 설계
- 제품/기술의 기본 방향
- 지금도 유효할 수 있지만, 최신 기능 작업의 직접 기준은 아닐 수 있음

### `docs/superpowers/specs/`

- 현재 활성 기능 설계
- 최근 작업에 직접 연결되는 문서
- 새 기능 설계는 우선 이쪽에 추가

### `docs/superpowers/plans/`

- 활성 구현 계획
- 실제 작업 순서와 테스트 전략을 담는 문서
- 구현 전에는 이쪽 문서를 기준으로 움직임

### `docs/handoffs/`, `docs/worklogs/`

- 맥락 복원용 이력
- 현재 기준 문서가 아니라 배경 참고용

### `docs/setup/`

- 환경 설정 참고
- 프로젝트 방향 문서와는 분리

## 문서 생성 규칙

앞으로 새 문서가 생길 때의 기본 규칙은 아래와 같다.

### 새 기능 설계

- 위치: `docs/superpowers/specs/`
- 그리고 `docs/INDEX.md`의 `Active Specs`를 갱신

### 새 구현 계획

- 위치: `docs/superpowers/plans/`
- 그리고 `docs/INDEX.md`의 `Active Plans`를 갱신

### 현재 상태 변화

- 위치: `docs/CURRENT_STATE.md`
- 단기 상태, 우선순위, 임시 결정 갱신

### 장기 배경 설계 추가

- 위치: `docs/specs/`
- `docs/INDEX.md`의 `Background`에 연결

즉 `문서를 어디 둘까`보다 `어떤 역할 문서인가`를 먼저 보고 위치를 정한다.

## 문서 연결 방식

각 문서는 아래 메타를 일관되게 가지는 편이 좋다.

- `Status`
- `Created`
- `Last updated`
- 필요 시 `Depends on`
- 필요 시 `Supersedes`

그리고 `INDEX.md`에서는 가능하면 문서군을 아래처럼 짧은 설명과 함께 나열한다.

- 문서 경로
- 역할
- 최신성 또는 우선순위

이렇게 해야 사람이든 에이전트든 오래된 문서를 현재 기준으로 오독할 가능성이 줄어든다.

## 완료 기준

아래가 모두 만족되면 이번 설계는 구현 준비가 된 것으로 본다.

- `AGENTS.md`가 짧은 라우터 역할만 하도록 정의되어 있다.
- `docs/INDEX.md`가 전체 문서 허브 역할을 한다.
- `docs/CURRENT_STATE.md`가 현재 프로젝트 상태 스냅샷 역할을 한다.
- `docs/superpowers/specs` / `plans`가 active 문서군으로 명시되어 있다.
- `docs/specs`는 장기 배경 문서군으로 분리 해석된다.
- 기존 폴더를 옮기지 않고도 새 문서가 어디에 들어가야 하는지 규칙이 정리되어 있다.
