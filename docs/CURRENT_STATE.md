# Current State

- Status: active
- Last updated: 2026-05-02
 

## Product Direction

- Portrait-first mobile presentation.
- Outdoor play keeps continuous travel risk and long-distance survival pressure active.
- Indoor play is text-heavy and decision-driven.
- Inventory is bag-first, with crafting triggered contextually from what is in the bag and where the survivor is.

## Implemented Baseline

Systems already integrated in `main`:

- 2026-05-02 야외 가시 리소스 대격변 1차가 들어갔다.
  - AI 생성 스타일 보드, 건물 시트, 소품 시트, 지형 타일 시트를 `resources/world/city/reference/`에 보관한다.
  - 실제 런타임 야외 건물/소품/도로/눈/보도 PNG는 `scripts/generate_world_visual_overhaul_assets.ps1`로 재생성한다.
  - 보조 건물 2차 AI 시트로 세탁소, 주택, 수리점, 차고, 물류 보관소, 구내 식당, 찻집, 호스텔, 식당 계열까지 같은 밀도의 외형을 갖게 했다.
  - 주요 3x3 야외 블록은 직선 십자 도로만 반복하지 않도록 전면 공간, 골목, 서비스 차선, 눈더미, 가로등, 쇼핑카트, 바리케이드, 덤프스터 등 시각 소품을 추가했다.
  - `OutdoorArtResolver`는 건물 ID별 외형과 블록 데이터의 명시적 `asset_id` 소품을 해석한다.
- 2026-05-02 실내 UX에 추천 행동 스트립을 추가했다.
  - 실내 행동 목록 위에서 현재 방의 낮은 위험 탐색, 획득, 이동 중 먼저 누르기 좋은 선택지를 요약한다.
  - 추천 행동은 한 번에 실행할 수 있어 긴 행동 목록을 읽기 전에 플레이 흐름을 잡아준다.
