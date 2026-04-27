# Outdoor 3x3 Authored Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **User workflow note:** Do not create micro-commits during this plan. The user prefers one verified commit after the full pass is working.

**Goal:** Expand the currently authored outdoor district from `2x2` blocks to a full contiguous `3x3` slice so outdoor travel, destination choice, and city scale all feel materially larger before deeper loot and story passes land.

**Architecture:** Keep the existing fixed-city outdoor runtime exactly as-is: `world_layout.json`, per-block JSON, `OutdoorWorldRuntime`, and `3x3` streaming remain the contract. This pass only expands authored content by adding five new block files, new building anchors/building entries, and thin indoor shells so the playable city footprint actually fills a meaningful `3x3` authored slice.

**Tech Stack:** Godot 4.4.1, GDScript, JSON data-driven outdoor blocks, existing headless Godot test suite

---

## File Structure

### New Files

- `game/data/outdoor/blocks/2_0.json`
  - New northeast extension block for the authored slice.
- `game/data/outdoor/blocks/2_1.json`
  - New east-middle block with a larger-facility / service-lot flavor.
- `game/data/outdoor/blocks/2_2.json`
  - New southeast authored block.
- `game/data/outdoor/blocks/1_2.json`
  - New south-middle block.
- `game/data/outdoor/blocks/0_2.json`
  - New southwest extension block.
- `game/data/events/indoor/<new-building>.json`
  - Thin indoor shells for every newly enterable building introduced by the five new blocks.

### Modified Files

- `game/data/buildings.json`
  - Add the new building identities, block coordinates, anchor IDs, and indoor event links.
- `game/tests/unit/test_content_library.gd`
  - Raise the authored-building contract to reflect the `3x3` slice.
- `game/tests/unit/test_outdoor_controller.gd`
  - Lock the authored block count and higher destination count.
- `game/tests/smoke/test_first_playable_loop.gd`
  - Keep smoke traversal valid as the playable slice expands.
- `docs/INDEX.md`
  - Route readers to this plan as active.
- `docs/CURRENT_STATE.md`
  - Replace the old `2x2` authored-slice immediate priority with `3x3`.

## Task 1: Raise The Tests To The New 3x3 Slice Contract

**Files:**
- Modify: `game/tests/unit/test_content_library.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Raise the content-library authored block contract from 4 to 9**

In `game/tests/unit/test_content_library.gd`, add assertions that the authored slice now includes all nine blocks:

```gdscript
	var authored_block_coords := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2),
	]
	for block_coord in authored_block_coords:
		var block := content_library.get_outdoor_block(block_coord)
		assert_true(not block.is_empty(), "Outdoor authored block %s should exist." % [block_coord])
```

- [ ] **Step 2: Raise the authored building-count floor in the controller test**

In `game/tests/unit/test_outdoor_controller.gd`, replace the old building floor:

```gdscript
	assert_true(building_markers.get_child_count() >= 28, "The authored outdoor slice should expose at least twenty-eight building markers after the 3x3 expansion.")
```

- [ ] **Step 3: Raise the smoke expectation so the larger authored slice must still boot cleanly**

In `game/tests/smoke/test_first_playable_loop.gd`, keep the existing active-window contract and add an authored-block sanity check after outdoor boot:

```gdscript
	var authored_coords := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2),
	]
	for block_coord in authored_coords:
		var block := content_library.get_outdoor_block(block_coord)
		assert_true(not block.is_empty(), "Smoke coverage expects authored outdoor block %s to exist." % [block_coord])
