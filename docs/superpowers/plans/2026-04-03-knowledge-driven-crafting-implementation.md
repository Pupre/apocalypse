# Knowledge-Driven Crafting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first working knowledge-driven crafting loop so the player can combine any two carried items, get `성공 / 실패 / 무효` outcomes, and permanently record those experiments in an item-centric codex across runs.

**Architecture:** Keep recipes and result types data-driven in JSON, route all crafting attempts through a single runtime resolver, and persist experiment records through a dedicated `KnowledgeCodex` autoload. UI should reuse one shared crafting sheet and one shared codex panel so indoor turn-based crafting and outdoor real-time crafting behave consistently while respecting different time rules.

**Tech Stack:** Godot 4, GDScript, JSON content files, autoload singletons, existing indoor/outdoor controllers, headless Godot tests

---

## File Structure

### Create

- `game/data/crafting_combinations.json`
  - First-pass 1:1 crafting definitions for success/failure outcomes, indoor minute cost, and result item ids.
- `game/scripts/autoload/knowledge_codex.gd`
  - Persistent meta journal for discovered items and crafting attempts across runs.
- `game/scripts/crafting/crafting_resolver.gd`
  - Pure runtime service that evaluates two-item crafting attempts and returns structured outcomes.
- `game/scenes/shared/crafting_sheet.tscn`
  - Shared two-slot crafting UI used by both indoor and outdoor flows.
- `game/scripts/ui/crafting_sheet.gd`
  - Shared controller for recipe attempts, slot selection, result copy, and callback wiring.
- `game/scenes/shared/knowledge_codex_panel.tscn`
  - Shared codex notebook panel showing known items and recorded experiments.
- `game/scripts/ui/knowledge_codex_panel.gd`
  - Shared controller for item list, per-item attempt rows, and result badges.
- `game/tests/unit/test_knowledge_codex.gd`
  - Persistence and journal structure coverage.
- `game/tests/unit/test_crafting_resolver.gd`
  - Crafting resolution coverage for success, failure, invalid, and indoor/outdoor time rules.

### Modify

- `game/project.godot`
  - Register `KnowledgeCodex` as an autoload.
- `game/data/items.json`
  - Add first-pass crafting materials and outputs such as `신문지`, `식용유`, `젖은 신문지`, `고농축 땔감`, `고무줄`.
- `game/scripts/autoload/content_library.gd`
  - Load and expose crafting combinations by canonical pair key.
- `game/scripts/run/inventory_model.gd`
  - Add helpers for counting and removing two selected items safely, including same-id pairs.
- `game/scripts/run/run_state.gd`
  - Add a single `attempt_craft(...)` entry point that mutates inventory, applies indoor time cost, and records codex results.
- `game/scripts/indoor/indoor_director.gd`
  - Expose crafting sheet data and codex panel data for indoor mode.
- `game/scripts/indoor/indoor_mode.gd`
  - Wire the shared crafting sheet and codex panel into the indoor inventory flow.
- `game/scenes/indoor/indoor_mode.tscn`
  - Add shared crafting/codex panel nodes and buttons without breaking the current clean indoor layout.
- `game/scripts/outdoor/outdoor_controller.gd`
  - Reuse the same crafting sheet and codex panel in outdoor mode without extra explicit time cost.
- `game/scenes/outdoor/outdoor_mode.tscn`
  - Add compact buttons to open inventory crafting and the codex while keeping outdoor readability.
- `game/tests/unit/test_content_library.gd`
  - Verify crafting data loads and canonical pair lookups work.
- `game/tests/unit/test_run_models.gd`
  - Verify `RunState` crafting entry point mutates inventory and time correctly.
- `game/tests/unit/test_indoor_mode.gd`
  - Verify indoor crafting sheet flow and codex access.
- `game/tests/unit/test_outdoor_controller.gd`
  - Verify outdoor crafting flow and no extra explicit craft-minute penalty.
- `game/tests/smoke/test_first_playable_loop.gd`
  - Verify the existing play loop still boots with the new shared panels attached.

---

### Task 1: Add Crafting Content and Loader Support

**Files:**
- Create: `game/data/crafting_combinations.json`
- Modify: `game/data/items.json`
- Modify: `game/scripts/autoload/content_library.gd`
- Test: `game/tests/unit/test_content_library.gd`

- [ ] **Step 1: Write the failing content-library expectations**

Add assertions like these to `game/tests/unit/test_content_library.gd`:

