# Crafting Codex And Lighter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a category-based crafting codex that starts as `???`, unlocks recipes through successful crafting and readable knowledge items, and make `lighter` a charge-based required tool for the first heat-producing recipe slice.

**Architecture:** Keep the current shared crafting sheet and data-driven crafting pipeline. Extend `crafting_combinations.json` with codex and tool metadata, store discovered recipe state directly in `RunState`, expose readable knowledge items through the existing indoor inventory sheet, and render the codex as a second tab inside the shared crafting sheet. Generalize charge support in item instances, but only activate it for `lighter` in this first pass.

**Tech Stack:** Godot 4.4.1, GDScript, JSON content data, existing `ContentLibrary` / `RunState` / `CraftingResolver` / `IndoorDirector` / shared `CraftingSheet`, headless Godot tests

---

## File Map

### Create

- `game/tests/unit/test_crafting_codex.gd`

### Modify

- `game/data/items.json`
- `game/data/crafting_combinations.json`
- `game/data/events/indoor/mart_01.json`
- `game/data/events/indoor/office_01.json`
- `game/scripts/autoload/content_library.gd`
- `game/scripts/crafting/crafting_resolver.gd`
- `game/scripts/indoor/indoor_director.gd`
- `game/scripts/run/run_state.gd`
- `game/scripts/ui/crafting_sheet.gd`
- `game/scenes/shared/crafting_sheet.tscn`
- `game/tests/unit/test_content_library.gd`
- `game/tests/unit/test_run_models.gd`
- `game/tests/unit/test_shared_crafting_sheet.gd`
- `game/tests/smoke/test_first_playable_loop.gd`

### Responsibilities

- `items.json`
  - Add readable note items
  - Add lighter charge metadata
- `crafting_combinations.json`
  - Add codex categories
  - Add required tool ids and charge costs
- `content_library.gd`
  - Normalize readable / charge / codex metadata
- `crafting_resolver.gd`
  - Validate required tools and surface readable failure messages
- `run_state.gd`
  - Own known recipe ids, read knowledge item ids, and lighter charge mutation
- `indoor_director.gd`
  - Expose `읽는다` for readable items and better lighter detail text
- `crafting_sheet.tscn` / `crafting_sheet.gd`
  - Add `직접 조합 / 조합 도감` tabs and codex rendering
- tests
  - Lock data shape, runtime unlocking, tool gating, UI rendering, and smoke flow

---

### Task 1: Lock The Codex And Lighter Contract

**Files:**
- Create: `game/tests/unit/test_crafting_codex.gd`
- Modify: `game/tests/unit/test_content_library.gd`
- Modify: `game/scripts/autoload/content_library.gd`
- Test: `game/tests/unit/test_content_library.gd`
- Test: `game/tests/unit/test_crafting_codex.gd`

- [ ] **Step 1: Write the failing codex data-contract test**

Create `game/tests/unit/test_crafting_codex.gd` with a minimal contract like:

