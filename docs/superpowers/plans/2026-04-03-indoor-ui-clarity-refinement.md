# Indoor UI Clarity Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실내 UI를 `상시 미니맵 + 위치 스트립 + 닫을 수 있는 상태 상세 + 가방 우측 상세 패널` 구조로 정리해서, 읽기 흐름을 깨지 않으면서도 필요한 정보를 더 쉽게 확인하게 만든다.

**Architecture:** `IndoorMode`의 화면 계층만 재배치하고, 기존 `IndoorDirector`의 데이터 계약은 최대한 유지한다. 표시 포맷과 패널 위치만 바꾸고, 미니맵은 여전히 `snapshot` 기반으로 렌더링하되 상시 카드와 전체 구조도 오버레이의 역할을 분리한다.

**Tech Stack:** Godot 4.4.1, GDScript, `.tscn` Control UI, headless Godot tests

---

## File Structure

- Modify: `game/scenes/indoor/indoor_mode.tscn`
  - 상단 `LocationStrip`, 상시 미니맵 카드, 가방 좌/우 레이아웃, 상태 상세 닫기 버튼 추가
- Modify: `game/scripts/indoor/indoor_mode.gd`
  - 새 노드 캐싱, 닫기 버튼 바인딩, 가방 우측 상세 렌더링, 상시 미니맵/위치 스트립 갱신
- Modify: `game/scripts/indoor/indoor_director.gd`
  - 상태 상세 수치 정수화, 장착중 행 텍스트 정리, 선택된 아이템 시트 데이터 보강
- Modify: `game/tests/unit/test_indoor_mode.gd`
  - 새 위치 스트립, 상태 상세 닫기, 가방 우측 상세, 장착중/소지품 구조 검증
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
  - 새 UI 구조에서도 기본 플레이 루프가 유지되는지 확인
- Modify: `docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md`
  - 이번 UI 후속 수정의 이유와 효과 기록
- Modify: `docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md`
  - 다음 세션이 이어받을 수 있게 현재 상태와 검증 커맨드 갱신

### Task 1: UI 계약 테스트를 먼저 고정

**Files:**
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Write the failing test**

`game/tests/unit/test_indoor_mode.gd`에 아래 기대값을 추가한다.

```gdscript
var location_strip := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/LocationStrip") as Control
if not assert_true(
	location_strip != null and location_strip.visible,
	"Indoor mode should expose a dedicated location strip below the top bar."
):
	indoor_mode.free()
	return

var location_value := _find_descendant_by_name_and_type(location_strip, "LocationValueLabel", "Label") as Label
if not assert_true(location_value != null, "Indoor mode should render the current zone inside the location strip."):
	indoor_mode.free()
	return
assert_eq(location_value.text, "정문 진입부", "Indoor mode should show the current zone label without the old header-row prefix.")

var stat_detail_close := _find_descendant_by_name_and_type(stat_detail_sheet, "CloseButton", "Button") as Button
if not assert_true(stat_detail_close != null, "Indoor mode should expose a close button in the stat detail sheet."):
	indoor_mode.free()
	return
assert_eq(stat_detail_value.text, "100 / 100 · 안정", "Indoor mode should render exact stat values without decimals.")

var bag_content_row := indoor_mode.get_node_or_null("BagSheet/VBox/ContentRow") as HBoxContainer
if not assert_true(bag_content_row != null, "Indoor mode should split the bag sheet into list/detail columns."):
	indoor_mode.free()
	return

var item_detail_panel := indoor_mode.get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel") as Control
if not assert_true(item_detail_panel != null, "Indoor mode should render selected inventory details inside the bag sheet."):
	indoor_mode.free()
	return

var equipped_tab := _find_descendant_by_name_and_type(indoor_mode, "EquippedTabButton", "Button") as Button
if not assert_true(
	equipped_tab.theme_override_styles.get("normal") != null and equipped_tab.theme_override_styles.get("pressed") != null,
	"Indoor mode should explicitly style the equipped tab states."
):
	indoor_mode.free()
	return
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home \
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL because `LocationStrip`, bag `ContentRow`, or stat detail `CloseButton` do not exist yet.

- [ ] **Step 3: Write minimal implementation**

이 단계에서는 생산 코드를 건드리지 않는다. 실패 메시지를 확인하고, 노드 경로와 기대 텍스트를 최종 확정한다.

```text
Expected first failure shape:
- Missing node: Panel/Layout/MainColumn/LocationStrip
or
- Missing node: BagSheet/VBox/ContentRow/ItemDetailPanel
```

- [ ] **Step 4: Run test to verify it still fails for the intended reason**

Run the same command again and confirm the failure remains a missing-UI-contract failure, not a syntax error.

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "test: lock indoor ui clarity refinement contract"
```

### Task 2: 씬 구조를 새 레이아웃으로 재배치

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Write the failing scene-structure expectation**

`game/tests/unit/test_indoor_mode.gd`에 가방 내부 상세 컬럼과 위치 스트립, 상태 상세 닫기 버튼의 실제 경로를 검증하는 기대를 추가한다.