```gdscript
func test_loads_crafting_pairs() -> void:
	ContentLibrary.load_all()
	var combo := ContentLibrary.get_crafting_combination("newspaper", "cooking_oil")
	assert_eq(combo.get("result_type", ""), "success")
	assert_eq(String(combo.get("result_item_id", "")), "dense_fuel")

	var reverse_combo := ContentLibrary.get_crafting_combination("cooking_oil", "newspaper")
	assert_eq(reverse_combo.get("result_item_id", ""), "dense_fuel")

	var invalid_combo := ContentLibrary.get_crafting_combination("bottled_water", "rubber_band")
	assert_true(invalid_combo.is_empty())
```

- [ ] **Step 2: Run the content-library test to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_content_library.gd
```

Expected: FAIL because crafting content and lookup helpers do not exist yet.

- [ ] **Step 3: Implement the first-pass recipe dataset and loader**

Create `game/data/crafting_combinations.json` with seed rows like:

```json
[
  {
    "id": "newspaper__cooking_oil",
    "ingredients": ["newspaper", "cooking_oil"],
    "result_type": "success",
    "result_item_id": "dense_fuel",
    "indoor_minutes": 20
  },
  {
    "id": "newspaper__bottled_water",
    "ingredients": ["newspaper", "bottled_water"],
    "result_type": "failure",
    "result_item_id": "wet_newspaper",
    "indoor_minutes": 15
  }
]
```

Add the corresponding item rows to `game/data/items.json`:

```json
{
  "id": "newspaper",
  "name": "신문지",
  "bulk": 1,
  "description": "구겨진 지역 신문 뭉치다.",
  "category": "material"
}
```

Then extend `game/scripts/autoload/content_library.gd` with:

```gdscript
var crafting_combinations: Dictionary = {}

func get_crafting_combination(primary_item_id: String, secondary_item_id: String) -> Dictionary:
	return crafting_combinations.get(_crafting_pair_key(primary_item_id, secondary_item_id), {})

func _crafting_pair_key(primary_item_id: String, secondary_item_id: String) -> String:
	var ids := [primary_item_id, secondary_item_id]
	ids.sort()
	return "%s__%s" % ids
```

Load `res://data/crafting_combinations.json` in `load_all()` and index it by canonical sorted pair key.

- [ ] **Step 4: Re-run the content-library test**

Run the same command from Step 2.

Expected: `CONTENT_LIBRARY_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/data/crafting_combinations.json \
  game/data/items.json \
  game/scripts/autoload/content_library.gd \
  game/tests/unit/test_content_library.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add crafting content library support"
```

### Task 2: Add a Persistent Item-Centric Knowledge Codex

**Files:**
- Create: `game/scripts/autoload/knowledge_codex.gd`
- Modify: `game/project.godot`
- Test: `game/tests/unit/test_knowledge_codex.gd`

- [ ] **Step 1: Write the failing codex persistence test**

Create `game/tests/unit/test_knowledge_codex.gd` with expectations like:

```gdscript
func test_records_attempts_by_item_and_persists() -> void:
	var codex := KnowledgeCodex.new()
	codex.set_storage_path("user://knowledge_codex_test.json")
	codex.clear_all()

	codex.register_item("newspaper")
	codex.record_attempt("newspaper", "cooking_oil", {
		"result_type": "success",
		"result_item_id": "dense_fuel"
	})

	codex.save()

	var reloaded := KnowledgeCodex.new()
	reloaded.set_storage_path("user://knowledge_codex_test.json")
	reloaded.load_from_disk()

	var newspaper_entry := reloaded.get_item_entry("newspaper")
	assert_eq(newspaper_entry.get("item_id", ""), "newspaper")
	assert_eq(newspaper_entry.get("attempts", []).size(), 1)
```

- [ ] **Step 2: Run the codex test to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_knowledge_codex.gd
```

Expected: FAIL because the autoload and persistence model do not exist yet.

- [ ] **Step 3: Implement the autoloaded codex journal**

Create `game/scripts/autoload/knowledge_codex.gd` with a structure like:

```gdscript
extends Node

var storage_path := "user://knowledge_codex.json"
var discovered_items: Dictionary = {}

func register_item(item_id: String) -> void:
	if item_id.is_empty() or discovered_items.has(item_id):
		return
	discovered_items[item_id] = {
		"item_id": item_id,
		"attempts": []
	}

func record_attempt(primary_item_id: String, secondary_item_id: String, payload: Dictionary) -> void:
	register_item(primary_item_id)
	register_item(secondary_item_id)
	_append_attempt(primary_item_id, secondary_item_id, payload)
	_append_attempt(secondary_item_id, primary_item_id, payload)
	save()