```gdscript
extends "res://tests/support/test_case.gd"


const RECIPE_IDS := [
	"newspaper__cooking_oil",
	"steel_food_can__dense_fuel",
	"bottled_water__can_stove",
	"hot_water__tea_bag",
]

const KNOWLEDGE_ITEM_IDS := [
	"improvised_heat_note_01",
	"field_hygiene_note_01",
]


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be present for crafting codex tests."):
		return

	var lighter := content_library.get_item("lighter")
	assert_true(not lighter.is_empty(), "Lighter should still exist.")
	assert_eq(int(lighter.get("charges_max", 0)), 5, "Lighter should expose charges_max for tool gating.")

	for item_id in KNOWLEDGE_ITEM_IDS:
		var item_row := content_library.get_item(item_id)
		assert_true(not item_row.is_empty(), "Knowledge item '%s' should load." % item_id)
		assert_true(bool(item_row.get("readable", false)), "Knowledge item '%s' should be readable." % item_id)
		assert_true(Array(item_row.get("knowledge_recipe_ids", [])).size() > 0, "Knowledge item '%s' should unlock recipes." % item_id)

	for recipe_id in RECIPE_IDS:
		var recipe := _find_recipe_by_id(content_library, recipe_id)
		assert_true(not recipe.is_empty(), "Recipe '%s' should load." % recipe_id)
		assert_true(not String(recipe.get("codex_category", "")).is_empty(), "Recipe '%s' should expose codex_category." % recipe_id)

	var hot_water_recipe := _find_recipe_by_id(content_library, "bottled_water__can_stove")
	assert_eq(Array(hot_water_recipe.get("required_tool_ids", [])), ["lighter"], "Heating water should require a lighter.")
	assert_eq(int(Dictionary(hot_water_recipe.get("tool_charge_costs", {})).get("lighter", 0)), 1, "Heating water should cost one lighter charge.")

	pass_test("CRAFTING_CODEX_OK")


func _find_recipe_by_id(content_library, recipe_id: String) -> Dictionary:
	for row in content_library.crafting_combinations.values():
		if String((row as Dictionary).get("id", "")) == recipe_id:
			return row
	return {}
```

- [ ] **Step 2: Extend the content-library regression test**

Add checks to `game/tests/unit/test_content_library.gd` for:

```gdscript
	_assert_item_contract("improvised_heat_note_01")
	_assert_item_contract("field_hygiene_note_01")
	assert_true(bool(items["improvised_heat_note_01"].get("readable", false)), "Knowledge notes should expose readable=true.")
	assert_eq(int(items["lighter"].get("charges_max", 0)), 5, "Lighter should expose a default charge capacity.")
```

Also add one representative recipe assertion:

```gdscript
	var hot_water_recipe := _find_recipe_by_id("bottled_water__can_stove")
	assert_eq(Array(hot_water_recipe.get("required_tool_ids", [])), ["lighter"], "Heat recipes should expose required lighter tooling.")
```

- [ ] **Step 3: Run the two tests and verify they fail**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/unit/test_content_library.gd
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/unit/test_crafting_codex.gd
```

Expected: FAIL because codex metadata, readable notes, and lighter charge fields do not exist yet.

- [ ] **Step 4: Normalize the new metadata in `ContentLibrary`**

Extend `_normalize_item_row()` in `game/scripts/autoload/content_library.gd` so it preserves these optional fields with safe defaults:

```gdscript
	row["readable"] = bool(row.get("readable", false))
	row["knowledge_title"] = String(row.get("knowledge_title", ""))
	var knowledge_recipe_ids_variant: Variant = row.get("knowledge_recipe_ids", [])
	row["knowledge_recipe_ids"] = (knowledge_recipe_ids_variant as Array).duplicate(true) if typeof(knowledge_recipe_ids_variant) == TYPE_ARRAY else []
	if int(row.get("charges_max", 0)) > 0 and not row.has("charge_label"):
		row["charge_label"] = "잔량"
```

Also normalize recipe rows in `_load_crafting_combinations(...)`:

```gdscript
	normalized_row["codex_category"] = String(normalized_row.get("codex_category", ""))
	var required_tool_ids_variant: Variant = normalized_row.get("required_tool_ids", [])
	normalized_row["required_tool_ids"] = (required_tool_ids_variant as Array).duplicate(true) if typeof(required_tool_ids_variant) == TYPE_ARRAY else []
	var tool_charge_costs_variant: Variant = normalized_row.get("tool_charge_costs", {})
	normalized_row["tool_charge_costs"] = (tool_charge_costs_variant as Dictionary).duplicate(true) if typeof(tool_charge_costs_variant) == TYPE_DICTIONARY else {}