```

- [ ] **Step 4: Run the focused tests and confirm they fail before authoring**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- tests fail because the five new blocks and their buildings do not exist yet

## Task 2: Author The Five New Outdoor Block Files

**Files:**
- Create: `game/data/outdoor/blocks/2_0.json`
- Create: `game/data/outdoor/blocks/2_1.json`
- Create: `game/data/outdoor/blocks/2_2.json`
- Create: `game/data/outdoor/blocks/1_2.json`
- Create: `game/data/outdoor/blocks/0_2.json`

- [ ] **Step 1: Add `2_0.json` as a denser mixed-use extension block**

Create `game/data/outdoor/blocks/2_0.json` following the existing schema:

```json
{
  "block_coord": { "x": 2, "y": 0 },
  "roads": [
    { "id": "north_south", "rect": { "x": 360, "y": 0, "width": 240, "height": 960 } },
    { "id": "east_west", "rect": { "x": 0, "y": 320, "width": 960, "height": 280 } }
  ],
  "snow_fields": [
    { "id": "north_lot_snow", "rect": { "x": 0, "y": 0, "width": 260, "height": 220 } },
    { "id": "southeast_open_snow", "rect": { "x": 660, "y": 660, "width": 300, "height": 300 } }
  ],
  "obstacles": [
    { "kind": "vehicle", "rect": { "x": 140, "y": 450, "width": 56, "height": 56 } },
    { "kind": "rubble", "rect": { "x": 760, "y": 180, "width": 120, "height": 80 } }
  ],
  "building_anchors": {
    "bookstore_anchor": { "x": 180, "y": 200 },
    "deli_anchor": { "x": 760, "y": 220 },
    "hostel_anchor": { "x": 740, "y": 720 }
  },
  "threat_spawns": [
    { "id": "pack_20_a", "position": { "x": 860, "y": 140 }, "forward": { "x": -1, "y": 0 } }
  ],
  "landmarks": [
    { "id": "book_lane", "label": "동쪽 상가 골목", "position": { "x": 500, "y": 470 } }
  ]
}
```

- [ ] **Step 2: Add `2_1.json` as a larger-facility/service-lot block**

Create `game/data/outdoor/blocks/2_1.json`:

```json
{
  "block_coord": { "x": 2, "y": 1 },
  "roads": [
    { "id": "north_south", "rect": { "x": 360, "y": 0, "width": 240, "height": 960 } },
    { "id": "east_west", "rect": { "x": 0, "y": 320, "width": 960, "height": 280 } }
  ],
  "snow_fields": [
    { "id": "yard_snow", "rect": { "x": 620, "y": 20, "width": 320, "height": 240 } },
    { "id": "south_lot_snow", "rect": { "x": 0, "y": 660, "width": 300, "height": 260 } }
  ],
  "obstacles": [
    { "kind": "vehicle", "rect": { "x": 480, "y": 450, "width": 56, "height": 56 } },
    { "kind": "rubble", "rect": { "x": 150, "y": 730, "width": 120, "height": 90 } }
  ],
  "building_anchors": {
    "storage_depot_anchor": { "x": 180, "y": 200 },
    "garage_anchor": { "x": 740, "y": 220 },
    "canteen_anchor": { "x": 720, "y": 720 }
  },
  "threat_spawns": [
    { "id": "pack_21_a", "position": { "x": 840, "y": 820 }, "forward": { "x": -1, "y": 0 } }
  ],
  "landmarks": [
    { "id": "service_yard", "label": "동쪽 작업 마당", "position": { "x": 520, "y": 460 } }
  ]
}
```

- [ ] **Step 3: Add `2_2.json` as a lower-density mixed block**

Create `game/data/outdoor/blocks/2_2.json`:

```json
{
  "block_coord": { "x": 2, "y": 2 },
  "roads": [
    { "id": "north_south", "rect": { "x": 360, "y": 0, "width": 240, "height": 960 } },
    { "id": "east_west", "rect": { "x": 0, "y": 320, "width": 960, "height": 280 } }
  ],
  "snow_fields": [
    { "id": "north_open_snow", "rect": { "x": 0, "y": 0, "width": 280, "height": 240 } },
    { "id": "east_open_snow", "rect": { "x": 680, "y": 640, "width": 280, "height": 320 } }
  ],
  "obstacles": [
    { "kind": "vehicle", "rect": { "x": 120, "y": 450, "width": 56, "height": 56 } },
    { "kind": "rubble", "rect": { "x": 760, "y": 720, "width": 120, "height": 90 } }
  ],
  "building_anchors": {
    "church_anchor": { "x": 200, "y": 200 },
    "corner_store_anchor": { "x": 760, "y": 240 }
  },
  "threat_spawns": [
    { "id": "pack_22_a", "position": { "x": 860, "y": 860 }, "forward": { "x": -1, "y": -1 } }
  ],
  "landmarks": [
    { "id": "snow_square", "label": "눈 쌓인 공터", "position": { "x": 500, "y": 500 } }
  ]
}
```

- [ ] **Step 4: Add `1_2.json` as a southern neighborhood extension**

Create `game/data/outdoor/blocks/1_2.json`:

```json
{
  "block_coord": { "x": 1, "y": 2 },
  "roads": [
    { "id": "north_south", "rect": { "x": 360, "y": 0, "width": 240, "height": 960 } },
    { "id": "east_west", "rect": { "x": 0, "y": 320, "width": 960, "height": 280 } }
  ],
  "snow_fields": [
    { "id": "west_snow", "rect": { "x": 0, "y": 640, "width": 280, "height": 300 } },
    { "id": "north_snow", "rect": { "x": 660, "y": 0, "width": 260, "height": 200 } }
  ],
  "obstacles": [
    { "kind": "vehicle", "rect": { "x": 760, "y": 450, "width": 56, "height": 56 } },
    { "kind": "rubble", "rect": { "x": 180, "y": 180, "width": 110, "height": 70 } }
  ],
  "building_anchors": {
    "school_gate_anchor": { "x": 200, "y": 200 },
    "butcher_anchor": { "x": 760, "y": 220 },
    "row_house_anchor": { "x": 220, "y": 720 }
  },
  "threat_spawns": [
    { "id": "pack_12_a", "position": { "x": 140, "y": 840 }, "forward": { "x": 1, "y": -1 } }
  ],
  "landmarks": [
    { "id": "school_corner", "label": "남쪽 골목 모퉁이", "position": { "x": 500, "y": 470 } }
  ]
}
```

- [ ] **Step 5: Add `0_2.json` as a more open lot-and-destination block**

Create `game/data/outdoor/blocks/0_2.json`:

```json
{
  "block_coord": { "x": 0, "y": 2 },
  "roads": [
    { "id": "north_south", "rect": { "x": 360, "y": 0, "width": 240, "height": 960 } },
    { "id": "east_west", "rect": { "x": 0, "y": 320, "width": 960, "height": 280 } }
  ],
  "snow_fields": [
    { "id": "west_open_snow", "rect": { "x": 0, "y": 0, "width": 300, "height": 260 } },
    { "id": "south_open_snow", "rect": { "x": 620, "y": 660, "width": 320, "height": 300 } }
  ],
  "obstacles": [
    { "kind": "vehicle", "rect": { "x": 150, "y": 450, "width": 56, "height": 56 } },
    { "kind": "rubble", "rect": { "x": 760, "y": 180, "width": 120, "height": 80 } }
  ],
  "building_anchors": {
    "chapel_anchor": { "x": 200, "y": 200 },
    "tea_shop_anchor": { "x": 760, "y": 240 }
  },
  "threat_spawns": [
    { "id": "pack_02_a", "position": { "x": 120, "y": 820 }, "forward": { "x": 1, "y": -1 } }
  ],
  "landmarks": [
    { "id": "open_lot", "label": "눈 덮인 공터", "position": { "x": 500, "y": 480 } }
  ]
}
```

## Task 3: Add The New Building Entries And Thin Indoor Shells

**Files:**
- Modify: `game/data/buildings.json`
- Create: `game/data/events/indoor/bookstore_01.json`
- Create: `game/data/events/indoor/deli_01.json`
- Create: `game/data/events/indoor/hostel_01.json`
- Create: `game/data/events/indoor/storage_depot_01.json`
- Create: `game/data/events/indoor/garage_01.json`
- Create: `game/data/events/indoor/canteen_01.json`
- Create: `game/data/events/indoor/church_01.json`
- Create: `game/data/events/indoor/corner_store_01.json`
- Create: `game/data/events/indoor/school_gate_01.json`
- Create: `game/data/events/indoor/butcher_01.json`
- Create: `game/data/events/indoor/row_house_01.json`
- Create: `game/data/events/indoor/chapel_01.json`
- Create: `game/data/events/indoor/tea_shop_01.json`

- [ ] **Step 1: Append the new building identities into `buildings.json`**

Add entries that match the new anchors:

```json
  {
    "id": "bookstore_01",
    "name": "중고 서점",
    "category": "retail",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 2, "y": 0 },
    "outdoor_anchor_id": "bookstore_anchor",
    "indoor_event_path": "res://data/events/indoor/bookstore_01.json"
  },
  {
    "id": "deli_01",
    "name": "반찬 가게",
    "category": "food_service",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 2, "y": 0 },
    "outdoor_anchor_id": "deli_anchor",
    "indoor_event_path": "res://data/events/indoor/deli_01.json"
  },
  {
    "id": "hostel_01",
    "name": "소형 여관",
    "category": "residential",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 2, "y": 0 },
    "outdoor_anchor_id": "hostel_anchor",
    "indoor_event_path": "res://data/events/indoor/hostel_01.json"
  }
