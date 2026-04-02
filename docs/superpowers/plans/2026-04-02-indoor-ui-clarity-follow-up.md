# Indoor UI Clarity Follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the indoor screen easier to parse at a glance by adding icon-based survival chips with exact-value detail sheets, restoring a small always-visible minimap, and making bag tabs and equipment state visually unambiguous.

**Architecture:** Keep the current reading-first indoor shell, but layer a compact inline minimap card and an explicit survival-detail sheet into `IndoorMode`. Reuse `IndoorDirector` as the single source of truth for chip stages, exact values, and inventory/equipment rows, and tighten tests around the new presentation contract so future UI tuning does not regress clarity.

**Tech Stack:** Godot 4, GDScript, existing `IndoorMode` / `IndoorDirector` / `IndoorMinimap`, existing headless Godot unit + smoke tests

---

## File Structure

- `game/scenes/indoor/indoor_mode.tscn`
  - Add a persistent mini minimap card to the main screen.
  - Add a survival-detail bottom sheet for exact numeric values.
  - Strengthen bag tab structure so carried/equipped states read like different UI surfaces.
- `game/scripts/indoor/indoor_mode.gd`
  - Render icon-backed survival chips as buttons instead of plain text panels.
  - Wire chip presses to the detail sheet.
  - Keep a small minimap live in the main screen while preserving the full-map overlay.
  - Style bag tabs and row groups with explicit selected/secondary states.
- `game/scripts/indoor/indoor_director.gd`
  - Expand the survival payload so the view can show stage text, exact values, rules text, and recovery hints without recomputing game logic in the scene.
- `game/scripts/indoor/indoor_minimap.gd`
  - Support both the small inline minimap card and the existing full-map overlay using the same snapshot API.
- `game/tests/unit/test_indoor_mode.gd`
  - Lock in the presence and behavior of the inline minimap, chip detail sheet, and clearer bag tabs.
- `game/tests/unit/test_indoor_minimap.gd`
  - Verify the minimap still centers on the current room when rendered at the smaller inline-card size.
- `game/tests/smoke/test_first_playable_loop.gd`
  - Keep the first playable indoor loop working after the UI refinement.
- `docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md`
  - Record the user feedback that motivated the change, the final design call, and residual UI risks.
- `docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md`
  - Capture what shipped, what was verified, and what future polish should build on top of this pass.

### Task 1: Define the Clarity Contract in Tests

**Files:**
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Modify: `game/tests/unit/test_indoor_minimap.gd`

- [ ] **Step 1: Add failing expectations for icon chips, inline minimap, and stat detail sheet**

Extend `game/tests/unit/test_indoor_mode.gd` so it asserts the main screen contains a persistent small minimap and tappable survival chips that open an exact-value detail surface.

```gdscript
var inline_minimap_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow/MiniMapCard") as Control
assert_true(inline_minimap_card != null and inline_minimap_card.visible, "Indoor mode should keep a small minimap visible in the main reading screen.")

var inline_minimap := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow/MiniMapCard/MapNodes") as Control
assert_true(inline_minimap != null, "Indoor mode should mount an always-visible minimap node.")

var stat_chip_row := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/StatChips") as HBoxContainer
assert_true(stat_chip_row != null and stat_chip_row.get_child_count() == 4, "Indoor mode should show four survival chips.")

var first_chip := stat_chip_row.get_child(0) as Button
assert_true(first_chip != null, "Indoor mode should render survival chips as buttons, not passive labels.")
assert_true(first_chip.icon != null, "Indoor mode should give each survival chip an icon.")

var stat_detail_sheet := indoor_mode.get_node_or_null("StatDetailSheet") as Control
assert_true(stat_detail_sheet != null and not stat_detail_sheet.visible, "Indoor mode should keep the stat detail sheet hidden by default.")
first_chip.emit_signal("pressed")
await process_frame
assert_true(stat_detail_sheet.visible, "Indoor mode should open the stat detail sheet when a chip is pressed.")
```

