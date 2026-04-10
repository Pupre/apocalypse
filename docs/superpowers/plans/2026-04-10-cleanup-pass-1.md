# Cleanup Pass 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove indoor legacy bag UI paths that were superseded by `SurvivalSheet`, clean generated workspace junk out of the repo view, and tighten ignore rules so the same noise does not keep reappearing.

**Architecture:** Treat this as a narrow cleanup pass, not a redesign. Keep the current runtime behavior intact, but collapse indoor inventory/crafting down to the single `SurvivalSheet` path, then make the workspace baseline cleaner by ignoring and deleting obvious generated artifacts. Do not remove outdoor `CraftingSheet` / `CodexPanel` yet because that runtime path is still live.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, `.gitignore`, shell cleanup commands, existing headless Godot tests

---

## File Map

### Create

- `docs/superpowers/plans/2026-04-10-cleanup-pass-1.md`

### Modify

- `game/tests/unit/test_indoor_mode.gd`
- `game/scripts/indoor/indoor_mode.gd`
- `game/scenes/indoor/indoor_mode.tscn`
- `.gitignore`

### Delete Or Prune

- generated workspace artifacts under `game/.godot/`
- generated workspace artifacts under `game/builds/`
- generated workspace artifacts under `game/android/build/.gradle/`
- generated workspace artifacts under `game/android/build/assets/`
- generated workspace artifacts under `game/android/build/assetPacks/installTime/src/main/assets/`
- generated workspace artifacts under `game/android/build/build/`
- generated local config `game/android/build/local.properties`
- generated `*.uid` files in `game/`

### Regression-Only Test Targets

- `game/tests/unit/test_survival_sheet.gd`
- `game/tests/unit/test_run_controller_live_transition.gd`
- `game/tests/smoke/test_first_playable_loop.gd`

### Responsibilities

- `game/tests/unit/test_indoor_mode.gd`
  - Lock the cleanup contract by proving `SurvivalSheet` is the only indoor inventory surface.
- `game/scripts/indoor/indoor_mode.gd`
  - Remove `BagSheet` state, node caches, handlers, and refresh code.
- `game/scenes/indoor/indoor_mode.tscn`
  - Remove the `BagSheet` node tree so the scene no longer exposes the legacy UI.
- `.gitignore`
  - Ignore the generated artifacts that should not pollute the working tree.

---

### Task 1: Lock The Indoor Cleanup Contract

**Files:**
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Add an explicit assertion that the legacy `BagSheet` tree is gone**

In `game/tests/unit/test_indoor_mode.gd`, add this assertion right after the existing `SurvivalSheet` presence checks:

```gdscript
	var legacy_bag_sheet := indoor_mode.get_node_or_null("BagSheet") as Control
	if not assert_true(legacy_bag_sheet == null, "Indoor mode should remove the legacy BagSheet tree once SurvivalSheet is the only inventory surface."):
		indoor_mode.free()
		return
```

- [ ] **Step 2: Run the focused indoor-mode test and verify it fails before cleanup**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-cleanup-pass-1 /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected:

- `test_indoor_mode.gd` fails because `BagSheet` still exists in `indoor_mode.tscn`

- [ ] **Step 3: Re-run the same test after the runtime cleanup and verify it passes**

Use the same command from Step 2.

Expected:

- `INDOOR_MODE_OK`

---

### Task 2: Remove The Indoor `BagSheet` Legacy Path

**Files:**
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Delete the `BagSheet` node tree from the indoor scene**

In `game/scenes/indoor/indoor_mode.tscn`, remove the entire subtree that starts here:

```tscn
[node name="BagSheet" type="PanelContainer" parent="."]
```

That removal must include:

```tscn
[node name="VBox" type="VBoxContainer" parent="BagSheet"]
[node name="Header" type="HBoxContainer" parent="BagSheet/VBox"]
[node name="Tabs" type="HBoxContainer" parent="BagSheet/VBox"]
[node name="ContentRow" type="HBoxContainer" parent="BagSheet/VBox"]
[node name="InventoryColumn" type="VBoxContainer" parent="BagSheet/VBox/ContentRow"]
[node name="ItemDetailPanel" type="PanelContainer" parent="BagSheet/VBox/ContentRow"]
```

Leave `SurvivalSheet`, `MinimapOverlay`, and the main reading/action layout intact.