```gdscript
var inline_minimap_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow/MiniMapCard") as Control
if not assert_true(
	inline_minimap_card != null and inline_minimap_card.visible,
	"Indoor mode should keep a compact always-visible minimap card in the main screen."
):
	indoor_mode.free()
	return

var item_detail_title := indoor_mode.get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/ItemNameLabel") as Label
if not assert_true(item_detail_title != null, "Indoor mode should render the item detail title inside the right-side bag panel."):
	indoor_mode.free()
	return
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home \
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL because the new `BagSheet/VBox/ContentRow/...` nodes are not present yet.

- [ ] **Step 3: Write minimal implementation**

`game/scenes/indoor/indoor_mode.tscn`을 아래 구조로 바꾼다.

```tscn
[node name="LocationStrip" type="PanelContainer" parent="Panel/Layout/MainColumn"]

[node name="HBox" type="HBoxContainer" parent="Panel/Layout/MainColumn/LocationStrip"]
[node name="LocationCaptionLabel" type="Label" parent="Panel/Layout/MainColumn/LocationStrip/HBox"]
text = "현재 위치"
[node name="LocationValueLabel" type="Label" parent="Panel/Layout/MainColumn/LocationStrip/HBox"]
text = "확인 중"

[node name="ContentRow" type="HBoxContainer" parent="BagSheet/VBox"]
theme_override_constants/separation = 12

[node name="InventoryColumn" type="VBoxContainer" parent="BagSheet/VBox/ContentRow"]
size_flags_horizontal = 3

[node name="ItemDetailPanel" type="PanelContainer" parent="BagSheet/VBox/ContentRow"]
size_flags_horizontal = 2

[node name="VBox" type="VBoxContainer" parent="BagSheet/VBox/ContentRow/ItemDetailPanel"]
[node name="ItemNameLabel" type="Label" parent="BagSheet/VBox/ContentRow/ItemDetailPanel/VBox"]
[node name="ItemDescriptionLabel" type="Label" parent="BagSheet/VBox/ContentRow/ItemDetailPanel/VBox"]
[node name="ItemEffectLabel" type="Label" parent="BagSheet/VBox/ContentRow/ItemDetailPanel/VBox"]
[node name="ActionButtons" type="HBoxContainer" parent="BagSheet/VBox/ContentRow/ItemDetailPanel/VBox"]

[node name="CloseButton" type="Button" parent="StatDetailSheet/VBox/Header"]
text = "닫기"
```

그리고 `InventoryScroll`을 `InventoryColumn` 아래로 옮겨서 왼쪽 목록만 스크롤되게 한다.

- [ ] **Step 4: Run test to verify it passes**

Run the same `test_indoor_mode` command.

Expected: PASS on node-path assertions, or move on to the next failing behavior assertion in the same test.

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/indoor/indoor_mode.tscn \
  game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: restructure indoor scene layout for clarity"
```

### Task 3: `IndoorMode` 동작과 표시 포맷 맞추기

**Files:**
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Write the failing behavior test**

`game/tests/unit/test_indoor_mode.gd`에 닫기 버튼, 가방 우측 상세, 정수형 수치, 장착중 행의 상태 카드 표현을 검증한다.

```gdscript
target_chip_button.emit_signal("pressed")
await process_frame
stat_detail_close.emit_signal("pressed")
await process_frame
assert_true(not stat_detail_sheet.visible, "Indoor mode should close the stat detail sheet when the close button is pressed.")

bag_button.emit_signal("pressed")
await process_frame
var first_inventory_row := _find_descendant_by_name_and_type(indoor_mode, "InventoryRow_inspect_inventory_energy_bar", "PanelContainer") as PanelContainer
if not assert_true(first_inventory_row != null, "Indoor mode should keep inventory rows addressable by action id."):
	indoor_mode.free()
	return
var row_button := _find_descendant_by_name_and_type(first_inventory_row, "RowButton", "Button") as Button
row_button.emit_signal("pressed")
await process_frame
assert_true(item_detail_panel.visible, "Indoor mode should show inventory details inside the bag detail panel when an item row is pressed.")

var equipped_row := _find_descendant_by_name_and_type(indoor_mode, "EquippedRow_back", "PanelContainer") as PanelContainer
if equipped_row != null:
	var summary := _find_descendant_by_name_and_type(equipped_row, "SummaryLabel", "Label") as Label
	assert_true(summary.text.find("등") != -1, "Indoor mode should keep equipped rows formatted as slot-first status cards.")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home \
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL because the close button is not wired, item details still use the floating `ItemSheet`, or exact stat values still contain decimals.

- [ ] **Step 3: Write minimal implementation**

`game/scripts/indoor/indoor_mode.gd`에서 새 노드 경로와 동작을 연결한다.

```gdscript
var _location_value_label: Label = null
var _stat_detail_close_button: Button = null
var _item_detail_panel: Control = null