- [ ] **Step 2: Add failing expectations for bag tab clarity**

Extend `game/tests/unit/test_indoor_mode.gd` so the bag view contract reflects explicit tab states and different presentation for carried vs equipped.

```gdscript
bag_button.emit_signal("pressed")
await process_frame

assert_true(carried_tab_button.toggle_mode, "Carried tab should render as an explicit selectable tab.")
assert_true(equipped_tab_button.toggle_mode, "Equipped tab should render as an explicit selectable tab.")
assert_true(carried_tab_button.button_pressed, "Carried tab should be selected by default.")
assert_true(not equipped_tab_button.button_pressed, "Equipped tab should be inactive by default.")

equipped_tab_button.emit_signal("pressed")
await process_frame
assert_true(equipped_tab_button.button_pressed, "Equipped tab should become the selected state when tapped.")
assert_true(not carried_tab_button.button_pressed, "Carried tab should leave the selected state when another tab is active.")
```

- [ ] **Step 3: Tighten the minimap viewport test for the new inline size**

Update `game/tests/unit/test_indoor_minimap.gd` so it uses the smaller card dimensions that the main screen will actually render.

```gdscript
minimap.custom_minimum_size = Vector2(200, 132)
minimap.size = Vector2(200, 132)

assert_true(
	absf(current_label.position.x - 100.0) <= 24.0 and absf(current_label.position.y - 56.0) <= 24.0,
	"Indoor minimap should keep the current room centered even in the compact inline-card viewport."
)
```

- [ ] **Step 4: Run tests to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_minimap.gd
```

Expected: both FAIL because the current screen still uses text-only stat chips, has no inline minimap card, and the bag tabs are not explicit selected tabs.

- [ ] **Step 5: Commit the failing-test checkpoint**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/tests/unit/test_indoor_mode.gd \
  game/tests/unit/test_indoor_minimap.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "test: define indoor ui clarity follow-up contract"
```

### Task 2: Add Icon Chips and Exact-Value Detail Sheet

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Reshape the top bar into header + status rows and add the detail sheet**

Update `game/scenes/indoor/indoor_mode.tscn` so the top region has a header row, a status row, and a reusable stat-detail sheet.

```tscn
[node name="TopBar" type="VBoxContainer" parent="Panel/Layout/MainColumn"]
theme_override_constants/separation = 8

[node name="HeaderRow" type="HBoxContainer" parent="Panel/Layout/MainColumn/TopBar"]
[node name="TitleLabel" type="Label" parent="Panel/Layout/MainColumn/TopBar/HeaderRow"]
[node name="LocationLabel" type="Label" parent="Panel/Layout/MainColumn/TopBar/HeaderRow"]
[node name="TimeLabel" type="Label" parent="Panel/Layout/MainColumn/TopBar/HeaderRow"]

[node name="StatusRow" type="HBoxContainer" parent="Panel/Layout/MainColumn/TopBar"]
[node name="StatChips" type="HBoxContainer" parent="Panel/Layout/MainColumn/TopBar/StatusRow"]
[node name="Tools" type="HBoxContainer" parent="Panel/Layout/MainColumn/TopBar/StatusRow/Tools"]

[node name="StatDetailSheet" type="PanelContainer" parent="."]
visible = false
[node name="TitleLabel" type="Label" parent="StatDetailSheet/VBox"]
[node name="ValueLabel" type="Label" parent="StatDetailSheet/VBox"]
[node name="RuleLabel" type="Label" parent="StatDetailSheet/VBox"]
[node name="RecoveryLabel" type="Label" parent="StatDetailSheet/VBox"]
```

- [ ] **Step 2: Expose richer chip payloads from the director**

Update `game/scripts/indoor/indoor_director.gd` so the scene can render chip text quickly and still show exact values when a chip is selected.