- [ ] **Step 2: Remove the `BagSheet`-only state from `indoor_mode.gd`**

Delete these legacy member variables from `game/scripts/indoor/indoor_mode.gd`:

```gdscript
var _bag_sheet: Control = null
var _bag_title_label: Label = null
var _bag_status_label: Label = null
var _bag_close_button: Button = null
var _carried_tab_button: Button = null
var _equipped_tab_button: Button = null
var _inventory_column: Control = null
var _inventory_items: VBoxContainer = null
var _item_sheet: Control = null
var _item_sheet_title: Label = null
var _item_sheet_scroll: ScrollContainer = null
var _item_sheet_description: Label = null
var _item_sheet_effect: Label = null
var _item_sheet_actions: HBoxContainer = null
var _active_bag_tab := "carried"
```

Also remove the matching node-cache assignments from `_cache_nodes()`:

```gdscript
	_bag_sheet = get_node_or_null("BagSheet") as Control
	_bag_title_label = get_node_or_null("BagSheet/VBox/Header/TitleLabel") as Label
	_bag_status_label = get_node_or_null("BagSheet/VBox/Header/StatusLabel") as Label
	_bag_close_button = get_node_or_null("BagSheet/VBox/Header/CloseButton") as Button
	_carried_tab_button = get_node_or_null("BagSheet/VBox/Tabs/CarriedTabButton") as Button
	_equipped_tab_button = get_node_or_null("BagSheet/VBox/Tabs/EquippedTabButton") as Button
	_inventory_column = get_node_or_null("BagSheet/VBox/ContentRow/InventoryColumn") as Control
	_inventory_items = get_node_or_null("BagSheet/VBox/ContentRow/InventoryColumn/InventoryScroll/InventoryItems") as VBoxContainer
	_item_sheet = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel") as Control
	_item_sheet_title = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/ItemNameLabel") as Label
	_item_sheet_scroll = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/DetailScroll") as ScrollContainer
	_item_sheet_description = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/DetailScroll/DetailContent/ItemDescriptionLabel") as Label
	_item_sheet_effect = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/DetailScroll/DetailContent/ItemEffectLabel") as Label
	_item_sheet_actions = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/ActionButtons") as HBoxContainer
```

- [ ] **Step 3: Remove the `BagSheet`-only behavior and collapse closures onto `SurvivalSheet`**

Delete these now-dead functions entirely:

```gdscript
func _refresh_bag_sheet() -> void:
	...

func _create_inventory_row(row: Dictionary) -> Control:
	...

func _create_equipped_row(row: Dictionary) -> Control:
	...

func _create_row_panel(row_name: String, stylebox: StyleBoxFlat = null) -> PanelContainer:
	...

func _create_row_box() -> VBoxContainer:
	...

func _create_empty_state_row(row_name: String, label_name: String, label_text: String) -> Control:
	...

func _row_panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	...

func _refresh_item_sheet() -> void:
	...

func _sync_item_detail_layout(detail_visible: bool) -> void:
	...

func _apply_tab_visual_state(button: Button, active: bool) -> void:
	...

func _tab_style(active: bool, hovered: bool = false) -> StyleBoxFlat:
	...

func _on_bag_close_pressed() -> void:
	...

func _on_carried_tab_pressed() -> void:
	...

func _on_equipped_tab_pressed() -> void:
	...

func _close_item_sheet_selection() -> void:
	...
```

Then simplify `_close_bag_sheet()` so it only closes the live sheet and clears chip detail:

```gdscript
func _close_bag_sheet() -> void:
	if _survival_sheet != null and _survival_sheet.visible and _survival_sheet.has_method("close_sheet"):
		_survival_sheet.close_sheet()
	_clear_stat_detail_selection()
```

And simplify `_on_stat_chip_pressed()` so it no longer checks the dead `BagSheet`:

```gdscript
func _on_stat_chip_pressed(chip_id: String) -> void:
	if _survival_sheet != null and _survival_sheet.visible:
		_close_bag_sheet()
	if _minimap_overlay != null and _minimap_overlay.visible:
		_minimap_overlay.visible = false
		_clear_stat_detail_selection()
	if _selected_chip_id == chip_id and _stat_detail_sheet != null and _stat_detail_sheet.visible:
		_clear_stat_detail_selection()
		return
	_selected_chip_id = chip_id
	_refresh_stat_detail_sheet()
```