```

- [ ] **Step 5: Re-run the two tests and verify they pass**

Run the same two commands again.

Expected:

- `CONTENT_LIBRARY_OK`
- `CRAFTING_CODEX_OK`

- [ ] **Step 6: Commit**

```bash
git add game/scripts/autoload/content_library.gd game/tests/unit/test_content_library.gd game/tests/unit/test_crafting_codex.gd
git commit -m "test: lock crafting codex and lighter contract"
```

---

### Task 2: Add Run-State Knowledge Unlocking And Lighter Charges

**Files:**
- Modify: `game/data/items.json`
- Modify: `game/data/crafting_combinations.json`
- Modify: `game/scripts/crafting/crafting_resolver.gd`
- Modify: `game/scripts/run/run_state.gd`
- Modify: `game/tests/unit/test_run_models.gd`
- Modify: `game/tests/unit/test_crafting_codex.gd`
- Test: `game/tests/unit/test_run_models.gd`
- Test: `game/tests/unit/test_crafting_codex.gd`

- [ ] **Step 1: Write the failing runtime expectations**

Add these expectations to `game/tests/unit/test_run_models.gd`:

```gdscript
	assert_true(run_state.known_recipe_ids.is_empty(), "A fresh run should start with no known recipes.")
	assert_true(run_state.read_knowledge_item_ids.is_empty(), "A fresh run should start with no read knowledge items.")

	assert_true(run_state.inventory.add_item({"id": "lighter", "name": "라이터", "bulk": 1, "charges_current": 5, "charges_max": 5}), "Runtime tests should hold a lighter.")
	assert_true(run_state.inventory.add_item({"id": "bottled_water", "name": "생수", "bulk": 1}), "Runtime tests should hold bottled water.")
	assert_true(run_state.inventory.add_item({"id": "can_stove", "name": "깡통 화로", "bulk": 1}), "Runtime tests should hold a can stove.")
	var heated_outcome := run_state.attempt_craft("bottled_water", "can_stove", "indoor")
	assert_eq(String(heated_outcome.get("result_item_id", "")), "hot_water", "Heating water should still succeed.")
	assert_true(run_state.known_recipe_ids.has("bottled_water__can_stove"), "Successful crafting should unlock the recipe in the codex.")
	assert_eq(run_state.get_tool_charges("lighter"), 4, "Heating water should spend one lighter charge.")

	var second_state = run_state_script.from_survivor_config({...}, live_content_library)
	assert_true(second_state.read_knowledge_item("improvised_heat_note_01"), "Knowledge notes should be readable.")
	assert_true(second_state.known_recipe_ids.has("newspaper__cooking_oil"), "Reading a heat note should unlock its mapped recipes.")
	assert_true(second_state.read_knowledge_item_ids.has("improvised_heat_note_01"), "Reading should mark the note as already read.")
	assert_true(not second_state.read_knowledge_item("improvised_heat_note_01"), "Reading the same note twice should not unlock anything new.")
```

- [ ] **Step 2: Run the runtime tests and verify they fail**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/unit/test_run_models.gd
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/unit/test_crafting_codex.gd
```

Expected: FAIL because codex state, readable notes, and lighter charge mutation do not exist yet.

- [ ] **Step 3: Add the first readable notes and lighter charge metadata**

Update `game/data/items.json` with:

- `lighter`
  - `charges_max: 5`
  - `charge_label: "잔량"`
  - `item_tags` including `ignition_tool`
- three readable note items:
  - `improvised_heat_note_01`
  - `survival_cooking_note_01`
  - `field_hygiene_note_01`

Each note row should include:

```json
{
  "id": "improvised_heat_note_01",
  "name": "즉석 보온 메모",
  "bulk": 1,
  "description": "급히 적어 둔 불씨와 보온 도구 메모다.",
  "usage_hint": "읽으면 몇 가지 초반 보온 조합을 익힐 수 있다.",
  "cold_hint": "추위에서 바로 써먹을 수 있는 기초 불/열 지식을 담고 있다.",
  "category": "knowledge",
  "item_tags": ["knowledge", "readable"],
  "readable": true,
  "knowledge_title": "즉석 보온 메모",
  "knowledge_recipe_ids": ["newspaper__cooking_oil", "steel_food_can__dense_fuel", "bottled_water__can_stove"]
}
```

- [ ] **Step 4: Add codex and tool fields to representative recipes**

