# Mart Indoor Content Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current one-card mart indoor prototype into a connected, multi-zone indoor exploration flow with gated back-of-house progression, indirect clues, and human-encounter-ready event data.

**Architecture:** Expand the mart indoor JSON from a flat action list into a zone graph with event nodes and option outcomes. Keep `run_shell` and the shared run state unchanged while `indoor_director.gd` owns current zone, visited state, event flags, and zone-local action generation through `indoor_action_resolver.gd`.

**Tech Stack:** Godot 4.4.1, GDScript, JSON content data, headless Godot tests

---

### Task 1: Introduce the mart zone graph schema in data and resolver helpers

**Files:**
- Modify: `game/data/events/indoor/mart_01.json`
- Modify: `game/scripts/indoor/indoor_action_resolver.gd`
- Create: `game/tests/unit/test_indoor_zone_graph.gd`

- [ ] **Step 1: Write the failing test**

```gdscript
extends "res://tests/support/test_case.gd"

const RESOLVER_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const EVENT_PATH := "res://data/events/indoor/mart_01.json"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var resolver_script := load(RESOLVER_PATH) as Script
	if not assert_true(resolver_script != null, "Missing resolver script."):
		return

	var event_data := _load_json(EVENT_PATH)
	if event_data.is_empty():
		return

	var resolver = resolver_script.new()
	assert_eq(resolver.get_entry_zone_id(event_data), "mart_entrance", "Mart should expose its entry zone.")

	var entrance_zone := resolver.get_zone(event_data, "mart_entrance")
	assert_eq(String(entrance_zone.get("label", "")), "정문 진입부", "Entry zone should expose its label.")

	var move_actions := resolver.get_move_actions(
		event_data,
		{
			"current_zone_id": "mart_entrance",
			"visited_zone_ids": PackedStringArray(["mart_entrance"]),
			"zone_flags": {},
		}
	)
	assert_eq(
		_action_ids(move_actions),
		["move_checkout", "move_food_aisle"],
		"Entry zone should only expose the first adjacent move actions."
	)

	pass_test("INDOOR_ZONE_GRAPH_OK")


func _action_ids(actions: Array) -> Array[String]:
	var ids: Array[String] = []
	for action in actions:
		ids.append(String(action.get("id", "")))
	return ids


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not assert_true(file != null, "Missing event JSON."):
		return {}

	var json := JSON.new()
	if not assert_eq(json.parse(file.get_as_text()), OK, "Event JSON should parse."):
		return {}

	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_zone_graph.gd
```

Expected: FAIL because `get_entry_zone_id`, `get_zone`, and `get_move_actions` do not exist yet and the mart JSON is still flat.

- [ ] **Step 3: Write minimal implementation**

Add the zone graph to `mart_01.json` and minimal resolver helpers:

```json
{
  "id": "mart_01",
  "name": "동네 마트",
  "entry_zone_id": "mart_entrance",
  "zones": [
    {
      "id": "mart_entrance",
      "floor_id": "floor_1",
      "label": "정문 진입부",
      "summary": "깨진 자동문과 쓰러진 장바구니가 보인다.",
      "connected_zone_ids": ["checkout", "food_aisle"],
      "first_visit_cost": 30,
      "revisit_cost": 10,
      "event_ids": []
    }
  ],
  "events": []
}
```

```gdscript
func get_entry_zone_id(event_data: Dictionary) -> String:
	return String(event_data.get("entry_zone_id", ""))


func get_zone(event_data: Dictionary, zone_id: String) -> Dictionary:
	for zone_variant in event_data.get("zones", []):
		if typeof(zone_variant) != TYPE_DICTIONARY:
			continue
		var zone := zone_variant as Dictionary
		if String(zone.get("id", "")) == zone_id:
			return zone
	return {}


func get_move_actions(event_data: Dictionary, event_state: Dictionary) -> Array[Dictionary]:
	var zone := get_zone(event_data, String(event_state.get("current_zone_id", "")))
	if zone.is_empty():
		return []

	var visited_zone_ids := _string_id_array(event_state.get("visited_zone_ids", []))
	var actions: Array[Dictionary] = []
	for connected_zone_id_variant in zone.get("connected_zone_ids", []):
		var connected_zone_id := String(connected_zone_id_variant)
		var connected_zone := get_zone(event_data, connected_zone_id)
		if connected_zone.is_empty():
			continue
		var minute_cost := int(connected_zone.get("revisit_cost", 10)) if visited_zone_ids.has(connected_zone_id) else int(connected_zone.get("first_visit_cost", 30))
		actions.append({
			"id": "move_%s" % connected_zone_id,
			"type": "move",
			"label": "%s로 이동한다" % String(connected_zone.get("label", connected_zone_id)),
			"target_zone_id": connected_zone_id,
			"minute_cost": minute_cost,
		})
	return actions
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_zone_graph.gd
```