```gdscript
func get_survival_chip_rows() -> Array[Dictionary]:
	return [
		{
			"id": "hunger",
			"label": "허기",
			"stage": _run_state.get_hunger_stage(),
			"value": _run_state.hunger,
			"icon_id": "hunger",
			"rule_text": "0이 되면 체력이 계속 감소한다",
			"recovery_text": "음식으로 회복",
		},
		{
			"id": "thirst",
			"label": "갈증",
			"stage": _run_state.get_thirst_stage(),
			"value": _run_state.thirst,
			"icon_id": "thirst",
			"rule_text": "허기보다 더 빠르게 바닥난다",
			"recovery_text": "물과 음료로 회복",
		},
	]

func get_survival_chip_detail(chip_id: String) -> Dictionary:
	for chip in get_survival_chip_rows():
		if String(chip.get("id", "")) == chip_id:
			return chip
	return {}
```

- [ ] **Step 3: Render chips as icon buttons and wire the detail sheet**

Update `game/scripts/indoor/indoor_mode.gd` so stat chips become buttons with icons and open the exact-value detail surface.

```gdscript
var _stat_detail_sheet: Control = null
var _stat_detail_title: Label = null
var _stat_detail_value: Label = null
var _stat_detail_rule: Label = null
var _stat_detail_recovery: Label = null
var _selected_chip_id := ""

func _refresh_stat_chips() -> void:
	_clear_children(_stat_chips)
	for chip in _director.get_survival_chip_rows():
		var button := Button.new()
		button.flat = false
		button.toggle_mode = false
		button.icon = _survival_chip_icon(String(chip.get("icon_id", "")))
		button.text = String(chip.get("stage", ""))
		button.pressed.connect(Callable(self, "_on_stat_chip_pressed").bind(String(chip.get("id", ""))))
		_stat_chips.add_child(button)

func _on_stat_chip_pressed(chip_id: String) -> void:
	_selected_chip_id = chip_id
	_refresh_stat_detail_sheet()
	_stat_detail_sheet.visible = true

func _refresh_stat_detail_sheet() -> void:
	var detail := _director.get_survival_chip_detail(_selected_chip_id)
	_stat_detail_title.text = String(detail.get("label", "상태"))
	_stat_detail_value.text = "%d / 100 · %s" % [int(detail.get("value", 0)), String(detail.get("stage", ""))]
	_stat_detail_rule.text = String(detail.get("rule_text", ""))
	_stat_detail_recovery.text = String(detail.get("recovery_text", ""))
```

- [ ] **Step 4: Re-run the indoor-mode unit test**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Expected: `INDOOR_MODE_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/indoor/indoor_mode.tscn \
  game/scripts/indoor/indoor_mode.gd \
  game/scripts/indoor/indoor_director.gd \
  game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add indoor stat chip detail sheet"
```

### Task 3: Restore a Persistent Mini Minimap Without Breaking the Full Map

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/indoor/indoor_minimap.gd`
- Test: `game/tests/unit/test_indoor_minimap.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Add the inline minimap card to the main screen**

Update `game/scenes/indoor/indoor_mode.tscn` so a small map card is always visible in the reading surface while the larger overlay remains available.

```tscn
[node name="ContextRow" type="HBoxContainer" parent="Panel/Layout/MainColumn"]
theme_override_constants/separation = 12

[node name="ReadingCard" type="PanelContainer" parent="Panel/Layout/MainColumn/ContextRow"]
size_flags_horizontal = 3

[node name="MiniMapCard" type="PanelContainer" parent="Panel/Layout/MainColumn/ContextRow"]
custom_minimum_size = Vector2(200, 132)

[node name="MapNodes" type="Control" parent="Panel/Layout/MainColumn/ContextRow/MiniMapCard"]
script = ExtResource("3")
```

- [ ] **Step 2: Feed the same snapshot to the inline map and the overlay**

Update `game/scripts/indoor/indoor_mode.gd` so `_refresh_minimap()` writes the director snapshot to both map surfaces.

