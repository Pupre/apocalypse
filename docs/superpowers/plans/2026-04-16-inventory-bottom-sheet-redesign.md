# Inventory Bottom Sheet Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the shared bag UI so inventory browsing is list-first, item detail opens as a bottom sheet, and the same `SurvivalSheet` grammar is used for indoor and outdoor inventory interactions.

**Architecture:** Keep `SurvivalSheet` as the single shared inventory surface, but invert its visual hierarchy: dense scroll-first list as the base state, contextual bottom detail sheet for inspection and crafting, and a lighter codex presence inside the same shell. Replace outdoor’s separate `CraftingSheet` / `CodexPanel` bag interactions with the shared sheet rather than maintaining two inventory grammars.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, existing `SurvivalSheet`, `IndoorMode`, `RunController`, headless Godot tests

---

## File Map

### Create

- None required

### Modify

- `game/scenes/shared/survival_sheet.tscn`
- `game/scripts/ui/survival_sheet.gd`
- `game/scenes/run/run_shell.tscn`
- `game/scenes/run/hud.tscn`
- `game/scripts/run/hud_presenter.gd`
- `game/scripts/run/run_controller.gd`
- `game/tests/unit/test_survival_sheet.gd`
- `game/tests/unit/test_indoor_mode.gd`
- `game/tests/unit/test_run_controller_live_transition.gd`
- `game/tests/smoke/test_first_playable_loop.gd`
- `docs/INDEX.md`
- `docs/CURRENT_STATE.md`

### Responsibilities

- `game/scenes/shared/survival_sheet.tscn`
  - Rebuild the shared sheet layout into a list-dominant base with a separate bottom detail panel.
- `game/scripts/ui/survival_sheet.gd`
  - Introduce explicit browse vs detail state, keep contextual crafting intact, and expose a shared API usable from both indoor and outdoor.
- `game/scenes/run/hud.tscn`
  - Add an outdoor bag entry button in the shared HUD so the shared sheet can be opened outside buildings.
- `game/scripts/run/hud_presenter.gd`
  - Drive the new HUD bag affordance and keep its visibility aligned with mode presentation.
- `game/scripts/run/run_controller.gd`
  - Mount and open the shared `SurvivalSheet` from outdoor mode, then stop routing bag-like interactions through `CraftingSheet` / `CodexPanel`.
- tests
  - Lock list-first behavior, bottom detail behavior, preserved contextual crafting behavior, and outdoor access to the same sheet.

### Implementation Note

- The user explicitly prefers one final commit instead of per-task micro-commits. Execute task-by-task and verify continuously, but defer Git commit until the entire pass is finished.

---

### Task 1: Rewrite The Shared Sheet Tests Around List-First Behavior

**Files:**
- Modify: `game/tests/unit/test_survival_sheet.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Rewrite `test_survival_sheet.gd` around the new browse/detail contract**

Replace the central assertions in `game/tests/unit/test_survival_sheet.gd` so they require:

```gdscript
	survival_sheet.open_inventory()
	assert_eq(survival_sheet.get_active_tab_id(), "inventory", "SurvivalSheet should open on the inventory tab.")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_browse", "Opening inventory should enter browse mode.")
	assert_true(survival_sheet.has_method("is_detail_open"), "SurvivalSheet should expose a detail-open helper.")
	assert_true(not survival_sheet.is_detail_open(), "The bag should start in list-first browse mode with detail closed.")

	survival_sheet.select_inventory_item("newspaper")
	assert_true(survival_sheet.is_detail_open(), "Selecting an item should open the bottom detail sheet.")
```

Then keep the contextual crafting assertions, but make them operate through this list-first base state:

```gdscript
	assert_true(_button_texts(primary_actions).has("버린다"), "Detail should still expose normal item actions.")
	assert_true(_button_texts(secondary_actions).has("조합 시작"), "Crafting should still begin from a secondary detail action.")
```

- [ ] **Step 2: Extend `test_indoor_mode.gd` so indoor proves the redesigned shared bag surface**

In `game/tests/unit/test_indoor_mode.gd`, add assertions after opening the sheet:

```gdscript
	assert_true(survival_sheet.has_method("is_detail_open"), "Indoor SurvivalSheet should expose detail-open state.")
	assert_true(not survival_sheet.is_detail_open(), "Indoor bag should open to list-first browse mode by default.")

	survival_sheet.select_inventory_item("newspaper")
	assert_true(survival_sheet.is_detail_open(), "Selecting an item indoors should open the bottom detail sheet.")
```

- [ ] **Step 3: Extend the smoke test so outdoor must expose the same shared sheet**

In `game/tests/smoke/test_first_playable_loop.gd`, add assertions that `RunShell` now contains the shared sheet and an outdoor bag button path:

```gdscript
	var shared_survival_sheet := run_shell.get_node_or_null("SurvivalSheet")
	var hud_bag_button := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/BagButton") as Button
	if not assert_true(shared_survival_sheet != null, "Run shell should mount the shared SurvivalSheet for both indoor and outdoor."):
		bootstrap.free()
		return
	if not assert_true(hud_bag_button != null, "Outdoor HUD should expose a bag button."):
		bootstrap.free()
		return

	hud_bag_button.emit_signal("pressed")
	assert_true(shared_survival_sheet.visible, "Outdoor HUD bag button should open the shared SurvivalSheet.")
	assert_true(shared_survival_sheet.has_method("is_detail_open") and not shared_survival_sheet.is_detail_open(), "Outdoor bag should also default to list-first browse mode.")