Update `game/data/crafting_combinations.json` so the first-pass codex slice has:

- `codex_category`
- `required_tool_ids`
- `tool_charge_costs`

Use this rule:

- assembly recipes do **not** require lighter
  - `newspaper__cooking_oil`
  - `steel_food_can__dense_fuel`
- heating recipes do require lighter
  - `bottled_water__can_stove`
  - `bottled_water__candle_lantern`
  - `bottled_water__shielded_candle`

Example shape:

```json
{
  "id": "bottled_water__can_stove",
  "ingredients": ["bottled_water", "can_stove"],
  "codex_category": "food_drink",
  "required_tool_ids": ["lighter"],
  "tool_charge_costs": {"lighter": 1}
}
```

- [ ] **Step 5: Add run-state codex and lighter charge logic**

In `game/scripts/run/run_state.gd`:

- add state:

```gdscript
var known_recipe_ids: Dictionary = {}
var read_knowledge_item_ids: Dictionary = {}
```

- initialize them in `from_survivor_config(...)`
- add helpers:

```gdscript
func knows_recipe(recipe_id: String) -> bool:
	return known_recipe_ids.has(recipe_id)

func unlock_recipe(recipe_id: String) -> void:
	if not recipe_id.is_empty():
		known_recipe_ids[recipe_id] = true

func get_tool_charges(item_id: String) -> int:
	# find first matching inventory item and return charges_current

func read_knowledge_item(item_id: String) -> bool:
	# reject repeats
	# load item definition
	# unlock all knowledge_recipe_ids
	# mark read_knowledge_item_ids[item_id] = true
	# return true only when new knowledge was added
```

Also update `attempt_craft(...)` so it:

- checks required tools before ingredient removal
- spends tool charges on success
- unlocks `recipe_id` on success

- [ ] **Step 6: Make `CraftingResolver` surface tool errors cleanly**

In `game/scripts/crafting/crafting_resolver.gd`, keep recipe lookup pure but include these fields in the returned outcome:

```gdscript
"required_tool_ids": required_tool_ids,
"tool_charge_costs": tool_charge_costs,
```

Do not mutate charges here. Mutation stays in `RunState`.

- [ ] **Step 7: Re-run the runtime tests and verify they pass**

Run the same two commands again.

Expected:

- `RUN_MODELS_OK`
- `CRAFTING_CODEX_OK`

- [ ] **Step 8: Commit**

```bash
git add game/data/items.json game/data/crafting_combinations.json game/scripts/crafting/crafting_resolver.gd game/scripts/run/run_state.gd game/tests/unit/test_run_models.gd game/tests/unit/test_crafting_codex.gd
git commit -m "feat: add recipe knowledge and lighter tool charges"
```

---

### Task 3: Expose Reading Actions And Better Item Detail

**Files:**
- Modify: `game/scripts/indoor/indoor_director.gd`
- Modify: `game/tests/unit/test_indoor_director.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_indoor_director.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Add the failing indoor knowledge-item expectations**

Extend `game/tests/unit/test_indoor_director.gd` so a readable note item:

- exposes a `읽는다` action in the inventory sheet
- keeps `버린다` and `닫기`
- returns a readable “already known” message on repeat

Add expectations like:

```gdscript
	assert_true(director.apply_action("inspect_inventory_improvised_heat_note_01"), "Director should allow selecting a knowledge note.")
	var selected_sheet := director.get_selected_inventory_sheet()
	assert_true(_action_ids(selected_sheet.get("actions", [])).has("read_inventory_improvised_heat_note_01"), "Knowledge notes should expose a read action.")
	assert_true(director.apply_action("read_inventory_improvised_heat_note_01"), "Director should allow reading the knowledge note.")
	assert_true(run_state.known_recipe_ids.has("newspaper__cooking_oil"), "Reading should unlock mapped recipes.")
	assert_true(director.apply_action("read_inventory_improvised_heat_note_01"), "Repeat reading should still resolve as an action.")
	assert_true(director.get_feedback_message().find("이미") != -1, "Repeat reading should surface an already-known message.")