- Life-world item and recipe expansion.
- Building-specific indoor loot.
- Shared crafting baseline.
- Warmth system.
- Carry-weight baseline.
- Heat-source-gated recovery baseline.
- First quantity-bearing supply sources in high-stock indoor sites.
- Indoor site memory plus drop/re-entry persistence.
- Crafting codex, note-based unlocks, lighter charges, and tool requirements.
- Portrait phase 1 shell and indoor survival sheet work.
- First generated frozen-city art replacement checkpoint.
- Image-backed outdoor frost screen feedback.
- First authored indoor pressure outcomes for cold, noise, fatigue, and small injuries.
- First outdoor terrain hazard zones for black ice and wind-gap pressure.
- First branching indoor resolution option using tools versus brute force.
- First improvised indoor access rules using key-or-setup requirements and material consumption.
- Wearable warmth gear now reduces outdoor cold drain through equipment effects.
- Outdoor black-ice and wind-gap hazards now cover multiple nearby city blocks.
- Clinic medicine storage now has rushed versus flashlight-assisted search risk.
- Gas station fuel salvage now turns empty jerrycans into heavy portable-heat fuel.
- Indoor loot profiles now use validated practical household item ids, and the mart back hall has a listen-first clue action.
- Equipped footwear and face/neck gear can now mitigate authored outdoor hazard pressure.
- Convenience-store counter search now branches between rushed broken-glass risk and safer work-glove handling.
- Convenience-store fridge stock now uses quantity supply pickup for bottled water.
- 야외 위험 접촉은 새 휴대폰 결빙 오버레이, 경고 데칼, 짧은 카메라 흔들림으로 즉시 체감되게 했다.
- 실내 읽기 카드에는 AI 생성 재난 편의점 일러스트와 결과 태그를 붙여 탐색 화면의 장소감을 강화했다.
- 실내 읽기 카드는 건물 분류에 따라 편의점, 의료, 주거, 작업장, 식당 주방 일러스트를 골라 보여준다.
- 실내 읽기 카드는 사무실, 파출소/경비실, 서점, 예배당/대피 공간 계열도 별도 AI 생성 일러스트로 구분한다.
- 실내 행동 버튼은 필요한 도구, 소란, 체력 손실, 피로 증가 같은 위험 미리보기를 보조 라벨로 보여준다.
- 작은 식당은 홀, 주방, 안쪽 보관실 구조와 빠른 위험 수색/장갑을 쓴 안전 수색 분기를 가진다.
- 야외 HUD는 위험 구역에 닿기 전에도 근처 빙판, 틈바람, 눈더미, 시야 불량의 예상 손실을 미리 경고한다.
- 남쪽/동쪽 외곽 블록에는 눈더미와 시야 불량 위험을 추가해 긴 이동 경로의 공백을 줄였다.
- 빵집, 중고 서점, 정육점, 폐교 정문은 4구역 구조와 빠른 위험 수색/도구 기반 안전 수색 분기를 가진다.
- 빵집에서 얻는 코코아 믹스는 뜨거운 물, 보온병 조합으로 따뜻한 코코아와 보온병 코코아 생존 루프에 연결된다.
- 빵집, 서점, 정육점, 폐교 정문 주변 야외 블록에는 건물 진입 전 판단 압력을 주는 눈더미, 빙판, 틈바람 위험이 추가되었다.
- 주인공 야외 스프라이트는 64px 기반 4방향 idle + 8프레임 walk로 교체해 큰 픽셀 덩어리감을 줄였고, 선형 필터링과 부드러운 상하 bob으로 배경 톤에 더 맞는 이동 애니메이션을 만든다.
- 구멍가게, 반찬 가게, 수리점, 물류 보관소는 4구역 구조와 빠른 위험 수색/도구 기반 안전 수색 분기로 확장했고, 각 진입 블록에는 건물 앞 빙판, 틈바람, 눈더미 위험을 추가했다.
- HUD, 실내 행동 카드, 생존 시트의 주요 UI PNG를 새 AI 방향 레퍼런스 기반의 결빙 휴대폰 UI 톤으로 재생성했고, 실내 행동은 `이동/탐색/획득/위험/막힘` 칩과 시간/위험/보상 보조 라벨을 함께 보여준다.
- 가방 시트는 무게, 운반 상태, 야외 이동속도를 한 줄로 요약하고, 인벤토리 행에는 아이템 태그 칩을 붙여 조합/장착/소모 판단에 필요한 정보를 더 빨리 읽게 했다.
- 주인공 걷기 스프라이트는 방향별 발 배치를 다시 생성해 좌/우/상/하 이동이 모두 같은 오른쪽 보행처럼 보이는 문제를 고쳤다.
- 실내 화면은 `여기서 할 일 -> 챙길 물건 -> 다른 구역 -> 막힌 길` 순서로 재배치해, 먼저 현재 장소에서 판단하고 그다음 이동하는 흐름을 강화했다.
- 실내 장소 상태는 본문 문장에 섞지 않고 별도 칩으로 분리해 남은 물건, 설치물, 소란, 수색 완료 여부를 더 빨리 읽게 했다.
- HUD, 생존 시트, 실내 카드의 기본 글자 크기와 대비를 올려 노트북 해상도에서도 읽히도록 했다.
- 타이틀과 생존자 생성 화면은 결빙 휴대폰 UI 톤으로 맞추고, 생존자 생성은 직업/난이도/특성의 생존 의미와 출발 가능 여부를 한눈에 보여주는 선택 요약 구조로 바꾸었다.
- 야외 지도 오버레이는 탐색한 블록 수, 표시 가능한 건물 수, 지도 범례, 현재 위치 복귀 버튼을 제공해 단순 그림이 아니라 이동 계획 도구로 읽히게 했다.
- 가방 목록은 획득 순서 나열에서 벗어나 `먹고 마실 것`, `불과 도구`, `입고 버틸 것`, `읽을 것`, `무거운 짐`, `재료와 기타` 같은 생존 의도별 섹션으로 재정렬된다.
- 조합 모드의 가방 목록은 `기준 재료`, `조합 가능`, `다른 물건` 순서로 바뀌어 두 번째 재료를 더 빨리 고르게 했다.
- 수량 보급 팝업은 선택 수량의 무게 증가를 미리 보여주고, `최대` 버튼으로 여러 번 누르지 않고 최대 유효 수량을 바로 고를 수 있다.
- 실내 행동 카드는 기본 문구도 `물건/단서 확인`, `단서 확인`, `조용한 확인`, `짧은 회복`처럼 선택 의미를 직접 보여주며, 같은 섹션 안에서는 안전한 선택, 위험한 선택, 잠긴 대안을 더 자연스러운 판단 순서로 정렬한다.
- 실내 행동 결과는 필요한 경우 전용 스토리 일러스트로 읽기 카드 이미지를 교체할 수 있으며, 마트 식품 진열대 수색은 `무엇부터 챙길지`를 보여주는 AI 생성 장면 배너를 표시한다.