```

Then continue with the remaining anchors:

```json
  {
    "id": "storage_depot_01",
    "name": "물류 보관소",
    "category": "industrial",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 2, "y": 1 },
    "outdoor_anchor_id": "storage_depot_anchor",
    "indoor_event_path": "res://data/events/indoor/storage_depot_01.json"
  },
  {
    "id": "garage_01",
    "name": "차고지",
    "category": "industrial",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 2, "y": 1 },
    "outdoor_anchor_id": "garage_anchor",
    "indoor_event_path": "res://data/events/indoor/garage_01.json"
  },
  {
    "id": "canteen_01",
    "name": "구내 식당",
    "category": "food_service",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 2, "y": 1 },
    "outdoor_anchor_id": "canteen_anchor",
    "indoor_event_path": "res://data/events/indoor/canteen_01.json"
  },
  {
    "id": "church_01",
    "name": "작은 교회",
    "category": "civic",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 2, "y": 2 },
    "outdoor_anchor_id": "church_anchor",
    "indoor_event_path": "res://data/events/indoor/church_01.json"
  },
  {
    "id": "corner_store_01",
    "name": "구멍가게",
    "category": "retail",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 2, "y": 2 },
    "outdoor_anchor_id": "corner_store_anchor",
    "indoor_event_path": "res://data/events/indoor/corner_store_01.json"
  },
  {
    "id": "school_gate_01",
    "name": "폐교 정문",
    "category": "civic",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 1, "y": 2 },
    "outdoor_anchor_id": "school_gate_anchor",
    "indoor_event_path": "res://data/events/indoor/school_gate_01.json"
  },
  {
    "id": "butcher_01",
    "name": "정육점",
    "category": "food_service",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 1, "y": 2 },
    "outdoor_anchor_id": "butcher_anchor",
    "indoor_event_path": "res://data/events/indoor/butcher_01.json"
  },
  {
    "id": "row_house_01",
    "name": "연립 주택",
    "category": "residential",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 1, "y": 2 },
    "outdoor_anchor_id": "row_house_anchor",
    "indoor_event_path": "res://data/events/indoor/row_house_01.json"
  },
  {
    "id": "chapel_01",
    "name": "작은 예배당",
    "category": "civic",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 0, "y": 2 },
    "outdoor_anchor_id": "chapel_anchor",
    "indoor_event_path": "res://data/events/indoor/chapel_01.json"
  },
  {
    "id": "tea_shop_01",
    "name": "찻집",
    "category": "food_service",
    "base_candidate": false,
    "outdoor_block_coord": { "x": 0, "y": 2 },
    "outdoor_anchor_id": "tea_shop_anchor",
    "indoor_event_path": "res://data/events/indoor/tea_shop_01.json"
  }