```

- [ ] **Step 2: Add the failing lighter detail expectations**

Extend `game/tests/unit/test_indoor_mode.gd` so a selected lighter item shows:

```gdscript
	assert_true(item_sheet_effect.text.find("잔량 5/5") != -1, "Lighter detail should show current remaining charges.")
	assert_true(item_sheet_effect.text.find("#ignition_tool") != -1, "Lighter detail should expose ignition tool tags.")
```

- [ ] **Step 3: Run the indoor tests and verify they fail**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/unit/test_indoor_director.gd
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL because readable notes and lighter charge detail are not surfaced yet.

- [ ] **Step 4: Add read actions in `IndoorDirector`**

Extend `_inventory_sheet_actions(...)` in `game/scripts/indoor/indoor_director.gd`:

```gdscript
	if bool(item_data.get("readable", false)):
		actions.append({
			"id": "read_inventory_%s" % item_id,
			"label": "읽는다",
		})
```

Handle `read_inventory_` in `apply_action(...)`:

- call `_run_state.read_knowledge_item(item_id)`
- on first read:
  - `"%s에서 새로운 조합법을 익혔다."`
- on repeat:
  - `"%s는 이미 아는 내용이다."`
- keep the item in inventory
- refresh selection and feedback

- [ ] **Step 5: Surface lighter charge text**

Extend `_item_effect_text(...)` in `game/scripts/indoor/indoor_director.gd`:

```gdscript
	var charges_max := int(item_data.get("charges_max", 0))
	var charges_current := int(item_data.get("charges_current", charges_max))
	if charges_max > 0:
		var charge_label := String(item_data.get("charge_label", "잔량"))
		parts.append("%s %d/%d" % [charge_label, charges_current, charges_max])
```

- [ ] **Step 6: Re-run the indoor tests and verify they pass**

Run the same two commands again.

Expected:

- `INDOOR_DIRECTOR_OK`
- `INDOOR_MODE_OK`

- [ ] **Step 7: Commit**

```bash
git add game/scripts/indoor/indoor_director.gd game/tests/unit/test_indoor_director.gd game/tests/unit/test_indoor_mode.gd
git commit -m "feat: add readable note actions and lighter detail"
```

---

### Task 4: Add The Codex Tab To The Shared Crafting Sheet

**Files:**
- Modify: `game/scenes/shared/crafting_sheet.tscn`
- Modify: `game/scripts/ui/crafting_sheet.gd`
- Modify: `game/tests/unit/test_shared_crafting_sheet.gd`
- Test: `game/tests/unit/test_shared_crafting_sheet.gd`

- [ ] **Step 1: Add failing codex-tab UI expectations**

Extend `game/tests/unit/test_shared_crafting_sheet.gd` so the shared sheet must expose:

- a `DirectTabButton`
- a `CodexTabButton`
- category labels like `불 / 열`
- `???` rows before discovery

Also add one positive discovered-recipe expectation after seeding `known_recipe_ids`:

```gdscript
	assert_true(_find_button_by_text(sheet, "직접 조합") != null, "Crafting sheet should expose a direct-crafting tab.")
	assert_true(_find_button_by_text(sheet, "조합 도감") != null, "Crafting sheet should expose a codex tab.")
	assert_true(_find_label_by_text(sheet, "???") != null, "Unknown recipes should render as ??? in the codex.")
```

- [ ] **Step 2: Run the shared-sheet test and verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/unit/test_shared_crafting_sheet.gd
```

Expected: FAIL because the crafting sheet has no codex tab yet.

- [ ] **Step 3: Add tabbed crafting-sheet structure**

Update `game/scenes/shared/crafting_sheet.tscn` to include:

- `Tabs`
  - `DirectTabButton`
  - `CodexTabButton`
- `DirectPane`
  - current slot and inventory controls
- `CodexPane`
  - category list / scroll

Keep one scene instance shared by indoor and outdoor.

