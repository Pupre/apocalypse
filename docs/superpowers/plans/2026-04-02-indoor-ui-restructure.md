# Indoor UI Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild indoor presentation into a mobile-first reading surface with a compact top bar, action-focused main body, optional minimap overlay, and bag sheet so indoor play stops feeling like a noisy dashboard.

**Architecture:** Keep indoor gameplay rules and director data intact, but replace the current two-column `indoor_mode` layout with a single-column presentation shell. Move optional tools into overlays and sheets, and make `run_controller` / `hud_presenter` treat indoor mode as a dedicated presentation surface instead of sharing the outdoor HUD.

**Tech Stack:** Godot 4, GDScript, existing `IndoorDirector` / `IndoorMinimap`, existing run-state survival stages, headless Godot unit/smoke tests

---

## File Structure

- `game/scenes/indoor/indoor_mode.tscn`
  - Replace the permanent sidebar layout with a single-column indoor shell.
  - Add a compact top bar, tool triggers (`구조도`, `가방`), a minimap overlay, and a bag bottom sheet.
- `game/scripts/indoor/indoor_mode.gd`
  - Rebind node lookups for the new scene shape.
  - Split presentation refresh into top-bar, reading surface, action list, minimap overlay, and bag sheet refreshers.
- `game/scripts/indoor/indoor_director.gd`
  - Expose compact payload helpers for indoor top-bar status chips and bag-sheet content.
  - Keep gameplay state unchanged; only add presentation-friendly accessors where needed.
- `game/scripts/indoor/indoor_minimap.gd`
  - Keep current discovery logic but support overlay-sized rendering cleanly.
- `game/scripts/run/run_controller.gd`
  - Explicitly switch HUD behavior when entering or leaving indoor mode.
- `game/scripts/run/hud_presenter.gd`
  - Hide or fully minimize the shared HUD during indoor mode instead of competing with the indoor top bar.
- `game/tests/unit/test_indoor_mode.gd`
  - Lock in the new indoor node contract and visible behavior.
- `game/tests/unit/test_run_controller_live_transition.gd`
  - Lock in indoor/outdoor HUD presentation boundaries through mode transitions.
- `game/tests/smoke/test_first_playable_loop.gd`
  - Keep the first playable loop alive after the UI migration.
- `docs/worklogs/2026-04-02-indoor-ui-restructure.md`
  - Human-readable rationale and change summary.
- `docs/handoffs/2026-04-02-indoor-ui-restructure.md`
  - Continuation checklist, verification state, and remaining risks.

### Task 1: Lock the New Indoor Screen Contract in Tests

**Files:**
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Modify: `game/tests/unit/test_run_controller_live_transition.gd`

- [ ] **Step 1: Write the failing indoor-shell expectations**

Extend `game/tests/unit/test_indoor_mode.gd` so it asserts the old sidebar contract is gone and the new shell exists.

```gdscript
var sidebar := indoor_mode.get_node_or_null("Panel/Layout/Sidebar")
assert_true(sidebar == null, "Indoor mode should remove the permanent sidebar layout.")

var top_bar := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar")
assert_true(top_bar != null, "Indoor mode should expose a dedicated indoor top bar.")

var map_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/Tools/MapButton") as Button
assert_true(map_button != null, "Indoor mode should expose a 구조도 button in the top bar.")

var bag_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/Tools/BagButton") as Button
assert_true(bag_button != null, "Indoor mode should expose a 가방 button in the top bar.")

var minimap_overlay := indoor_mode.get_node_or_null("MinimapOverlay") as Control
assert_true(minimap_overlay != null, "Indoor mode should expose a minimap overlay.")
assert_true(not minimap_overlay.visible, "Indoor mode should keep the minimap overlay hidden by default.")

var bag_sheet := indoor_mode.get_node_or_null("BagSheet") as Control
assert_true(bag_sheet != null, "Indoor mode should expose a bag bottom sheet.")
assert_true(not bag_sheet.visible, "Indoor mode should keep the bag sheet hidden by default.")
```

- [ ] **Step 2: Write the failing shared-HUD expectations**

Extend `game/tests/unit/test_run_controller_live_transition.gd` so it asserts indoor mode no longer leaves the shared HUD visible as a competing panel.

```gdscript
var hud := run_shell.get_node_or_null("HUD")
assert_true(hud != null, "Run shell should include a HUD node.")

await run_controller._transition_to_mode("indoor", "mart_01")
assert_true(
	not hud.visible or hud.modulate.a < 0.05,
	"Indoor mode should hide or fully minimize the shared HUD."
)

await run_controller._transition_to_mode("outdoor", "mart_01")
assert_true(hud.visible, "Outdoor mode should restore the shared HUD.")
```