Expected: PASS with `INDOOR_ZONE_GRAPH_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/data/events/indoor/mart_01.json game/scripts/indoor/indoor_action_resolver.gd game/tests/unit/test_indoor_zone_graph.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add indoor zone graph primitives"
```

### Task 2: Extend resolver outcomes for movement, flags, clues, and gated options

**Files:**
- Modify: `game/data/events/indoor/mart_01.json`
- Modify: `game/scripts/indoor/indoor_action_resolver.gd`
- Modify: `game/tests/unit/test_indoor_actions.gd`

- [ ] **Step 1: Write the failing test**

Add a new scenario to `test_indoor_actions.gd` that expects a gated route and a forced-entry route:

```gdscript
var event_state := {
	"current_zone_id": "checkout",
	"visited_zone_ids": PackedStringArray(["mart_entrance", "checkout"]),
	"revealed_clue_ids": PackedStringArray(),
	"spent_action_ids": PackedStringArray(),
	"zone_flags": {},
	"noise": 0,
}

var actions := resolver.get_actions(event_data, event_state)
assert_true(_action_ids(actions).has("search_checkout_drawer"), "Checkout should expose its search action.")
assert_true(_action_ids(actions).has("move_staff_corridor_gate"), "Checkout should expose movement toward the staff gate.")

assert_true(resolver.apply_action(run_state, event_data, event_state, "search_checkout_drawer"), "Checkout search should resolve.")
assert_true(_string_values(event_state.get("revealed_clue_ids", [])).has("staff_key_board_hint"), "Searching checkout should reveal the staff key board clue.")
assert_true(_string_values(event_state.get("zone_flags", {}).keys()).has("checkout_drawer_opened"), "Searching checkout should set a zone flag.")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_actions.gd
```

Expected: FAIL because the resolver still only supports the old flat `actions` array and does not emit movement, flags, or noise-aware results.

- [ ] **Step 3: Write minimal implementation**

Extend the mart event data and resolver to support event options with requirements and outcomes:

```json
{
  "id": "search_checkout_drawer",
  "zone_id": "checkout",
  "type": "search",
  "hint_text": "서랍은 닫혀 있는데 급히 뜯은 흔적은 없다.",
  "options": [
    {
      "id": "search_checkout_drawer",
      "label": "조용히 서랍을 연다",
      "requirements": {},
      "costs": { "minutes": 30, "noise": 0 },
      "outcomes": {
        "loot": [{ "id": "canned_beans", "name": "통조림 콩", "bulk": 1 }],
        "reveal_clue_ids": ["staff_key_board_hint"],
        "set_flags": ["checkout_drawer_opened"],
        "consume_on_use": true
      }
    }
  ]
}
```

```gdscript
func get_actions(event_data: Dictionary, event_state: Dictionary = {}) -> Array[Dictionary]:
	var actions := get_move_actions(event_data, event_state)
	var current_zone_id := String(event_state.get("current_zone_id", ""))
	for event_variant in event_data.get("events", []):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event := event_variant as Dictionary
		if String(event.get("zone_id", "")) != current_zone_id:
			continue
		for option_variant in event.get("options", []):
			if typeof(option_variant) != TYPE_DICTIONARY:
				continue
			var option := option_variant as Dictionary
			if _option_is_available(option, event_state):
				actions.append(option)
	return actions


func apply_action(run_state, event_data: Dictionary, event_state: Dictionary, action_id: String) -> bool:
	if action_id.begins_with("move_"):
		return _apply_move_action(run_state, event_data, event_state, action_id)

	var option := _get_option(event_data, String(event_state.get("current_zone_id", "")), action_id)
	if option.is_empty():
		return false

	_apply_costs(run_state, event_state, option)
	_apply_outcomes(run_state, event_state, option)
	return true
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_actions.gd
```

Expected: PASS with `INDOOR_ACTIONS_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/data/events/indoor/mart_01.json game/scripts/indoor/indoor_action_resolver.gd game/tests/unit/test_indoor_actions.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: support indoor zone options and outcomes"
```

### Task 3: Make the indoor director own zone progression and readable location state

**Files:**
- Modify: `game/scripts/indoor/indoor_director.gd`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Create: `game/tests/unit/test_indoor_director.gd`

- [ ] **Step 1: Write the failing test**

Create `test_indoor_director.gd`:

```gdscript
extends "res://tests/support/test_case.gd"

const DIRECTOR_PATH := "res://scripts/indoor/indoor_director.gd"
const RUN_STATE_PATH := "res://scripts/run/run_state.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var director_script := load(DIRECTOR_PATH) as Script
	var run_state_script := load(RUN_STATE_PATH) as Script
	if not assert_true(director_script != null and run_state_script != null, "Director dependencies should load."):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(),
		"remaining_points": 0,
	}, self)
	var director = director_script.new()
	director.configure(run_state, "mart_01")

	assert_eq(director.get_current_zone_id(), "mart_entrance", "Director should start at the entry zone.")
	assert_eq(director.get_current_zone_label(), "정문 진입부", "Director should expose the current zone label.")

	assert_true(director.apply_action("move_checkout"), "Director should allow zone movement actions.")
	assert_eq(director.get_current_zone_id(), "checkout", "Movement should change the current zone.")

	pass_test("INDOOR_DIRECTOR_OK")
```

Also extend `test_indoor_mode.gd` to require a zone label node:

```gdscript
var zone_label := indoor_mode.get_node_or_null("Panel/VBox/LocationLabel") as Label
assert_true(zone_label != null, "Indoor mode should expose a location label.")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_director.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL because the director has no current-zone API and the indoor scene has no location label.

- [ ] **Step 3: Write minimal implementation**

Add current-zone state to the director and render it in the indoor UI:

```gdscript
var _event_state: Dictionary = {
	"current_zone_id": "",
	"visited_zone_ids": PackedStringArray(),
	"revealed_clue_ids": PackedStringArray(),
	"spent_action_ids": PackedStringArray(),
	"zone_flags": {},
	"noise": 0,
}