func _bind_ui_buttons() -> void:
	...
	if _stat_detail_close_button != null and not _stat_detail_close_button.pressed.is_connected(Callable(self, "_on_stat_detail_close_pressed")):
		_stat_detail_close_button.pressed.connect(Callable(self, "_on_stat_detail_close_pressed"))

func _refresh_top_bar() -> void:
	...
	if _location_value_label != null and _director.has_method("get_current_zone_label"):
		_location_value_label.text = String(_director.get_current_zone_label())

func _refresh_item_sheet() -> void:
	if _item_detail_panel == null:
		return
	_item_detail_panel.visible = _bag_sheet != null and _bag_sheet.visible and bool(sheet.get("visible", false))

func _on_stat_detail_close_pressed() -> void:
	_clear_stat_detail_selection()
```

`game/scripts/indoor/indoor_director.gd`에서 상세 수치를 정수형으로 바꾼다.

```gdscript
func get_survival_chip_rows() -> Array[Dictionary]:
	...
	"%d / %d · %s" % [int(round(_run_state.health)), _run_state.MAX_SURVIVAL_VALUE, _run_state.get_health_stage()]
	...
	"%d / %d · %s" % [int(round(_run_state.hunger)), _run_state.MAX_SURVIVAL_VALUE, _run_state.get_hunger_stage()]
	...
	"%d · %s" % [int(round(_run_state.fatigue)), _run_state.get_fatigue_stage()]
```

또 `get_equipped_rows()`의 `summary_text`/`detail_text`를 슬롯 중심 상태 카드 문장으로 정리한다.

- [ ] **Step 4: Run test to verify it passes**

Run the same `test_indoor_mode` command.

Expected: PASS with `INDOOR_MODE_OK`.

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scripts/indoor/indoor_mode.gd \
  game/scripts/indoor/indoor_director.gd \
  game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: implement indoor ui clarity refinement behavior"
```

### Task 4: 미니맵 표시 역할과 플레이 루프 회귀 검증

**Files:**
- Modify: `game/scripts/indoor/indoor_minimap.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Modify: `docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md`
- Modify: `docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md`
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Write the failing test**

`game/tests/smoke/test_first_playable_loop.gd`에 상시 미니맵과 위치 스트립이 새 레이아웃에서도 유지되는지 검증을 추가한다.

```gdscript
var indoor_mode := _find_descendant_by_name_and_type(root, "IndoorMode", "Control") as Control
var location_strip := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/LocationStrip") as Control
assert_true(location_strip != null and location_strip.visible, "First playable loop should keep the dedicated location strip visible indoors.")

var minimap_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow/MiniMapCard") as Control
assert_true(minimap_card != null and minimap_card.visible, "First playable loop should keep the inline minimap visible indoors.")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home \
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/smoke/test_first_playable_loop.gd
```

Expected: FAIL until the smoke uses the new node paths and the minimap/location strip survive the full loop.

- [ ] **Step 3: Write minimal implementation**

`game/scripts/indoor/indoor_minimap.gd`는 현재처럼 `current_zone_id` 중심 offset을 유지하되, inline card에서 멀리 떨어진 방문 구역이 주인공이 되지 않도록 현재 중심 offset을 계속 사용한다. 코드 변경은 최소화하고, 필요한 경우 주석 한 줄만 추가한다.

```gdscript
func _display_offset() -> Vector2:
	var current_node := _current_node()
	if current_node.is_empty():
		return Vector2.ZERO
	return (viewport_size * 0.5) - _raw_point_for_node(current_node)
```

`docs/worklogs/...`와 `docs/handoffs/...`에는 이번 변경 이유와 검증 커맨드를 추가한다.

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home \
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd

XDG_DATA_HOME=/tmp/codex-godot-home \
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

```text
INDOOR_MODE_OK
FIRST_PLAYABLE_LOOP_OK
```

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scripts/indoor/indoor_minimap.gd \
  game/tests/smoke/test_first_playable_loop.gd \
  docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md \
  docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md
git -C /home/muhyeon_shin/packages/apocalypse commit -m "test: verify indoor ui clarity refinement end to end"
```

## Self-Review

- 스펙 커버리지:
  - 상시 미니맵: Task 2, Task 4
  - 전체 구조도 유지: Task 2, Task 3
  - 상태 상세 닫기 + 정수 수치: Task 1, Task 3
  - 가방 우측 상세: Task 2, Task 3
  - 장착중 시인성/카드화: Task 1, Task 3
  - 위치 스트립: Task 1, Task 2, Task 4
- Placeholder scan: `TODO`, `TBD`, “적절히” 같은 표현 없음
- Type consistency:
  - `LocationStrip`, `LocationValueLabel`, `ContentRow`, `ItemDetailPanel`, `CloseButton` 경로를 전 태스크에서 동일하게 사용
  - 테스트와 구현 모두 `IndoorMode`/`IndoorDirector`/`IndoorMinimap` 현재 계약에 맞춰 작성