- [ ] **Step 4: Implement codex rendering in `crafting_sheet.gd`**

Add state:

```gdscript
var _active_tab := "direct"
```

Add helpers:

```gdscript
func _all_codex_rows() -> Dictionary:
	# group all recipes by codex_category

func _known_recipe_ids() -> Dictionary:
	return run_state.known_recipe_ids if run_state != null else {}

func _render_codex() -> void:
	# category heading: "불 / 열 3/18"
	# unknown row: "???"
	# known row: "신문지 + 식용유 -> 고농축 땔감"
	# detail row: result_text + conditions
```

Condition rendering should include:

- `실내 전용`
- `도구: 라이터`

- [ ] **Step 5: Re-run the shared-sheet test and verify it passes**

Run the same command again.

Expected: `SHARED_CRAFTING_SHEET_OK`

- [ ] **Step 6: Commit**

```bash
git add game/scenes/shared/crafting_sheet.tscn game/scripts/ui/crafting_sheet.gd game/tests/unit/test_shared_crafting_sheet.gd
git commit -m "feat: add crafting codex tab to the shared sheet"
```

---

### Task 5: Integrate Knowledge Notes Into Loot And Smoke Coverage

**Files:**
- Modify: `game/data/events/indoor/mart_01.json`
- Modify: `game/data/events/indoor/office_01.json`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_indoor_loot_tables.gd`

- [ ] **Step 1: Add failing smoke expectations for reading and codex unlock**

Extend `game/tests/smoke/test_first_playable_loop.gd` with a small live loop:

- find one knowledge note in a reachable loot table
- take it
- read it
- open the crafting sheet
- switch to codex tab
- confirm at least one previously hidden recipe is now revealed

Also add a lighter-gated check:

```gdscript
	assert_true(run_shell.run_state.inventory.add_item(content_library.get_item("lighter")), "Smoke should seed a lighter.")
	assert_true(run_shell.run_state.read_knowledge_item("improvised_heat_note_01"), "Smoke should unlock note-backed recipes.")
	assert_true(run_shell.run_state.knows_recipe("bottled_water__can_stove"), "Smoke should reveal the heated-water recipe after reading.")
```

- [ ] **Step 2: Run the smoke test and verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/smoke/test_first_playable_loop.gd
```

Expected: FAIL because notes are not placed, codex UI is absent, or lighter gating is not wired yet.

- [ ] **Step 3: Place first-pass notes in building loot tables**

Update:

- `game/data/events/indoor/mart_01.json`
  - add one cooking / heat note to office-like or back-room loot
- `game/data/events/indoor/office_01.json`
  - add one repair or hygiene note to records / desks

Do not replace guaranteed progression items. Add notes as weighted identity flavor loot.

- [ ] **Step 4: Re-run smoke and loot-table tests**

Run:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/unit/test_indoor_loot_tables.gd
XDG_DATA_HOME=/tmp/codex-godot-home /home/smh3223/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path "/mnt/c/Toy Projects/apocalypse/game" -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `INDOOR_LOOT_TABLES_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 5: Commit**

```bash
git add game/data/events/indoor/mart_01.json game/data/events/indoor/office_01.json game/tests/smoke/test_first_playable_loop.gd
git commit -m "test: cover note-driven codex unlocks in smoke flow"
```

---

## Self-Review

- Spec coverage:
  - codex master list with `???`: covered by Task 4
  - success-based unlock: covered by Task 2
  - book/note-based unlock: covered by Tasks 2, 3, and 5
  - lighter charges and tool gating: covered by Task 2 and Task 3
  - category-based presentation: covered by Task 4
  - first-pass loot integration: covered by Task 5
- Placeholder scan:
  - no `TBD`, `TODO`, or deferred pseudo-steps remain
- Type consistency:
  - runtime state uses `known_recipe_ids`, `read_knowledge_item_ids`, and `get_tool_charges(...)` consistently
  - recipe metadata uses `codex_category`, `required_tool_ids`, and `tool_charge_costs` consistently