- [ ] **Step 3: Run the two tests to verify failure**

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
  -s res://tests/unit/test_run_controller_live_transition.gd
```

Expected: both tests FAIL because the old sidebar is still mounted and the shared HUD is still visible indoors.

- [ ] **Step 4: Commit the failing-test checkpoint**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/tests/unit/test_indoor_mode.gd \
  game/tests/unit/test_run_controller_live_transition.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "test: define indoor ui restructure contract"
```

### Task 2: Rebuild IndoorMode Into a Reading-First Main Screen

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Replace the old scene layout**

Update `game/scenes/indoor/indoor_mode.tscn` so the main shell becomes single-column and reading-first.

```tscn
[node name="Panel" type="PanelContainer" parent="."]

[node name="Layout" type="VBoxContainer" parent="Panel"]

[node name="TopBar" type="HBoxContainer" parent="Panel/Layout"]
[node name="TitleLabel" type="Label" parent="Panel/Layout/TopBar"]
[node name="LocationLabel" type="Label" parent="Panel/Layout/TopBar"]
[node name="TimeLabel" type="Label" parent="Panel/Layout/TopBar"]
[node name="StatChips" type="HBoxContainer" parent="Panel/Layout/TopBar"]
[node name="Tools" type="HBoxContainer" parent="Panel/Layout/TopBar"]
[node name="MapButton" type="Button" parent="Panel/Layout/TopBar/Tools"]
[node name="BagButton" type="Button" parent="Panel/Layout/TopBar/Tools"]

[node name="ReadingCard" type="PanelContainer" parent="Panel/Layout"]
[node name="SummaryLabel" type="Label" parent="Panel/Layout/ReadingCard/VBox"]
[node name="ResultLabel" type="Label" parent="Panel/Layout/ReadingCard/VBox"]

[node name="ActionHeadingLabel" type="Label" parent="Panel/Layout"]
[node name="ActionButtons" type="VBoxContainer" parent="Panel/Layout"]
```

- [ ] **Step 2: Rebind `IndoorMode` to the new top bar and main reading surface**

Update `game/scripts/indoor/indoor_mode.gd` so node caching, refresh paths, and stat display follow the new shell.

```gdscript
func _cache_nodes() -> void:
	_title_label = get_node_or_null("Panel/Layout/TopBar/TitleLabel") as Label
	_location_label = get_node_or_null("Panel/Layout/TopBar/LocationLabel") as Label
	_time_label = get_node_or_null("Panel/Layout/TopBar/TimeLabel") as Label
	_summary_label = get_node_or_null("Panel/Layout/ReadingCard/VBox/SummaryLabel") as Label
	_result_label = get_node_or_null("Panel/Layout/ReadingCard/VBox/ResultLabel") as Label
	_action_buttons = get_node_or_null("Panel/Layout/ActionButtons") as VBoxContainer
```

Add a dedicated refresher for compact survival chips instead of relying on the shared HUD:

```gdscript
func _refresh_top_bar() -> void:
	_title_label.text = _director.get_event_title()
	_location_label.text = "위치: %s" % _director.get_current_zone_label()
	_time_label.text = "시각: %s" % _director.get_clock_label()
	_refresh_stat_chips()
```

- [ ] **Step 3: Add compact top-bar payload helpers to the director**

Update `game/scripts/indoor/indoor_director.gd` with presentation-only helpers so `IndoorMode` does not manually rebuild indoor status text.

```gdscript
func get_survival_chip_rows() -> Array[Dictionary]:
	return [
		{"id": "hunger", "label": "허기", "value": run_state.get_hunger_stage()},
		{"id": "thirst", "label": "갈증", "value": run_state.get_thirst_stage()},
		{"id": "health", "label": "체력", "value": run_state.get_health_stage()},
		{"id": "fatigue", "label": "피로", "value": run_state.get_fatigue_stage()},
	]
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
git -C /home/muhyeon_shin/packages/apocalypse commit -m "refactor: rebuild indoor screen around reading-first layout"
```

### Task 3: Move Minimap and Inventory Into Optional Overlays

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/indoor/indoor_minimap.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Add the minimap overlay and bag bottom sheet to the scene**

Update `game/scenes/indoor/indoor_mode.tscn` with optional surfaces instead of a permanent sidebar.

```tscn
[node name="MinimapOverlay" type="PanelContainer" parent="."]
visible = false

[node name="BagSheet" type="PanelContainer" parent="."]
visible = false
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Tabs" type="HBoxContainer" parent="BagSheet/VBox"]
[node name="CarriedTabButton" type="Button" parent="BagSheet/VBox/Tabs"]
[node name="EquippedTabButton" type="Button" parent="BagSheet/VBox/Tabs"]
```