## 2026-05-02 Checkpoint

- Stable local checkpoint: `8c469a9` (`feat: tune outdoor pressure and refresh city art`).
- Current playability uplift continues from that checkpoint with generated cold-screen feedback and indoor pressure consequences.
- Indoor `outcomes.pressure` is now the preferred first-pass authoring hook for deterministic search risk.
- Noise is visible, persistent, and now resolves deterministic danger thresholds at 3/6/9.
- Recent stabilization also refreshed stale indoor/action UI tests against the current branching gate and loot-profile behavior.

## Active Specs

Canonical active-doc inventory lives in `docs/INDEX.md`. The list below is the current working set that most directly affects the game direction right now.

- [Carry, Heat, and Loot Pressure Design](superpowers/specs/2026-04-27-carry-heat-loot-pressure-design.md)
- [Toast Feedback System Design](superpowers/specs/2026-04-20-toast-feedback-system-design.md)
- [Indoor Depth and Item Expansion Design](superpowers/specs/2026-04-20-indoor-depth-item-expansion-design.md)
- [Outdoor 3x3 Authored Slice Design](superpowers/specs/2026-04-17-outdoor-3x3-authored-slice-design.md)
- [Portrait UI Framework Design](superpowers/specs/2026-04-17-portrait-ui-framework-design.md)
- [Outdoor Art Integration Pass 1 Design](superpowers/specs/2026-04-16-outdoor-art-integration-pass1-design.md)
- [Inventory Craft Slot Bar Design](superpowers/specs/2026-04-16-inventory-craft-slot-bar-design.md)
- [Inventory Bottom Sheet Redesign](superpowers/specs/2026-04-16-inventory-bottom-sheet-redesign.md)
- [Outdoor Spatial Map UI Design](superpowers/specs/2026-04-15-outdoor-spatial-map-ui-design.md)
- [Outdoor Map And Fog UI Design](superpowers/specs/2026-04-15-outdoor-map-and-fog-ui-design.md)
- [Outdoor Threat and Cold Feedback Design](superpowers/specs/2026-04-13-outdoor-threat-and-cold-feedback-design.md)
- [Outdoor World Architecture Design](superpowers/specs/2026-04-15-outdoor-world-architecture-design.md)
- [Outdoor 2x2 Block Expansion Design](superpowers/specs/2026-04-15-outdoor-2x2-block-expansion-design.md) (superseded)
- [Context Routing Docs Design](superpowers/specs/2026-04-10-context-routing-docs-design.md)
- [Contextual Crafting UI Design](superpowers/specs/2026-04-09-contextual-crafting-ui-design.md)
- [Portrait Phase 1 Shell Design](superpowers/specs/2026-04-07-portrait-phase1-shell-design.md)
- [Indoor Portrait Survival Sheet Design](superpowers/specs/2026-04-07-indoor-portrait-survival-sheet-design.md)
- [Crafting Codex Lighter Design](superpowers/specs/2026-04-06-crafting-codex-lighter-design.md)

## Active Plans

For the full active plan inventory, use `docs/INDEX.md`. The list below is the near-term plan stack currently driving implementation.