```

- [ ] **Step 2: Create one thin-shell indoor event template and reuse it consistently**

Use the existing light indoor event pattern already used by recent small buildings. Each file should carry:

- a title
- 1-2 room nodes
- a short summary
- 1-2 simple search actions
- minimal loot

Use this shape for `bookstore_01.json`:

```json
{
  "event_id": "indoor_bookstore_01",
  "building_id": "bookstore_01",
  "entry_node_id": "bookstore_entry",
  "nodes": [
    {
      "id": "bookstore_entry",
      "title": "입구",
      "summary": "유리문이 깨진 서점 입구다. 눅눅한 종이 냄새와 찬 공기가 남아 있다.",
      "links": [
        { "to": "back_shelf", "label": "안쪽 서가로 이동한다", "minutes": 10 }
      ],
      "actions": [
        {
          "id": "search_entry_cache",
          "type": "search",
          "label": "계산대 주변을 뒤진다",
          "minutes": 30,
          "loot_table_id": "retail_small_counter"
        }
      ]
    },
    {
      "id": "back_shelf",
      "title": "안쪽 서가",
      "summary": "쓰러진 서가와 젖은 책 더미가 어지럽다.",
      "links": [
        { "to": "bookstore_entry", "label": "입구 쪽으로 돌아간다", "minutes": 10 }
      ],
      "actions": [
        {
          "id": "search_shelf",
          "type": "search",
          "label": "남은 책 더미를 살핀다",
          "minutes": 30,
          "loot_table_id": "paper_goods_small"
        }
      ]
    }
  ]
}
```

- [ ] **Step 3: Mirror that thin-shell structure across the remaining new interiors**

Create the other new files with the same level of depth:

- `deli_01.json`
- `hostel_01.json`
- `storage_depot_01.json`
- `garage_01.json`
- `canteen_01.json`
- `church_01.json`
- `corner_store_01.json`
- `school_gate_01.json`
- `butcher_01.json`
- `row_house_01.json`
- `chapel_01.json`
- `tea_shop_01.json`

Keep each one to:

- 1 entry node
- 1 interior node when needed
- 1-2 actions max
- short loot hooks only

## Task 4: Verify The New 3x3 Slice End-To-End

**Files:**
- Modify: `docs/INDEX.md`
- Modify: `docs/CURRENT_STATE.md`

- [ ] **Step 1: Update routing so the new 3x3 authored-slice work is discoverable**

Add to `docs/INDEX.md` under active specs and active plans:

```md
- [Outdoor 3x3 Authored Slice Design](superpowers/specs/2026-04-17-outdoor-3x3-authored-slice-design.md)
- [Outdoor 3x3 Authored Slice](superpowers/plans/2026-04-17-outdoor-3x3-authored-slice.md)
```

In `docs/CURRENT_STATE.md`, keep the world-architecture doc active but replace the old `2x2` authored-slice immediate priority with the new `3x3` authored-slice priority.

- [ ] **Step 2: Run focused verification for the expanded city slice**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- content library sees all nine authored blocks
- outdoor controller renders at least twenty-eight building markers
- run transition smoke still works
- first playable loop still reaches and enters indoor content from the larger district

## Self-Review

- Spec coverage: this plan covers the new `3x3` authored slice, block variation, additional building entries, thin indoor shells, and routing updates.
- Placeholder scan: no `TBD`, `TODO`, or vague “handle appropriately” steps remain.
- Type consistency: all new outdoor data stays on the existing `outdoor_block_coord` + `outdoor_anchor_id` schema, and tests continue to target current Godot paths and existing runtime method names.