```

Make the autoload save/load JSON from `user://knowledge_codex.json`, expose `get_item_rows()` and `get_item_entry(item_id)`, and add:

```ini
[autoload]
KnowledgeCodex="*res://scripts/autoload/knowledge_codex.gd"
```

to `game/project.godot`.

- [ ] **Step 4: Re-run the codex test**

Run the same command from Step 2.

Expected: `KNOWLEDGE_CODEX_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/project.godot \
  game/scripts/autoload/knowledge_codex.gd \
  game/tests/unit/test_knowledge_codex.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add persistent knowledge codex"
```

### Task 3: Resolve Crafting Attempts in RunState

**Files:**
- Create: `game/scripts/crafting/crafting_resolver.gd`
- Modify: `game/scripts/run/inventory_model.gd`
- Modify: `game/scripts/run/run_state.gd`
- Test: `game/tests/unit/test_crafting_resolver.gd`
- Test: `game/tests/unit/test_run_models.gd`

- [ ] **Step 1: Write the failing crafting runtime tests**

Create `game/tests/unit/test_crafting_resolver.gd` and extend `game/tests/unit/test_run_models.gd` with expectations like:

```gdscript
func test_success_failure_and_invalid_results() -> void:
	var resolver := CraftingResolver.new()
	var success_result := resolver.resolve_attempt("newspaper", "cooking_oil", ContentLibrary)
	assert_eq(success_result.get("result_type", ""), "success")
	assert_eq(success_result.get("result_item_id", ""), "dense_fuel")

	var failure_result := resolver.resolve_attempt("newspaper", "bottled_water", ContentLibrary)
	assert_eq(failure_result.get("result_type", ""), "failure")
	assert_eq(failure_result.get("result_item_id", ""), "wet_newspaper")

	var invalid_result := resolver.resolve_attempt("bottled_water", "rubber_band", ContentLibrary)
	assert_eq(invalid_result.get("result_type", ""), "invalid")
	assert_true(bool(invalid_result.get("returns_inputs", false)))
```

and:

```gdscript
func test_indoor_crafting_spends_time_but_outdoor_does_not() -> void:
	var state := RunState.from_survivor_config(_valid_survivor_config(), ContentLibrary, false)
	state.inventory.add_item(ContentLibrary.get_item("newspaper"))
	state.inventory.add_item(ContentLibrary.get_item("cooking_oil"))

	var before_minutes := state.clock.total_minutes
	var indoor_result := state.attempt_craft("newspaper", "cooking_oil", "indoor")
	assert_true(bool(indoor_result.get("ok", false)))
	assert_gt(state.clock.total_minutes, before_minutes)
```

- [ ] **Step 2: Run the crafting tests to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_crafting_resolver.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_run_models.gd
```

Expected: FAIL because no crafting resolver or run-state crafting entry point exists.

- [ ] **Step 3: Implement crafting resolution and inventory mutation**

Create `game/scripts/crafting/crafting_resolver.gd`:

```gdscript
extends RefCounted
class_name CraftingResolver

func resolve_attempt(primary_item_id: String, secondary_item_id: String, content_source) -> Dictionary:
	var combo := content_source.get_crafting_combination(primary_item_id, secondary_item_id)
	if combo.is_empty():
		return {
			"result_type": "invalid",
			"returns_inputs": true,
			"primary_item_id": primary_item_id,
			"secondary_item_id": secondary_item_id
		}
	return combo.duplicate(true)
```

Extend `InventoryModel` with helpers that can remove two chosen items safely, including same-id pairs:

```gdscript
func count_item(item_id: String) -> int:
	var count := 0
	for item in items:
		if String(item.get("id", "")) == item_id:
			count += 1
	return count
```

Extend `RunState` with:

```gdscript
func attempt_craft(primary_item_id: String, secondary_item_id: String, context: String = "indoor") -> Dictionary:
	# remove inputs
	# resolve result
	# add crafted output or return invalid inputs
	# spend indoor minutes only when context == "indoor"
	# record codex attempt through KnowledgeCodex
```

Record all three outcomes in `KnowledgeCodex`, and only spend explicit `indoor_minutes` when `context == "indoor"`.

- [ ] **Step 4: Re-run the crafting tests**

Run the same commands from Step 2.

Expected:

- `CRAFTING_RESOLVER_OK`
- `RUN_MODELS_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scripts/crafting/crafting_resolver.gd \
  game/scripts/run/inventory_model.gd \
  game/scripts/run/run_state.gd \
  game/tests/unit/test_crafting_resolver.gd \
  game/tests/unit/test_run_models.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add runtime crafting resolution"