```gdscript
var _inline_minimap: Control = null
var _overlay_minimap: Control = null

func _refresh_minimap() -> void:
	if _director == null or not _director.has_method("get_map_snapshot"):
		return
	var snapshot := _director.get_map_snapshot()
	if _inline_minimap != null and _inline_minimap.has_method("set_snapshot"):
		_inline_minimap.set_snapshot(snapshot)
	if _overlay_minimap != null and _overlay_minimap.has_method("set_snapshot"):
		_overlay_minimap.set_snapshot(snapshot)
```

- [ ] **Step 3: Keep the minimap script centered in the compact viewport**

Adjust `game/scripts/indoor/indoor_minimap.gd` only enough to make the inline-card scale robust.

```gdscript
func _display_offset() -> Vector2:
	var current_node := _current_node()
	if current_node.is_empty():
		return Vector2.ZERO
	var viewport_size := size
	if viewport_size == Vector2.ZERO:
		viewport_size = custom_minimum_size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(200, 132)
	return (viewport_size * 0.5) - _raw_point_for_node(current_node)
```

- [ ] **Step 4: Re-run the minimap and indoor-mode tests**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_minimap.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Expected: both PASS.

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/indoor/indoor_mode.tscn \
  game/scripts/indoor/indoor_mode.gd \
  game/scripts/indoor/indoor_minimap.gd \
  game/tests/unit/test_indoor_minimap.gd \
  game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add inline indoor minimap"
```

### Task 4: Make Bag Tabs and Equipment State Read Instantly

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`
- Create: `docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md`
- Create: `docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md`

- [ ] **Step 1: Upgrade the bag tabs into explicit segmented controls**

Update `game/scenes/indoor/indoor_mode.tscn` so the carried/equipped controls are clearly separate tabs instead of plain buttons.

```tscn
[node name="Tabs" type="HBoxContainer" parent="BagSheet/VBox"]
[node name="CarriedTabButton" type="Button" parent="BagSheet/VBox/Tabs"]
toggle_mode = true
size_flags_horizontal = 3
[node name="EquippedTabButton" type="Button" parent="BagSheet/VBox/Tabs"]
toggle_mode = true
size_flags_horizontal = 3
```

- [ ] **Step 2: Render carried rows as interactive inventory and equipped rows as current-state lines**

Update `game/scripts/indoor/indoor_mode.gd` so carried rows keep button affordances, while equipped rows look like static slot summaries.

```gdscript
func _refresh_bag_sheet() -> void:
	_carried_tab_button.button_pressed = _active_bag_tab == "carried"
	_equipped_tab_button.button_pressed = _active_bag_tab == "equipped"
	_apply_tab_visuals(_carried_tab_button, _active_bag_tab == "carried")
	_apply_tab_visuals(_equipped_tab_button, _active_bag_tab == "equipped")

	if _active_bag_tab == "carried":
		for row in _director.get_inventory_rows():
			var button := Button.new()
			button.text = String(row.get("label", ""))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			_inventory_items.add_child(button)
	else:
		for row in _director.get_equipped_rows():
			var panel := PanelContainer.new()
			var label := Label.new()
			label.text = String(row)
			panel.add_child(label)
			_inventory_items.add_child(panel)
```

- [ ] **Step 3: Document the change and run the key regression tests**

Create `docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md` and `docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md` with the user feedback, the chosen solution, verification commands, and remaining polish notes.

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/smoke/test_first_playable_loop.gd
```

Expected: `INDOOR_MODE_OK` and `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 4: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/indoor/indoor_mode.tscn \
  game/scripts/indoor/indoor_mode.gd \
  game/scripts/indoor/indoor_director.gd \
  game/tests/unit/test_indoor_mode.gd \
  game/tests/smoke/test_first_playable_loop.gd \
  docs/worklogs/2026-04-02-indoor-ui-clarity-follow-up.md \
  docs/handoffs/2026-04-02-indoor-ui-clarity-follow-up.md
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: polish indoor ui clarity"
```