- [Carry, Heat, and Loot Pressure](superpowers/plans/2026-04-27-carry-heat-loot-pressure.md)
- [Toast Feedback System](superpowers/plans/2026-04-20-toast-feedback-system.md)
- [Indoor Depth and Item Expansion](superpowers/plans/2026-04-20-indoor-depth-item-expansion.md)
- [Outdoor 3x3 Authored Slice](superpowers/plans/2026-04-17-outdoor-3x3-authored-slice.md)
- [Portrait UI Framework](superpowers/plans/2026-04-17-portrait-ui-framework.md)
- [Outdoor Art Integration Pass 1](superpowers/plans/2026-04-16-outdoor-art-integration-pass1.md)
- [Inventory Craft Slot Bar](superpowers/plans/2026-04-16-inventory-craft-slot-bar.md)
- [Inventory Bottom Sheet Redesign](superpowers/plans/2026-04-16-inventory-bottom-sheet-redesign.md)
- [Outdoor Map And Fog UI](superpowers/plans/2026-04-15-outdoor-map-and-fog-ui.md)
- [Outdoor World Architecture](superpowers/plans/2026-04-15-outdoor-world-architecture.md)
- [Outdoor 2x2 Block Expansion](superpowers/plans/2026-04-15-outdoor-2x2-block-expansion.md) (superseded)
- [Outdoor Threat and Cold Feedback](superpowers/plans/2026-04-13-outdoor-threat-and-cold-feedback.md)
- [Context Routing Docs](superpowers/plans/2026-04-10-context-routing-docs.md)
- [Contextual Crafting UI](superpowers/plans/2026-04-09-contextual-crafting-ui.md)
- [Portrait Phase 1 Shell](superpowers/plans/2026-04-07-portrait-phase1-shell.md)
- [Indoor Portrait Survival Sheet](superpowers/plans/2026-04-07-indoor-portrait-survival-sheet.md)
- [Crafting Codex Lighter](superpowers/plans/2026-04-06-crafting-codex-lighter.md)

## Immediate Priorities

- Tighten outdoor cold pressure now that the first carry-weight, heat-source, and quantity-supply scaffolding is in place.
- Make `적정 / 과중 / 과적` meaningfully affect risky outdoor travel, not just inventory presentation.
- Broaden quantity-bearing supply sources past the first `mart / hardware / warehouse` pass where it materially improves scavenging decisions.
- Expand portable heat-source setup and recovery affordances so “go there and come back” versus “establish warmth there” becomes a real decision.
- Deepen the existing building set before pushing outdoor radius again: anchor four buildings into real multi-zone sites and lift the rest out of one-zone shells.
- Expand the item compendium with more believable site-specific finds, not just more raw crafting materials.
- Expand crafted items and cross-recipes so new and existing items can coexist in a deeper authored crafting graph.
- Maintain a separate resource-request ledger for newly introduced buildings and items so art generation can track content growth cleanly.
- Replace placeholder outdoor geometry with frozen-city terrain, buildings, props, and player art while keeping the streamed city runtime stable.
- Build the first outdoor pressure loop with animal pursuit, cold feedback, and more game-like real-time tension.
- Replace the temporary outdoor district scaffolding with a fixed-city streamed block runtime built on fixed-size blocks.
- Expand the first authored city slice from `2x2` to a full contiguous `3x3` so outdoor travel stops feeling tiny before deeper loot/story passes land.
- Keep the city globally open while revealing map knowledge per run from visited blocks only.
- Replace the mismatched outdoor minimap/full-map split with a coherent spatial map stack: local minimap, draggable full outdoor map, fog-of-war, and separate indoor building-detail layer.
- Keep the codex, note unlocks, lighter charges, and tool requirements aligned with the active crafting UI.
- 새 결빙 휴대폰 UI 키트 기준으로 타이틀, 생존자 생성, 지도 오버레이, 수량 선택, 도감, 스토리 일러스트 패널까지 같은 `결정 우선` 시각 언어로 계속 끌어올린다.
- 전용 스토리/결과 일러스트는 단순 장식이 아니라 의미 있는 선택, 위험, 서사 순간을 강화할 때 우선 추가한다.
- Continuously remove dead code, obsolete UI paths, temporary scaffolding, and other local junk that would otherwise pollute future implementation patterns.

## Temporary Development Conditions

- Dev-only starter items and shortcut grants are still enabled for playtesting.
- Treat them as temporary scaffolding, not production behavior.
- Keep them in place until balance and survival pressure are stable enough to remove them cleanly.