```

### Task 4: Add a Shared Crafting Sheet and Indoor Crafting Flow

**Files:**
- Create: `game/scenes/shared/crafting_sheet.tscn`
- Create: `game/scripts/ui/crafting_sheet.gd`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Test: `game/tests/unit/test_indoor_director.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Write the failing indoor crafting-flow tests**

Extend indoor tests with expectations like:

```gdscript
func test_indoor_inventory_can_open_crafting_sheet() -> void:
	var screen := _build_indoor_mode()
	screen.press_inventory_button()
	screen.open_crafting_sheet()
	assert_true(screen.is_crafting_sheet_visible())

func test_indoor_crafting_updates_feedback_and_inventory() -> void:
	var screen := _build_indoor_mode_with_items(["newspaper", "cooking_oil"])
	screen.open_crafting_sheet()
	screen.select_primary_item("newspaper")
	screen.select_secondary_item("cooking_oil")
	screen.confirm_crafting()
	assert_true(screen.get_feedback_text().contains("고농축 땔감"))
```

- [ ] **Step 2: Run the indoor tests to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_director.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL because there is no indoor crafting UI path yet.

- [ ] **Step 3: Implement the shared crafting sheet and indoor wiring**

Create `game/scripts/ui/crafting_sheet.gd` with state like:

```gdscript
extends Control

signal craft_requested(primary_item_id: String, secondary_item_id: String)

var _primary_item_id := ""
var _secondary_item_id := ""

func configure(item_rows: Array[Dictionary], selected_primary: String = "", selected_secondary: String = "") -> void:
	# render grouped inventory choices into two slots
```

Update `indoor_director.gd` to expose:

```gdscript
func get_crafting_rows() -> Array[Dictionary]:
	return _build_crafting_rows_from_inventory()

func attempt_craft(primary_item_id: String, secondary_item_id: String) -> Dictionary:
	var result := _run_state.attempt_craft(primary_item_id, secondary_item_id, "indoor")
	state_changed.emit()
	return result
```

Wire `indoor_mode.gd` and `indoor_mode.tscn` so the existing bag sheet can open the shared crafting sheet, pick two carried items, submit a craft attempt, and show the returned result in the normal feedback area.

- [ ] **Step 4: Re-run the indoor tests**

Run the same commands from Step 2.

Expected:

- `INDOOR_DIRECTOR_OK`
- `INDOOR_MODE_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/shared/crafting_sheet.tscn \
  game/scripts/ui/crafting_sheet.gd \
  game/scripts/indoor/indoor_director.gd \
  game/scripts/indoor/indoor_mode.gd \
  game/scenes/indoor/indoor_mode.tscn \
  game/tests/unit/test_indoor_director.gd \
  game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add indoor crafting sheet flow"
```

### Task 5: Add Outdoor Crafting Access and the Persistent Codex UI

**Files:**
- Create: `game/scenes/shared/knowledge_codex_panel.tscn`
- Create: `game/scripts/ui/knowledge_codex_panel.gd`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/scenes/outdoor/outdoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Write the failing outdoor/codex UI expectations**

Add tests like:

```gdscript
func test_outdoor_crafting_has_no_extra_explicit_minute_cost() -> void:
	var controller := _build_controller_with_items(["newspaper", "cooking_oil"])
	var before_minutes := controller.run_state.clock.total_minutes
	controller.attempt_craft("newspaper", "cooking_oil")
	assert_eq(controller.run_state.clock.total_minutes, before_minutes)

func test_codex_panel_shows_attempts_for_discovered_item() -> void:
	var panel := _build_codex_panel()
	panel.configure(KnowledgeCodex.get_item_rows(), KnowledgeCodex.get_item_entry("newspaper"))
	assert_true(panel.get_attempt_labels().any(func(label): return label.contains("고농축 땔감")))
```

- [ ] **Step 2: Run the outdoor and smoke tests to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_outdoor_controller.gd
```

Then:

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

Expected: FAIL because outdoor mode does not expose crafting/codex access and the shared codex panel does not exist yet.

- [ ] **Step 3: Implement reusable codex UI and outdoor crafting access**

Create `game/scripts/ui/knowledge_codex_panel.gd` with a simple item-centric API:

```gdscript
extends Control

func configure(item_rows: Array[Dictionary], selected_entry: Dictionary) -> void:
	_render_item_rows(item_rows)
	_render_attempt_rows(selected_entry.get("attempts", []))
