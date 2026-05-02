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
- Continuously remove dead code, obsolete UI paths, temporary scaffolding, and other local junk that would otherwise pollute future implementation patterns.

## Temporary Development Conditions

- Dev-only starter items and shortcut grants are still enabled for playtesting.
- Treat them as temporary scaffolding, not production behavior.
- Keep them in place until balance and survival pressure are stable enough to remove them cleanly.