func configure(run_state, building_id: String) -> void:
	_run_state = run_state
	_building_data = _get_building_data(building_id)
	_event_data = _resolver.load_event(String(_building_data.get("indoor_event_path", "")))
	var entry_zone_id := _resolver.get_entry_zone_id(_event_data)
	_event_state = {
		"current_zone_id": entry_zone_id,
		"visited_zone_ids": PackedStringArray([entry_zone_id]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}
	state_changed.emit()


func get_current_zone_id() -> String:
	return String(_event_state.get("current_zone_id", ""))


func get_current_zone_label() -> String:
	return _resolver.get_zone_label(_event_data, get_current_zone_id())
```

```gdscript
@onready var _location_label := get_node_or_null("Panel/VBox/LocationLabel") as Label

func _refresh_view() -> void:
	# existing title/summary refresh...
	if _location_label != null and _director.has_method("get_current_zone_label"):
		_location_label.text = _director.get_current_zone_label()
```

```text
[node name="LocationLabel" type="Label" parent="Panel/VBox"]
text = "현재 위치"
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_director.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected: PASS with `INDOOR_DIRECTOR_OK` and `INDOOR_MODE_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/scripts/indoor/indoor_director.gd game/scripts/indoor/indoor_mode.gd game/scenes/indoor/indoor_mode.tscn game/tests/unit/test_indoor_mode.gd game/tests/unit/test_indoor_director.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: track indoor zone progression"
```

### Task 4: Fill the mart with connected floor content, gate decisions, and human-encounter-ready nodes

**Files:**
- Modify: `game/data/events/indoor/mart_01.json`
- Modify: `game/tests/unit/test_indoor_actions.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Write the failing test**

Expand the smoke to walk through the building and verify the new indoor flow:

```gdscript
var location_label := indoor_mode.get_node_or_null("Panel/VBox/LocationLabel") as Label
assert_eq(location_label.text, "정문 진입부", "Indoor mode should begin at the mart entrance zone.")

var move_checkout_button := _find_button_by_text(action_buttons, "계산대 구역로 이동한다")
assert_true(move_checkout_button != null, "Indoor mode should expose a movement action into checkout.")

move_checkout_button.emit_signal("pressed")
if not await _wait_until(
	Callable(self, "_label_text_is").bind(location_label, "계산대 구역"),
	"Timed out waiting for indoor location to change."
):
	bootstrap.free()
	return

assert_true(_buttons_include_text(action_buttons, "조용히 서랍을 연다"), "Checkout should expose its local search action.")
```

Also extend `test_indoor_actions.gd` to verify one gate and one human-encounter-ready branch:

```gdscript
assert_true(_action_ids(resolver.get_actions(event_data, gate_state)).has("force_staff_corridor_gate"), "Staff gate should expose a forced-entry option.")
assert_true(_action_ids(resolver.get_actions(event_data, hall_state)).has("wait_and_listen"), "Back hall should expose a human-encounter-ready option.")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_actions.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected: FAIL because the mart data still only includes a small subset of the 1-floor prototype interactions.

- [ ] **Step 3: Write minimal implementation**

Populate the mart data with the agreed zones and event families.

Add zones:

```json
{ "id": "checkout", "floor_id": "floor_1", "label": "계산대 구역", "connected_zone_ids": ["mart_entrance", "staff_corridor_gate"], "first_visit_cost": 30, "revisit_cost": 10, "event_ids": ["checkout_drawer_event"] },
{ "id": "back_hall", "floor_id": "floor_1", "label": "음료/후면 통로", "connected_zone_ids": ["household_goods", "cold_storage", "staff_corridor_gate"], "first_visit_cost": 30, "revisit_cost": 10, "event_ids": ["drag_marks_event"] }
```

Add gate and encounter-ready event nodes:

```json
{
  "id": "staff_gate_event",
  "zone_id": "staff_corridor_gate",
  "type": "access",
  "hint_text": "문 손잡이 아래만 유독 닳아 있다.",
  "options": [
    {
      "id": "inspect_staff_corridor_gate",
      "label": "귀를 대본다",
      "requirements": {},
      "costs": { "minutes": 10, "noise": 0 },
      "outcomes": {
        "reveal_clue_ids": ["muffled_breath_hint"]
      }
    },
    {
      "id": "force_staff_corridor_gate",
      "label": "공구로 비집는다",
      "requirements": { "required_flag_ids": ["has_pry_tool"] },
      "costs": { "minutes": 30, "noise": 2 },
      "outcomes": {
        "unlock_zone_ids": ["stair_landing"],
        "set_flags": ["staff_gate_forced"]
      }
    }
  ]
}
```

```json
{
  "id": "drag_marks_event",
  "zone_id": "back_hall",
  "type": "human_encounter",
  "hint_text": "무거운 상자를 끈 자국이 안쪽으로 이어진다.",
  "options": [
    {
      "id": "wait_and_listen",
      "label": "소리를 죽이고 기다린다",
      "requirements": {},
      "costs": { "minutes": 10, "noise": 0 },
      "outcomes": {
        "reveal_clue_ids": ["recent_human_presence_hint"]
      }
    }
  ]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_actions.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected: PASS with `INDOOR_ACTIONS_OK` and `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/data/events/indoor/mart_01.json game/tests/unit/test_indoor_actions.gd game/tests/smoke/test_first_playable_loop.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add connected mart indoor content"
```

### Task 5: Run the full indoor regression suite and leave the repo in a push-ready state

**Files:**
- Modify: none unless regression failures require it
- Test: `game/tests/unit/test_indoor_zone_graph.gd`
- Test: `game/tests/unit/test_indoor_actions.gd`
- Test: `game/tests/unit/test_indoor_director.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`

- [ ] **Step 1: Run the focused regression suite**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_zone_graph.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_actions.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_director.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
```

Expected: all commands exit `0` and print their `*_OK` markers.

- [ ] **Step 2: Check the git diff**

Run:

```bash
git -C /home/muhyeon_shin/packages/apocalypse status --short --branch
git -C /home/muhyeon_shin/packages/apocalypse diff --check
```

Expected:

- only the intended mart indoor files are modified
- no whitespace or merge-marker issues

- [ ] **Step 3: Commit the final integration pass**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/data/events/indoor/mart_01.json game/scripts/indoor/indoor_action_resolver.gd game/scripts/indoor/indoor_director.gd game/scripts/indoor/indoor_mode.gd game/scenes/indoor/indoor_mode.tscn game/tests/unit/test_indoor_zone_graph.gd game/tests/unit/test_indoor_actions.gd game/tests/unit/test_indoor_director.gd game/tests/unit/test_indoor_mode.gd game/tests/smoke/test_first_playable_loop.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: expand mart indoor exploration"
```

## Self-Review

### Spec Coverage

- Connected zone exploration: covered by Task 1 and Task 3
- Indirect clues and gated back-of-house progression: covered by Task 2 and Task 4
- Human-encounter-ready event grammar: covered by Task 2 and Task 4
- Story-friendly extensibility: preserved through Task 1 data schema and Task 2 outcome fields
- Regression confidence: covered by Task 5

### Placeholder Scan

- No `TODO`, `TBD`, or deferred implementation markers are used as plan steps
- Every code-changing step includes concrete file targets and code snippets
- Every verification step includes an exact command and expected result

### Type Consistency

- `current_zone_id`, `visited_zone_ids`, `zone_flags`, and `noise` are used consistently across resolver, director, and tests
- `get_entry_zone_id`, `get_zone`, and `get_move_actions` are defined before later tasks rely on them
- `LocationLabel` and the director current-zone API are introduced in Task 3 before smoke tests use them in Task 4