```

Update outdoor mode so it exposes compact buttons for:

- opening the shared crafting sheet
- opening the shared codex panel

When outdoor crafting calls `RunState.attempt_craft(..., "outdoor")`, keep inventory/result changes and codex recording, but do not add explicit indoor craft minutes.

Wire the same codex panel into indoor mode so the notebook is reachable from both spaces.

- [ ] **Step 4: Re-run the outdoor and smoke tests**

Run the same three commands from Step 2.

Expected:

- `OUTDOOR_CONTROLLER_OK`
- `INDOOR_MODE_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/shared/knowledge_codex_panel.tscn \
  game/scripts/ui/knowledge_codex_panel.gd \
  game/scripts/outdoor/outdoor_controller.gd \
  game/scenes/outdoor/outdoor_mode.tscn \
  game/scripts/indoor/indoor_mode.gd \
  game/scenes/indoor/indoor_mode.tscn \
  game/tests/unit/test_outdoor_controller.gd \
  game/tests/unit/test_indoor_mode.gd \
  game/tests/smoke/test_first_playable_loop.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add outdoor crafting and knowledge codex ui"
```

### Task 6: Run Full Regression and Tighten the Seed Knowledge Loop

**Files:**
- Modify: `game/tests/unit/test_content_library.gd`
- Modify: `game/tests/unit/test_knowledge_codex.gd`
- Modify: `game/tests/unit/test_crafting_resolver.gd`
- Modify: `game/tests/unit/test_run_models.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Add the last regression assertions**

Make sure the test suite covers:

- success/failure/invalid recording in codex
- indoor time cost vs outdoor no-extra-time rule
- failure result items can be carried and re-used later
- only discovered items appear in the codex list
- the first-playable loop still boots and transitions correctly

- [ ] **Step 2: Run the full regression suite**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
for test in \
  res://tests/unit/test_content_library.gd \
  res://tests/unit/test_knowledge_codex.gd \
  res://tests/unit/test_crafting_resolver.gd \
  res://tests/unit/test_run_models.gd \
  res://tests/unit/test_indoor_zone_graph.gd \
  res://tests/unit/test_indoor_director.gd \
  res://tests/unit/test_indoor_actions.gd \
  res://tests/unit/test_indoor_mode.gd \
  res://tests/unit/test_indoor_minimap.gd \
  res://tests/unit/test_outdoor_controller.gd \
  res://tests/unit/test_survivor_creator.gd \
  res://tests/unit/test_run_controller_live_transition.gd \
  res://tests/smoke/test_first_playable_loop.gd
do
  /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
    --headless \
    --path /home/muhyeon_shin/packages/apocalypse/game \
    -s "$test" || exit 1
done
```

Expected: all tests pass, including the new `KNOWLEDGE_CODEX_OK` and `CRAFTING_RESOLVER_OK` markers.

- [ ] **Step 3: Tighten any brittle copy or state expectations**

If any test still relies on fragile text ordering, replace it with state-driven checks like:

```gdscript
assert_eq(screen.get_selected_inventory_sheet().get("title", ""), "고농축 땔감")
assert_true(KnowledgeCodex.get_item_entry("newspaper").get("attempts", []).size() >= 1)
```

Do not relax core behavioral assertions.

- [ ] **Step 4: Re-run the full regression suite**

Run the same loop from Step 2.

Expected: full pass, stable enough for the next system/story layer.

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/tests/unit/test_content_library.gd \
  game/tests/unit/test_knowledge_codex.gd \
  game/tests/unit/test_crafting_resolver.gd \
  game/tests/unit/test_run_models.gd \
  game/tests/unit/test_indoor_mode.gd \
  game/tests/unit/test_outdoor_controller.gd \
  game/tests/smoke/test_first_playable_loop.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "test: stabilize knowledge crafting regression coverage"
```

## Self-Review

- **Spec coverage:**  
  - 1:1 crafting, anywhere crafting, and indoor/outdoor time split are covered by Tasks 1, 3, 4, and 5.  
  - `성공 / 실패 / 무효` outcomes and failed-item reuse are covered by Tasks 1, 3, and 6.  
  - Item-centric permanent codex is covered by Tasks 2 and 5.  
  - Environment-observation-driven philosophy is preserved by keeping this plan to direct crafting/codex plumbing only; no auto-answer environment logging is introduced.
- **Placeholder scan:**  
  - No `TBD`, `TODO`, or “implement later” markers remain.  
  - Each task includes named files, runnable commands, and explicit expected outcomes.
- **Type consistency:**  
  - Pair lookup uses `get_crafting_combination(...)` throughout.  
  - Runtime crafting entry point uses `RunState.attempt_craft(...)` throughout.  
  - Persistent journal remains `KnowledgeCodex` in project config, tests, and UI tasks.