```

- [ ] **Step 4: Run the focused tests and confirm the current implementation fails**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-bag-redesign-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-bag-redesign-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/apocalypse-bag-redesign-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `test_survival_sheet.gd` should fail because the current sheet always reserves detail space and has no explicit list-first detail-open state
- the smoke test should fail because outdoor still routes through `CraftingSheet` / `CodexPanel` instead of a shared bag surface

---

### Task 2: Rebuild `SurvivalSheet` Into A List-First Base With A Bottom Detail Layer

**Files:**
- Modify: `game/scenes/shared/survival_sheet.tscn`
- Modify: `game/scripts/ui/survival_sheet.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`

- [ ] **Step 1: Replace the permanent detail stack in `survival_sheet.tscn`**

In `game/scenes/shared/survival_sheet.tscn`, replace the current `InventoryPane` split with:

```text
Sheet/VBox
  Header
  Tabs
  CraftContextStrip
  InventoryPane
    InventoryScroll
      InventoryItems
    DetailSheet
      VBox
        ItemNameLabel
        ItemDescriptionLabel
        ItemEffectLabel
        ModeMessageLabel
        DetailActions
```

The key layout rules are:

- `InventoryScroll` gets the dominant vertical space
- `DetailSheet` starts hidden
- `DetailSheet` is anchored visually as the lower sheet rather than a permanent always-open card

- [ ] **Step 2: Add explicit detail-open state helpers in `survival_sheet.gd`**

In `game/scripts/ui/survival_sheet.gd`, add:

```gdscript
var _detail_open := false
var _detail_sheet: Control = null

func is_detail_open() -> bool:
	return _detail_open

func close_detail() -> void:
	_detail_open = false
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
		_sheet_state = STATE_INVENTORY_BROWSE
		_craft_base_item_id = ""
		_last_craft_feedback_text = ""
	_refresh_highlights()
	_render_inventory()
```

- [ ] **Step 3: Make item selection open detail instead of assuming permanent detail**

Update `select_inventory_item()` so it opens the detail sheet:

```gdscript
func select_inventory_item(item_id: String) -> void:
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT and item_id != _selected_item_id:
		_last_craft_feedback_text = ""
	_selected_item_id = item_id
	_detail_open = not item_id.is_empty()
	_render_inventory()
```

Also make `open_inventory()` reset to true list-first mode:

```gdscript
func open_inventory() -> void:
	visible = true
	_active_tab = "inventory"
	_sheet_state = STATE_INVENTORY_BROWSE
	_selected_item_id = ""
	_detail_open = false
	_last_craft_feedback_text = ""
	_refresh_highlights()
	_render()
```

- [ ] **Step 4: Keep crafting inside detail without restoring the old layout**

Adjust `begin_craft_mode()` and `confirm_craft()` so the detail sheet remains the crafting home:

```gdscript
func begin_craft_mode(item_id: String) -> void:
	if item_id.is_empty():
		return
	visible = true
	_active_tab = "inventory"
	_selected_item_id = item_id
	_craft_base_item_id = item_id
	_detail_open = true
	_last_craft_feedback_text = ""
	_sheet_state = STATE_INVENTORY_CRAFT_SELECT
	_refresh_highlights()
	_render()
```

After successful craft:

```gdscript
	if bool(outcome.get("ok", false)) and not crafted_item_id.is_empty() and String(outcome.get("result_type", "")) != "invalid":
		_selected_item_id = crafted_item_id
		_detail_open = true
		_sheet_state = STATE_INVENTORY_BROWSE
```

- [ ] **Step 5: Make `_render_inventory()` hide or show the detail sheet explicitly**

Update `_render_inventory()` to gate detail rendering:

```gdscript
	if _detail_sheet != null:
		_detail_sheet.visible = _detail_open and _active_tab == "inventory"

	if _detail_open:
		_render_item_detail()
	else:
		_clear_detail_labels_to_list_state()
```

Add a small helper:

```gdscript
func _clear_detail_labels_to_list_state() -> void:
	if _item_name_label != null:
		_item_name_label.text = ""
	if _item_description_label != null:
		_item_description_label.text = ""
	if _item_effect_label != null:
		_item_effect_label.text = ""
	if _mode_message_label != null:
		_mode_message_label.text = ""
	_clear_children(_primary_actions)
	_clear_children(_secondary_actions)
```

- [ ] **Step 6: Run the sheet test and make it pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-bag-redesign-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
```

Expected:

- `SURVIVAL_SHEET_OK`

---

### Task 3: Keep Indoor On The Shared Sheet While Updating Its Assumptions