Finally, remove the dead button bindings from `_bind_ui_buttons()`:

```gdscript
	if _bag_close_button != null and not _bag_close_button.pressed.is_connected(Callable(self, "_on_bag_close_pressed")):
		_bag_close_button.pressed.connect(Callable(self, "_on_bag_close_pressed"))
	if _carried_tab_button != null and not _carried_tab_button.pressed.is_connected(Callable(self, "_on_carried_tab_pressed")):
		_carried_tab_button.pressed.connect(Callable(self, "_on_carried_tab_pressed"))
	if _equipped_tab_button != null and not _equipped_tab_button.pressed.is_connected(Callable(self, "_on_equipped_tab_pressed")):
		_equipped_tab_button.pressed.connect(Callable(self, "_on_equipped_tab_pressed"))
```

- [ ] **Step 4: Run the focused indoor regression after the cleanup**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-cleanup-pass-1 /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected:

- `INDOOR_MODE_OK`

---

### Task 3: Ignore And Remove Generated Workspace Junk

**Files:**
- Modify: `.gitignore`
- Delete: `game/.godot/`
- Delete: `game/builds/`
- Delete: `game/android/build/.gradle/`
- Delete: `game/android/build/assets/`
- Delete: `game/android/build/assetPacks/installTime/src/main/assets/`
- Delete: `game/android/build/build/`
- Delete: `game/android/build/local.properties`
- Delete: `game/**/*.uid`

- [ ] **Step 1: Add generated-path rules to `.gitignore`**

Append these rules to `.gitignore`:

```gitignore
.codex/
.superpowers/
.playwright-mcp/
.gradle-android-build/
game/.godot/
game/builds/
game/android/build/.gradle/
game/android/build/assets/
game/android/build/assetPacks/installTime/src/main/assets/
game/android/build/build/
game/android/build/local.properties
*.uid
```

Do not ignore `game/android/build/AndroidManifest.xml`, `game/android/build/config.gradle`, or the tracked template files under `game/android/build/`.

- [ ] **Step 2: Delete the existing generated artifacts from the working tree**

Run these exact commands from the repo root:

```bash
find game -name '*.uid' -print -delete
rm -rf game/.godot
rm -rf game/builds
rm -rf game/android/build/.gradle
rm -rf game/android/build/assets
rm -rf game/android/build/assetPacks/installTime/src/main/assets
rm -rf game/android/build/build
rm -f game/android/build/local.properties
rm -rf .codex .superpowers .playwright-mcp .gradle-android-build
```

Expected:

- the generated directories disappear from `git status`
- tracked source files remain untouched

- [ ] **Step 3: Verify the ignore rules are catching the intended junk**

Run:

```bash
git status --short -- .gitignore game/.godot game/builds game/android/build .codex .superpowers .playwright-mcp .gradle-android-build
```

Expected:

- `.gitignore` is modified
- deleted generated paths no longer appear as untracked noise
- tracked Android template files still show normally if modified

---

### Task 4: Run Cleanup Regressions And Baseline Checks

**Files:**
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Run the focused runtime regressions**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-cleanup-pass-1 /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/apocalypse-cleanup-pass-1 /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-cleanup-pass-1 /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/apocalypse-cleanup-pass-1 /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `INDOOR_MODE_OK`
- `SURVIVAL_SHEET_OK`
- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 2: Sanity-check the remaining legacy runtime references**

Run:

```bash
rg -n "BagSheet" game/scripts game/scenes
rg -n "CraftingSheet|CodexPanel" game/scripts/run game/scenes/run
```

Expected:

- no `BagSheet` matches remain in runtime code or scenes
- `CraftingSheet` / `CodexPanel` still appear in `run_shell.tscn` and `run_controller.gd`, proving the pass did not prematurely remove the still-live outdoor path

---

## Self-Review

- Spec coverage:
  - legacy indoor `BagSheet` cleanup is covered by Task 1 and Task 2
  - ignore-rule hardening and generated cleanup are covered by Task 3
  - preserving the live outdoor crafting/codex path is checked in Task 4
- Placeholder scan:
  - No `TODO`, `TBD`, or undefined “appropriate cleanup” language remains
- Type consistency:
  - `SurvivalSheet` remains the live indoor surface throughout the plan
  - `BagSheet` is treated as dead everywhere in cleanup tasks