- [ ] **Step 2: Rewrite the inventory/minimap interactions around toggles**

Update `game/scripts/indoor/indoor_mode.gd` so `구조도` opens/closes the overlay and `가방` opens/closes the bag sheet, while item selection still opens the existing action sheet inside the bag flow.

```gdscript
func _on_map_button_pressed() -> void:
	_minimap_overlay.visible = not _minimap_overlay.visible
	if _minimap_overlay.visible:
		_bag_sheet.visible = false


func _on_bag_button_pressed() -> void:
	_bag_sheet.visible = not _bag_sheet.visible
	if _bag_sheet.visible:
		_minimap_overlay.visible = false
```

Keep inventory and equipped gear in one surface:

```gdscript
func _refresh_bag_sheet() -> void:
	_inventory_status_label.text = _director.get_inventory_status_text()
	_refresh_inventory_items()
	_refresh_equipped_items()
```

- [ ] **Step 3: Make the minimap render cleanly in overlay mode**

Update `game/scripts/indoor/indoor_minimap.gd` only as needed so the overlay-sized control still centers the current node and clips properly.

```gdscript
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
```

Prefer keeping the discovery rules unchanged.

- [ ] **Step 4: Re-run the indoor-mode test**

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
  game/scripts/indoor/indoor_minimap.gd \
  game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: move indoor map and bag into optional surfaces"
```

### Task 4: Hide the Shared HUD During Indoor Play

**Files:**
- Modify: `game/scripts/run/hud_presenter.gd`
- Modify: `game/scripts/run/run_controller.gd`
- Modify: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Add a dedicated indoor-hidden presentation path**

Update `game/scripts/run/hud_presenter.gd` so indoor mode no longer competes with the indoor top bar.

```gdscript
func set_mode_presentation(mode_name: String) -> void:
	_cache_nodes()
	if _panel == null:
		return

	if mode_name == "indoor":
		visible = false
		return

	visible = true
	_panel.modulate = Color(1, 1, 1, 1.0)
```

- [ ] **Step 2: Keep the controller responsible for switching presentation boundaries**

Make sure `game/scripts/run/run_controller.gd` still flips HUD presentation at each transition and refreshes after the mode is mounted.

```gdscript
if _hud_presenter != null and _hud_presenter.has_method("set_mode_presentation"):
	_hud_presenter.set_mode_presentation(mode_name)
_refresh_hud()
```

This should stay in the transition path so the HUD state cannot drift out of sync.

- [ ] **Step 3: Re-run transition and smoke coverage**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_run_controller_live_transition.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 4: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scripts/run/hud_presenter.gd \
  game/scripts/run/run_controller.gd \
  game/tests/unit/test_run_controller_live_transition.gd \
  game/tests/smoke/test_first_playable_loop.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "refactor: keep indoor ui independent from shared hud"
```

### Task 5: Record the UI Migration and Run Final Regression

**Files:**
- Create: `docs/worklogs/2026-04-02-indoor-ui-restructure.md`
- Create: `docs/handoffs/2026-04-02-indoor-ui-restructure.md`
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Write the worklog**

Create `docs/worklogs/2026-04-02-indoor-ui-restructure.md` in Korean and capture:

```md
# 실내 UI 재구성 작업 기록

- 기존 상태: 실내 화면이 상시 HUD, 구조도, 소지품, 장착 장비를 동시에 노출하고 있었음
- 문제: 플레이어가 현재 위치 설명과 행동보다 주변 정보에 먼저 시선을 빼앗김
- 변경 방향: 실내를 대시보드가 아니라 읽기/선택 중심 화면으로 재구성
- 기대 효과: 모바일에서도 현재 위치, 현재 상황, 현재 행동만 빠르게 읽을 수 있음
```

- [ ] **Step 2: Write the handoff**

Create `docs/handoffs/2026-04-02-indoor-ui-restructure.md` with short checklist status and exact continuation points.

```md
# Indoor UI Restructure Handoff

- [x] reading-first indoor shell 적용
- [x] 구조도 오버레이 / 가방 시트 적용
- [x] 실내 shared HUD 비활성화
- [ ] 모바일 버튼 간격/폰트 세부 튜닝
- [ ] 실제 플레이 테스트 기반 문구 압축 검토
```

- [ ] **Step 3: Run the final focused regression**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `INDOOR_MODE_OK`
- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 4: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  docs/worklogs/2026-04-02-indoor-ui-restructure.md \
  docs/handoffs/2026-04-02-indoor-ui-restructure.md
git -C /home/muhyeon_shin/packages/apocalypse commit -m "docs: record indoor ui restructure work"
```