**Files:**
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Make indoor open the redesigned sheet in list-first mode**

In `game/scripts/indoor/indoor_mode.gd`, keep `_survival_sheet.open_inventory()` in `_on_bag_button_pressed()`, but do not force-select any item immediately after opening.

- [ ] **Step 2: Ensure payload updates do not force detail open**

Where indoor pushes payload into the sheet, keep:

```gdscript
	_survival_sheet.set_inventory_payload(payload)
```

but do not add any side effect that selects an item or opens detail automatically.

- [ ] **Step 3: Run the indoor test and make it pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-bag-redesign-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected:

- `INDOOR_MODE_OK`

---

### Task 4: Replace Outdoor Bag-Like Interactions With The Shared `SurvivalSheet`

**Files:**
- Modify: `game/scenes/run/run_shell.tscn`
- Modify: `game/scenes/run/hud.tscn`
- Modify: `game/scripts/run/hud_presenter.gd`
- Modify: `game/scripts/run/run_controller.gd`
- Modify: `game/tests/unit/test_run_controller_live_transition.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Mount the shared sheet in `run_shell.tscn`**

In `game/scenes/run/run_shell.tscn`, replace the old shared crafting/codex pair:

```text
- CraftingSheet
- CodexPanel
+ SurvivalSheet
```

Use:

```tscn
[ext_resource type="PackedScene" path="res://scenes/shared/survival_sheet.tscn" id="4"]

[node name="SurvivalSheet" parent="." instance=ExtResource("4")]
```

- [ ] **Step 2: Add an outdoor bag button to the HUD**

In `game/scenes/run/hud.tscn`, add:

```tscn
[node name="BagButton" type="Button" parent="TopRibbon/Margin/Stack/HeaderRow"]
text = "가방"
```

Keep it in the outdoor header row so outdoor can open the shared sheet without inventing a second inventory UI.

- [ ] **Step 3: Cache the bag button in `hud_presenter.gd`**

Add:

```gdscript
var _bag_button: Button
```

and cache it with:

```gdscript
	_bag_button = get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/BagButton") as Button
```

No business logic belongs in the presenter yet; it only needs to expose the node consistently.

- [ ] **Step 4: Route the outdoor bag button through the shared sheet in `run_controller.gd`**

Replace `_crafting_sheet` / `_codex_panel` references with a shared sheet field:

```gdscript
var _survival_sheet: Node = null
var _pending_survival_sheet_tab := "inventory"
```

In `start_run()`:

```gdscript
	_survival_sheet = get_node_or_null("SurvivalSheet")
	if _survival_sheet != null and _survival_sheet.has_method("bind_run_state"):
		_survival_sheet.bind_run_state(run_state)
```

Connect the HUD bag button:

```gdscript
	var bag_button := _hud_presenter.get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/BagButton") as Button
	if bag_button != null and not bag_button.pressed.is_connected(Callable(self, "_on_bag_requested")):
		bag_button.pressed.connect(Callable(self, "_on_bag_requested"))
```

Add:

```gdscript
func _on_bag_requested() -> void:
	if _survival_sheet == null or not _survival_sheet.has_method("open_inventory"):
		return
	_survival_sheet.open_inventory()
```

- [ ] **Step 5: Remove outdoor dependence on the old shared crafting/codex surfaces**

Delete the old `_crafting_sheet` / `_codex_panel` open-close path once the smoke and live-transition tests are adjusted to the shared sheet.

The point is not to preserve both systems. Outdoor should converge on the same bag surface.

- [ ] **Step 6: Run the outdoor transition and smoke tests**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-bag-redesign-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/apocalypse-bag-redesign-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `FIRST_PLAYABLE_LOOP_OK`

---

### Task 5: Update Routing Docs To Reflect The New Active Inventory Direction

**Files:**
- Modify: `docs/INDEX.md`
- Modify: `docs/CURRENT_STATE.md`

- [ ] **Step 1: Add the new spec and plan to `docs/INDEX.md`**

Add to the top of the active lists:

```md
- [Inventory Bottom Sheet Redesign](superpowers/specs/2026-04-16-inventory-bottom-sheet-redesign.md)
```

and

```md
- [Inventory Bottom Sheet Redesign](superpowers/plans/2026-04-16-inventory-bottom-sheet-redesign.md)
```

- [ ] **Step 2: Update `docs/CURRENT_STATE.md`**

Reflect that the near-term inventory direction is now:

```md
- Redesign the shared bag UI around a list-first base state with contextual bottom detail instead of a permanently split inventory/detail layout.
```

- [ ] **Step 3: No code tests required**

Doc-only task. Manually verify the new entries point at the correct files.

---

## Spec Coverage Check

- `list-first base state` is covered by Task 1 and Task 2.
- `bottom detail sheet` is covered by Task 2.
- `crafting remains contextual inside detail` is covered by Task 2.
- `indoor and outdoor converge on the same bag grammar` is covered by Task 3 and Task 4.
- `routing docs stay current` is covered by Task 5.

No spec gaps remain for this pass.
