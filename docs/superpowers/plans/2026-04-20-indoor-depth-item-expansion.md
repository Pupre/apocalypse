# Indoor Depth and Item Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **User workflow note:** Do not create micro-commits during this plan. The user prefers one verified commit after the full pass is working.

**Goal:** Deepen the authored city by turning four anchor buildings into real multi-zone sites, lifting the remaining shallow buildings out of one-zone shells, expanding the item compendium with site-appropriate finds, and expanding crafted items without forcing every new item into crafting.

**Architecture:** Keep the existing authored indoor JSON model: zone graphs, event ids, clues, access requirements, and re-entry memory remain the contract. This pass grows content by authoring deeper anchor-site event JSONs, batch-uplifting shallow interiors with reusable tier-2 patterns, extending `items.json` and `crafting_combinations.json`, and surfacing richer outdoor entry briefings from building metadata.

**Tech Stack:** Godot 4.4.1, GDScript, JSON-authored indoor sites and crafting combinations, existing headless Godot test suite

---

## File Structure

### New Files

- `game/tests/unit/test_indoor_content_depth.gd`
  - Dedicated regression suite for anchor-site zone depth, shallow-site uplift, and new item/recipe existence.
- `docs/resource_requests/2026-04-20-indoor-depth-expansion-ledger.md`
  - Separate resource-request ledger for newly added buildings, items, crafted outcomes, and notable site props.

### Modified Files

- `game/data/items.json`
  - Add new direct-use items, tools, keys, notes, crafting materials, intermediates, and crafted outcomes.
- `game/data/crafting_combinations.json`
  - Add new authored two-item combinations that connect new and existing items.
- `game/data/buildings.json`
  - Add indoor depth metadata and outdoor entry-briefing metadata for anchor and uplifted buildings.
- `game/data/events/indoor/mart_01.json`
  - Deepen the mart into a `tier 3` site with more zones, gates, keys, and richer loot.
- `game/data/events/indoor/hardware_01.json`
  - Deepen the hardware store into a `tier 3` repair/material site.
- `game/data/events/indoor/apartment_01.json`
  - Deepen the apartment into a `tier 3` vertical living site.
- `game/data/events/indoor/warehouse_01.json`
  - Expand the warehouse into the main logistics reward site.
- `game/data/events/indoor/garage_01.json`
  - Expand the garage into a linked logistics precursor / side site.
- `game/data/events/indoor/bakery_01.json`
- `game/data/events/indoor/bookstore_01.json`
- `game/data/events/indoor/butcher_01.json`
- `game/data/events/indoor/cafe_01.json`
- `game/data/events/indoor/canteen_01.json`
- `game/data/events/indoor/chapel_01.json`
- `game/data/events/indoor/church_01.json`
- `game/data/events/indoor/corner_store_01.json`
- `game/data/events/indoor/deli_01.json`
- `game/data/events/indoor/hostel_01.json`
- `game/data/events/indoor/pharmacy_01.json`
- `game/data/events/indoor/police_box_01.json`
- `game/data/events/indoor/repair_shop_01.json`
- `game/data/events/indoor/residence_01.json`
- `game/data/events/indoor/restaurant_01.json`
- `game/data/events/indoor/row_house_01.json`
- `game/data/events/indoor/school_gate_01.json`
- `game/data/events/indoor/storage_depot_01.json`
- `game/data/events/indoor/tea_shop_01.json`
  - Lift every current one-zone shallow site to a minimum `tier 2` pattern.
- `game/scripts/outdoor/outdoor_controller.gd`
  - Replace generic building-enter text with richer entry briefings sourced from `buildings.json`.
- `game/tests/unit/test_content_library.gd`
  - Raise content-library expectations for new item ids and recipe ids.
- `game/tests/unit/test_outdoor_controller.gd`
  - Lock the richer outdoor entry briefing behavior.
- `game/tests/smoke/test_first_playable_loop.gd`
  - Keep smoke coverage stable as deeper content and briefings land.
- `docs/INDEX.md`
  - Route readers to the new active plan.
- `docs/CURRENT_STATE.md`
  - Update the near-term priorities to reflect the indoor-depth pass.

## Task 1: Raise The Regression Contract For Indoor Depth

**Files:**
- Create: `game/tests/unit/test_indoor_content_depth.gd`
- Modify: `game/tests/unit/test_content_library.gd`

- [ ] **Step 1: Create a new indoor-depth regression suite with explicit anchor and uplift expectations**

Create `game/tests/unit/test_indoor_content_depth.gd`:

```gdscript
extends "res://tests/support/test_case.gd"

const ANCHOR_MIN_ZONE_COUNTS := {
	"mart_01": 14,
	"hardware_01": 6,
	"apartment_01": 13,
	"warehouse_01": 4,
	"garage_01": 3,
}

const UPLIFTED_BUILDING_IDS := [
	"bakery_01",
	"bookstore_01",
	"butcher_01",
	"cafe_01",
	"canteen_01",
	"chapel_01",
	"church_01",
	"corner_store_01",
	"deli_01",
	"hostel_01",
	"pharmacy_01",
	"police_box_01",
	"repair_shop_01",
	"residence_01",
	"restaurant_01",
	"row_house_01",
	"school_gate_01",
	"storage_depot_01",
	"tea_shop_01",
]

const REQUIRED_NEW_ITEM_IDS := [
	"butter_cookie_box",
	"instant_cocoa_mix",
	"cling_wrap_roll",
	"foil_tray_pack",
	"hand_warmer_pack",
	"mart_stock_note_01",
	"sealant_tube",
	"hose_clamp",
	"rubber_gasket",
	"epoxy_putty",
	"hardware_backroom_key",
	"sewing_kit",
	"knit_cap",
	"slippers",
	"detergent_pod_pack",
	"apartment_boiler_key",
	"empty_jerrycan",
	"siphon_hose",
	"shop_towel_bundle",
	"tarp_sheet",
	"drain_funnel",
	"warehouse_shutter_key",
	"sealed_window_patch",
	"transfer_hose",
	"patched_blanket",
	"solvent_wipes",
	"tarp_bedroll",
	"foil_tray_warmer",
]

func _init() -> void:
	call_deferred("_run_test")


func _event_path_for(building_id: String) -> String:
	var building := ContentLibrary.get_building(building_id)
	return ProjectSettings.globalize_path(String(building.get("indoor_event_path", "")))


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _run_test() -> void:
	for building_id in ANCHOR_MIN_ZONE_COUNTS.keys():
		var event_data := _load_json(_event_path_for(building_id))
		assert_true(not event_data.is_empty(), "Expected event data for '%s'." % building_id)
		assert_true((event_data.get("zones", []) as Array).size() >= int(ANCHOR_MIN_ZONE_COUNTS[building_id]), "Anchor building '%s' should meet its new depth target." % building_id)

	for building_id in UPLIFTED_BUILDING_IDS:
		var event_data := _load_json(_event_path_for(building_id))
		assert_true(not event_data.is_empty(), "Expected uplifted event data for '%s'." % building_id)
		assert_true((event_data.get("zones", []) as Array).size() >= 2, "Building '%s' should no longer be a one-zone shell." % building_id)

	for item_id in REQUIRED_NEW_ITEM_IDS:
		var row := ContentLibrary.get_item(item_id)
		assert_true(not row.is_empty(), "Expected new item '%s' to exist." % item_id)

	finish()
```

- [ ] **Step 2: Raise the content-library test so the new items and anchor metadata are contractual**

Append these assertions to `game/tests/unit/test_content_library.gd` inside `_run_test()`:

```gdscript
	for required_building_id in ["mart_01", "hardware_01", "apartment_01", "warehouse_01", "garage_01"]:
		var building := content_library.get_building(required_building_id)
		assert_true(not building.is_empty(), "Expected building '%s' to exist." % required_building_id)
		assert_true(String(building.get("depth_tier", "")).begins_with("tier_"), "Building '%s' should expose a depth_tier." % required_building_id)
		assert_true(not String(building.get("entry_briefing", "")).is_empty(), "Building '%s' should expose an outdoor entry briefing." % required_building_id)

	for required_item_id in [
		"butter_cookie_box",
		"sealant_tube",
		"sewing_kit",
		"empty_jerrycan",
		"sealed_window_patch",
		"patched_blanket",
	]:
		_assert_item_contract(required_item_id)

	_assert_recipe_contract("sealant_tube", "clear_plastic_sheet", "sealed_window_patch")
	_assert_recipe_contract("hose_clamp", "siphon_hose", "transfer_hose")
	_assert_recipe_contract("sewing_kit", "old_blanket", "patched_blanket")
	_assert_recipe_contract("shop_towel_bundle", "rubbing_alcohol", "solvent_wipes")
	_assert_recipe_contract("tarp_sheet", "old_blanket", "tarp_bedroll")
	_assert_recipe_contract("foil_tray_pack", "tea_light_candle", "foil_tray_warmer")
```

- [ ] **Step 3: Run the new focused tests and confirm they fail before authoring**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_content_depth.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
```

Expected:

- both tests fail because the new items, recipes, and deeper zone graphs do not exist yet

## Task 2: Expand Canonical Items, Recipes, And The Resource Ledger

**Files:**
- Modify: `game/data/items.json`
- Modify: `game/data/crafting_combinations.json`
- Create: `docs/resource_requests/2026-04-20-indoor-depth-expansion-ledger.md`

- [ ] **Step 1: Add the mart and household item family to `items.json`**

Append these rows to `game/data/items.json`:

```json
{
  "id": "butter_cookie_box",
  "name": "버터 쿠키 상자",
  "bulk": 1,
  "description": "금속 상자에 담긴 버터 쿠키다. 오래됐지만 아직 먹을 만하다.",
  "usage_hint": "간단한 간식으로 바로 먹기 좋다.",
  "cold_hint": "체온을 직접 올리진 않지만 추운 이동 중 허기를 눌러 주는 식량이다.",
  "category": "food",
  "item_tags": ["food", "packaged", "mart_item"],
  "hunger_restore": 9,
  "thirst_restore": -1,
  "use_minutes": 10
},
{
  "id": "instant_cocoa_mix",
  "name": "코코아 믹스",
  "bulk": 1,
  "description": "뜨거운 물만 있으면 금방 마실 수 있는 달콤한 코코아 믹스다.",
  "usage_hint": "뜨거운 물과 함께 쓰면 체온 회복에 도움이 되는 따뜻한 음료가 된다.",
  "cold_hint": "찬 몸을 달래는 쪽에 더 가까운 식품 재료다.",
  "category": "food",
  "item_tags": ["food", "drink_mix", "mart_item"]
},
{
  "id": "cling_wrap_roll",
  "name": "랩",
  "bulk": 1,
  "description": "얇지만 밀봉과 보온 보조에 두루 쓸 수 있는 랩이다.",
  "usage_hint": "용기, 보온병, 임시 봉합물과 함께 쓰기 좋다.",
  "cold_hint": "직접 따뜻하진 않지만 열과 수분을 잡는 데 도움이 된다.",
  "category": "utility",
  "item_tags": ["utility", "seal", "mart_item"]
},
{
  "id": "foil_tray_pack",
  "name": "알루미늄 포일 트레이",
  "bulk": 1,
  "description": "얕은 포일 트레이 몇 개가 포개져 있다.",
  "usage_hint": "작은 열원과 함께 쓰면 바닥 받침이나 임시 열 반사판으로 쓸 수 있다.",
  "cold_hint": "직접적인 연료는 아니지만 열을 모으는 데는 도움이 된다.",
  "category": "utility",
  "item_tags": ["utility", "container", "heat_support", "mart_item"]
},
{
  "id": "hand_warmer_pack",
  "name": "핫팩",
  "bulk": 1,
  "description": "봉지를 흔들면 한동안 미지근한 열을 내는 일회용 핫팩이다.",
  "category": "medical",
  "item_tags": ["medical", "warming", "mart_item"],
  "use_minutes": 5,
  "use_effects": { "exposure_restore": 5 }
},
{
  "id": "mart_stock_note_01",
  "name": "재고 정리 메모",
  "bulk": 1,
  "description": "포장재와 작은 생활용품을 어떻게 돌려쓰는지 적어 둔 메모다.",
  "usage_hint": "읽으면 소형 생활 조합 몇 가지를 익힌다.",
  "cold_hint": "보온용 소형 생활도구를 임시로 꾸리는 요령이 적혀 있다.",
  "category": "knowledge",
  "item_tags": ["knowledge", "readable", "mart_item"],
  "readable": true,
  "knowledge_title": "재고 정리 메모",
  "knowledge_recipe_ids": ["foil_tray_pack__tea_light_candle", "cling_wrap_roll__hot_water_bottle"]
}
```

- [ ] **Step 2: Add the hardware, apartment, and logistics item families**

Append these rows to `game/data/items.json`:

```json
{
  "id": "sealant_tube",
  "name": "실링제 튜브",
  "bulk": 1,
  "description": "틈을 메우고 접합면을 밀봉하는 데 쓰는 실링제다.",
  "usage_hint": "플라스틱 판, 얇은 막, 틈막이 재료와 잘 맞는다.",
  "cold_hint": "바람과 물이 새는 틈을 줄이는 데 좋다.",
  "category": "utility",
  "item_tags": ["utility", "seal", "hardware_item"]
},
{
  "id": "hose_clamp",
  "name": "호스 밴드",
  "bulk": 1,
  "description": "호스를 금속 관이나 노즐에 단단히 고정하는 금속 밴드다.",
  "usage_hint": "호스, 관, 임시 연결 장치와 함께 쓰기 좋다.",
  "cold_hint": "직접 보온에는 도움되지 않지만 유체를 다루는 임시 장치 제작에 좋다.",
  "category": "utility",
  "item_tags": ["utility", "fastener", "hardware_item"]
},
{
  "id": "rubber_gasket",
  "name": "고무 개스킷",
  "bulk": 1,
  "description": "압착면 사이를 밀봉하는 고무 개스킷이다.",
  "usage_hint": "배관 부속이나 뚜껑 결합면을 더 단단히 막는 데 쓸 수 있다.",
  "cold_hint": "찬 바람과 누수를 막는 보수 쪽에 가까운 부품이다.",
  "category": "utility",
  "item_tags": ["utility", "seal", "hardware_item"]
},
{
  "id": "epoxy_putty",
  "name": "에폭시 퍼티",
  "bulk": 1,
  "description": "손으로 섞어 틈이나 금속 파손부를 임시로 메울 수 있는 퍼티다.",
  "usage_hint": "작은 금속 파손부나 고정이 필요한 부분의 응급 보수에 쓸 수 있다.",
  "cold_hint": "바깥 추위보다 파손과 틈새를 줄이는 데 직접 도움이 되는 재료다.",
  "category": "utility",
  "item_tags": ["utility", "repair", "hardware_item"]
},
{
  "id": "hardware_backroom_key",
  "name": "철물점 뒷방 열쇠",
  "bulk": 1,
  "description": "철물점 안쪽 자재실을 여는 작은 열쇠다.",
  "category": "key",
  "item_tags": ["key", "hardware_item"]
},
{
  "id": "sewing_kit",
  "name": "반짇고리",
  "bulk": 1,
  "description": "실, 바늘, 작은 가위가 들어 있는 휴대용 반짇고리다.",
  "usage_hint": "천이나 담요를 기워 다시 쓰는 데 좋다.",
  "cold_hint": "낡은 섬유를 보수해 보온 도구를 오래 쓰게 만드는 쪽에 가깝다.",
  "category": "tool",
  "item_tags": ["tool", "textile", "apartment_item"]
},
{
  "id": "knit_cap",
  "name": "니트 모자",
  "bulk": 1,
  "description": "귀를 덮는 두꺼운 니트 모자다.",
  "usage_hint": "바로 쓰는 소모품은 아니지만 생활 보온 물품으로 가치가 있다.",
  "cold_hint": "머리 쪽 보온을 상상하게 만드는 생활용 겨울 물품이다.",
  "category": "utility",
  "item_tags": ["utility", "warming", "apartment_item"]
},
{
  "id": "slippers",
  "name": "실내 슬리퍼",
  "bulk": 1,
  "description": "바닥 냉기를 조금 막아 주는 낡은 실내 슬리퍼다.",
  "category": "equipment",
  "item_tags": ["equipment", "warming", "apartment_item"],
  "equip_slot": "feet",
  "move_speed_bonus": 2
},
{
  "id": "detergent_pod_pack",
  "name": "세제 캡슐",
  "bulk": 1,
  "description": "작은 세제 캡슐이 몇 개 남아 있는 봉투다.",
  "usage_hint": "세척 관련 조합이나 생활 위생 아이템과 잘 맞는다.",
  "cold_hint": "직접 보온은 아니지만 장기 생존에서 위생 유지에 도움이 된다.",
  "category": "utility",
  "item_tags": ["utility", "cleaning", "apartment_item"]
},
{
  "id": "apartment_boiler_key",
  "name": "보일러실 열쇠",
  "bulk": 1,
  "description": "아파트 지하 보일러실을 여는 녹슨 열쇠다.",
  "category": "key",
  "item_tags": ["key", "apartment_item"]
},
{
  "id": "empty_jerrycan",
  "name": "빈 제리캔",
  "bulk": 2,
  "description": "내용물은 비었지만 연료나 물을 옮기기 좋게 생긴 통이다.",
  "usage_hint": "이송 호스나 깔때기와 함께 쓰기 좋다.",
  "cold_hint": "직접 따뜻하진 않지만 연료나 물을 옮기는 기반 용기다.",
  "category": "utility",
  "item_tags": ["utility", "container", "logistics_item"]
},
{
  "id": "siphon_hose",
  "name": "사이펀 호스",
  "bulk": 1,
  "description": "액체를 옮길 때 쓰는 유연한 고무 호스다.",
  "usage_hint": "호스 밴드나 용기와 결합하면 임시 이송 장치가 된다.",
  "cold_hint": "연료와 물 같은 자원을 옮기는 기반 부품이다.",
  "category": "utility",
  "item_tags": ["utility", "fluid", "logistics_item"]
},
{
  "id": "shop_towel_bundle",
  "name": "작업용 수건 묶음",
  "bulk": 1,
  "description": "기름과 먼지가 밴 작업용 천 묶음이다.",
  "usage_hint": "세척제, 알코올, 보수 재료와 함께 쓰기 좋다.",
  "cold_hint": "직접 보온보다는 정비와 세척 쪽에 쓰기 좋은 천이다.",
  "category": "utility",
  "item_tags": ["utility", "cleaning", "logistics_item"]
},
{
  "id": "tarp_sheet",
  "name": "방수포",
  "bulk": 2,
  "description": "큰 물건을 덮거나 임시 차단막을 만들 때 쓰는 방수포다.",
  "usage_hint": "담요나 결속재와 함께 쓰면 차단막이나 꾸러미를 만들 수 있다.",
  "cold_hint": "바람과 눈을 막는 외피 재료로 가치가 있다.",
  "category": "utility",
  "item_tags": ["utility", "cover", "logistics_item"]
},
{
  "id": "drain_funnel",
  "name": "깔때기",
  "bulk": 1,
  "description": "액체를 좁은 입구로 옮길 때 쓰는 플라스틱 깔때기다.",
  "usage_hint": "병, 캔, 큰 용기에 액체를 옮길 때 쓰기 좋다.",
  "cold_hint": "직접 보온과는 무관하지만 자원 이송 작업을 쉽게 해 준다.",
  "category": "utility",
  "item_tags": ["utility", "container", "logistics_item"]
},
{
  "id": "warehouse_shutter_key",
  "name": "셔터 열쇠",
  "bulk": 1,
  "description": "창고 안쪽 셔터를 여는 묵직한 열쇠다.",
  "category": "key",
  "item_tags": ["key", "logistics_item"]
}
```

- [ ] **Step 3: Add the crafted outcome items that make the new graph visible**

Append these rows to `game/data/items.json`:

```json
{
  "id": "sealed_window_patch",
  "name": "밀봉 보수 패치",
  "bulk": 1,
  "description": "얇은 막과 실링제를 이어 만든 틈막이 패치다.",
  "usage_hint": "창문 틈새나 얇은 패널 보수에 쓰는 완성형 패치다.",
  "cold_hint": "찬 바람을 줄이는 데 직접 도움이 되는 결과물이다.",
  "category": "utility",
  "item_tags": ["utility", "seal", "crafted_item"]
},
{
  "id": "transfer_hose",
  "name": "이송 호스",
  "bulk": 1,
  "description": "호스 밴드로 끝단을 고정한 임시 이송 호스다.",
  "usage_hint": "용기와 함께 액체를 옮기는 데 쓸 수 있다.",
  "cold_hint": "직접 따뜻하진 않지만 자원 확보 루프를 넓혀 주는 제작물이다.",
  "category": "utility",
  "item_tags": ["utility", "fluid", "crafted_item"]
},
{
  "id": "patched_blanket",
  "name": "기운 담요",
  "bulk": 2,
  "description": "헤진 부분을 꿰매 다시 쓸 수 있게 만든 담요다.",
  "usage_hint": "휴식이나 보온 조합에서 다시 쓸 수 있는 생활 보온 물건이다.",
  "cold_hint": "추위에 직접 대응하는 보온 결과물이다.",
  "category": "utility",
  "item_tags": ["utility", "warming", "crafted_item"]
},
{
  "id": "solvent_wipes",
  "name": "세척용 천 꾸러미",
  "bulk": 1,
  "description": "작업용 수건에 알코올을 적셔 만든 세척용 천이다.",
  "usage_hint": "오염된 표면을 닦거나 간단한 위생 처리에 쓸 수 있다.",
  "cold_hint": "보온보다는 위생과 정비에 가까운 제작 결과물이다.",
  "category": "medical",
  "item_tags": ["medical", "cleaning", "crafted_item"],
  "health_restore": 4,
  "use_minutes": 5
},
{
  "id": "tarp_bedroll",
  "name": "방수 침낭 꾸러미",
  "bulk": 3,
  "description": "담요와 방수포를 함께 묶어 만든 거친 보온 꾸러미다.",
  "usage_hint": "바닥 냉기와 눈을 줄이는 야전 보온 꾸러미다.",
  "cold_hint": "직접적으로 추위 대응에 도움이 되는 보온 결과물이다.",
  "category": "utility",
  "item_tags": ["utility", "warming", "crafted_item"]
},
{
  "id": "foil_tray_warmer",
  "name": "포일 트레이 보온기",
  "bulk": 1,
  "description": "포일 트레이와 작은 초를 조합한 간이 보온기다.",
  "usage_hint": "작은 열원을 바닥 받침과 반사판처럼 쓰는 데 적합하다.",
  "cold_hint": "강한 열원은 아니지만 몸 가까운 곳의 미세한 열 유지에 도움이 된다.",
  "category": "utility",
  "item_tags": ["utility", "warming", "crafted_item"]
},
{
  "id": "wrapped_hot_water_bottle",
  "name": "보온 감싼 물주머니",
  "bulk": 1,
  "description": "랩으로 표면을 감싸 열이 오래 가게 만든 물주머니다.",
  "usage_hint": "짧은 보온 도구보다 오래 따뜻함을 유지하는 데 목적이 있다.",
  "cold_hint": "직접 체감되는 보온 회복에 쓰는 결과물이다.",
  "category": "utility",
  "item_tags": ["drink", "warming", "crafted_item"],
  "use_effects": { "exposure_restore": 8 }
}
```

- [ ] **Step 4: Add the authored recipe rows that connect old and new items**

Append these rows to `game/data/crafting_combinations.json`:

```json
{
  "id": "clear_plastic_sheet__sealant_tube",
  "ingredients": ["clear_plastic_sheet", "sealant_tube"],
  "contexts": ["indoor"],
  "required_tags": [],
  "minutes": 20,
  "ingredient_rules": {
    "clear_plastic_sheet": "consume",
    "sealant_tube": "consume"
  },
  "result_items": [{ "id": "sealed_window_patch", "count": 1 }],
  "result_item_id": "sealed_window_patch",
  "indoor_minutes": 20
},
{
  "id": "hose_clamp__siphon_hose",
  "ingredients": ["hose_clamp", "siphon_hose"],
  "contexts": ["indoor"],
  "required_tags": [],
  "minutes": 20,
  "ingredient_rules": {
    "hose_clamp": "consume",
    "siphon_hose": "consume"
  },
  "result_items": [{ "id": "transfer_hose", "count": 1 }],
  "result_item_id": "transfer_hose",
  "indoor_minutes": 20
},
{
  "id": "old_blanket__sewing_kit",
  "ingredients": ["old_blanket", "sewing_kit"],
  "contexts": ["indoor"],
  "required_tags": [],
  "minutes": 25,
  "ingredient_rules": {
    "old_blanket": "consume",
    "sewing_kit": "keep"
  },
  "result_items": [{ "id": "patched_blanket", "count": 1 }],
  "result_item_id": "patched_blanket",
  "indoor_minutes": 25
},
{
  "id": "rubbing_alcohol__shop_towel_bundle",
  "ingredients": ["rubbing_alcohol", "shop_towel_bundle"],
  "contexts": ["indoor"],
  "required_tags": [],
  "minutes": 15,
  "ingredient_rules": {
    "rubbing_alcohol": "consume",
    "shop_towel_bundle": "consume"
  },
  "result_items": [{ "id": "solvent_wipes", "count": 1 }],
  "result_item_id": "solvent_wipes",
  "indoor_minutes": 15
},
{
  "id": "old_blanket__tarp_sheet",
  "ingredients": ["old_blanket", "tarp_sheet"],
  "contexts": ["indoor"],
  "required_tags": [],
  "minutes": 25,
  "ingredient_rules": {
    "old_blanket": "consume",
    "tarp_sheet": "consume"
  },
  "result_items": [{ "id": "tarp_bedroll", "count": 1 }],
  "result_item_id": "tarp_bedroll",
  "indoor_minutes": 25
},
{
  "id": "foil_tray_pack__tea_light_candle",
  "ingredients": ["foil_tray_pack", "tea_light_candle"],
  "contexts": ["indoor"],
  "required_tags": [],
  "minutes": 15,
  "ingredient_rules": {
    "foil_tray_pack": "consume",
    "tea_light_candle": "consume"
  },
  "result_items": [{ "id": "foil_tray_warmer", "count": 1 }],
  "result_item_id": "foil_tray_warmer",
  "indoor_minutes": 15
},
{
  "id": "cling_wrap_roll__hot_water_bottle",
  "ingredients": ["cling_wrap_roll", "hot_water_bottle"],
  "contexts": ["indoor"],
  "required_tags": [],
  "minutes": 10,
  "ingredient_rules": {
    "cling_wrap_roll": "consume",
    "hot_water_bottle": "keep"
  },
  "result_items": [{ "id": "wrapped_hot_water_bottle", "count": 1 }],
  "result_item_id": "wrapped_hot_water_bottle",
  "indoor_minutes": 10
},
{
  "id": "empty_jerrycan__transfer_hose",
  "ingredients": ["empty_jerrycan", "transfer_hose"],
  "contexts": ["indoor"],
  "required_tags": [],
  "minutes": 10,
  "ingredient_rules": {
    "empty_jerrycan": "keep",
    "transfer_hose": "keep"
  },
  "result_items": [{ "id": "empty_jerrycan", "count": 1 }],
  "result_item_id": "empty_jerrycan",
  "indoor_minutes": 10
}
```

- [ ] **Step 5: Create the separate resource-request ledger**

Run:

```bash
mkdir -p /home/muhyeon_shin/packages/apocalypse/docs/resource_requests
```

Then create `docs/resource_requests/2026-04-20-indoor-depth-expansion-ledger.md`:

```markdown
# Indoor Depth Expansion Resource Ledger

## Buildings

| id | name | role | visual notes |
| --- | --- | --- | --- |
| mart_01 | 동네 마트 | tier 3 living-goods hub | rear stock room, cold shelf zone, office clutter |
| hardware_01 | 철물점 | tier 3 repair / materials hub | tool walls, workbench, locked back room |
| apartment_01 | 낡은 아파트 | tier 3 living vertical site | shared hallway, stairwell, boiler room, lived-in units |
| warehouse_01 | 창고 | tier 3 logistics reward site | shutter gate, pallet aisles, cage storage |
| garage_01 | 차고지 | linked logistics side site | half-open shutter, maintenance pit, greasy tools |

## New Items

| id | name | category | visual notes |
| --- | --- | --- | --- |
| butter_cookie_box | 버터 쿠키 상자 | food | old butter-cookie tin or paper snack box |
| instant_cocoa_mix | 코코아 믹스 | food | single-serve cocoa sachet |
| cling_wrap_roll | 랩 | utility | small plastic wrap roll |
| foil_tray_pack | 알루미늄 포일 트레이 | utility | stacked disposable foil trays |
| hand_warmer_pack | 핫팩 | medical | disposable heat pack sachet |
| sealant_tube | 실링제 튜브 | utility | squeezed sealant tube |
| hose_clamp | 호스 밴드 | utility | small metal hose clamp |
| rubber_gasket | 고무 개스킷 | utility | dark rubber sealing ring |
| epoxy_putty | 에폭시 퍼티 | utility | repair putty stick |
| sewing_kit | 반짇고리 | tool | compact sewing kit |
| knit_cap | 니트 모자 | equipment | thick knit cap |
| slippers | 실내 슬리퍼 | equipment | worn indoor slippers |
| detergent_pod_pack | 세제 캡슐 | utility | detergent pod pouch |
| empty_jerrycan | 빈 제리캔 | utility | empty fuel can |
| siphon_hose | 사이펀 호스 | utility | flexible clear hose |
| shop_towel_bundle | 작업용 수건 묶음 | utility | greasy folded shop towels |
| tarp_sheet | 방수포 | utility | folded dark tarp |
| drain_funnel | 깔때기 | utility | oil funnel or plastic funnel |
| sealed_window_patch | 밀봉 보수 패치 | utility | patched plastic sealing kit |
| transfer_hose | 이송 호스 | utility | hose with clamp assembly |
| patched_blanket | 기운 담요 | equipment | stitched blanket |
| solvent_wipes | 세척용 천 꾸러미 | medical | alcohol-soaked rag bundle |
| tarp_bedroll | 방수 침낭 꾸러미 | equipment | tarp-wrapped bedroll |
| foil_tray_warmer | 포일 트레이 보온기 | utility | foil tray with tea light |
| wrapped_hot_water_bottle | 보온 감싼 물주머니 | drink | bottle wrapped in cling film / insulating wrap |
```

- [ ] **Step 6: Run the two content tests again and confirm they pass**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_content_depth.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
```

Expected:

- both tests pass, proving the new item and recipe surface exists

## Task 3: Deepen `mart_01` Into A Real Tier-3 Site

**Files:**
- Modify: `game/data/events/indoor/mart_01.json`

- [ ] **Step 1: Add deeper rear-site and office zones to the mart**

Extend `mart_01.json` so it includes these new zones in addition to the existing graph:

```json
{
  "id": "cold_storage",
  "floor_id": "floor_1",
  "label": "냉장 보관실",
  "summary": "꺼진 냉장고와 뒤집힌 아이스박스 사이로 아직 밀봉 식품이 남아 있다.",
  "connected_zone_ids": ["food_aisle", "back_hall"],
  "event_ids": ["cold_storage_search_event"],
  "map_position": [1, 3],
  "first_visit_cost": 30,
  "revisit_cost": 10
},
{
  "id": "manager_office",
  "floor_id": "floor_2",
  "label": "점장실",
  "summary": "금전함, 점포 일지, 자재 열쇠를 숨겨 둔 서랍이 보인다.",
  "connected_zone_ids": ["stair_landing"],
  "event_ids": ["manager_office_search_event"],
  "map_position": [5, 1],
  "first_visit_cost": 30,
  "revisit_cost": 10
},
{
  "id": "rear_stock_cage",
  "floor_id": "floor_2",
  "label": "후면 재고 케이지",
  "summary": "망으로 둘러친 재고 케이지 안에 포장재와 생활 물자가 남아 있다.",
  "connected_zone_ids": ["warehouse"],
  "event_ids": ["rear_stock_cage_event"],
  "map_position": [5, 3],
  "first_visit_cost": 30,
  "revisit_cost": 10,
  "access_requirements": {
    "required_item_ids": ["storage_key"]
  }
}
```

- [ ] **Step 2: Add search events that expose the new mart item family**

Add these events to `mart_01.json`:

```json
{
  "id": "cold_storage_search_event",
  "zone_id": "cold_storage",
  "type": "search",
  "hint_text": "꺼진 냉장고와 식품 상자 사이에 아직 봉지 음식과 음료 재료가 남아 있을 수 있다.",
  "options": [
    {
      "id": "search_cold_storage",
      "label": "냉장 보관실을 탐색한다",
      "requirements": {},
      "costs": { "minutes": 30, "noise": 0 },
      "outcomes": {
        "discover_loot": [],
        "loot_table": {
          "rolls": 3,
          "allow_duplicates": false,
          "entries": [
            { "id": "butter_cookie_box", "weight": 4 },
            { "id": "instant_cocoa_mix", "weight": 4 },
            { "id": "hand_warmer_pack", "weight": 2 },
            { "id": "canned_beans", "weight": 2 }
          ]
        },
        "consume_on_use": true
      }
    }
  ]
},
{
  "id": "manager_office_search_event",
  "zone_id": "manager_office",
  "type": "search",
  "hint_text": "서랍 안쪽에 열쇠와 재고 메모가 숨겨져 있을 수 있다.",
  "options": [
    {
      "id": "search_manager_office",
      "label": "점장실을 탐색한다",
      "requirements": {},
      "costs": { "minutes": 30, "noise": 0 },
      "outcomes": {
        "discover_loot": [
          { "id": "mart_stock_note_01", "name": "재고 정리 메모", "bulk": 1 }
        ],
        "loot_table": {
          "rolls": 2,
          "allow_duplicates": false,
          "entries": [
            { "id": "storage_key", "weight": 4 },
            { "id": "cling_wrap_roll", "weight": 3 },
            { "id": "foil_tray_pack", "weight": 3 }
          ]
        },
        "consume_on_use": true
      }
    }
  ]
}
```

- [ ] **Step 3: Run the dedicated depth test and indoor smoke**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_content_depth.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- mart now satisfies the higher zone-count target without breaking first playable flow

## Task 4: Deepen `hardware_01` Into A Real Tier-3 Site

**Files:**
- Modify: `game/data/events/indoor/hardware_01.json`

- [ ] **Step 1: Add a gated rear-room structure to the hardware store**

Extend `hardware_01.json` with:

```json
{
  "id": "stock_door",
  "floor_id": "floor_1",
  "label": "자재실 문",
  "summary": "안쪽 자재실 문에는 작은 자물쇠가 걸려 있다.",
  "connected_zone_ids": ["parts_shelf", "material_room"],
  "event_ids": ["stock_door_event"],
  "map_position": [2, 0],
  "first_visit_cost": 20,
  "revisit_cost": 10
},
{
  "id": "material_room",
  "floor_id": "floor_1",
  "label": "자재실",
  "summary": "밀봉재, 고무 부품, 금속 부속 상자가 정리된 채 남아 있다.",
  "connected_zone_ids": ["stock_door", "receiving_bay"],
  "event_ids": ["material_room_search_event"],
  "map_position": [3, 0],
  "first_visit_cost": 30,
  "revisit_cost": 10,
  "access_requirements": {
    "required_item_ids": ["hardware_backroom_key"]
  }
},
{
  "id": "receiving_bay",
  "floor_id": "floor_1",
  "label": "후면 적재 공간",
  "summary": "반쯤 뜯긴 상자와 묶음 자재가 남아 있는 작은 적재 공간이다.",
  "connected_zone_ids": ["material_room", "workbench"],
  "event_ids": ["receiving_bay_search_event"],
  "map_position": [3, 1],
  "first_visit_cost": 30,
  "revisit_cost": 10
}
```

- [ ] **Step 2: Add the hardware-store-specific key and item loop**

Add these events:

```json
{
  "id": "stock_door_event",
  "zone_id": "stock_door",
  "type": "search",
  "hint_text": "카운터 뒤쪽 못 상자와 걸쇠 주변에 자재실 열쇠가 숨겨졌을 수 있다.",
  "options": [
    {
      "id": "search_stock_door_cache",
      "label": "문 주변을 더듬어 본다",
      "requirements": {},
      "costs": { "minutes": 20, "noise": 0 },
      "outcomes": {
        "discover_loot": [{ "id": "hardware_backroom_key", "name": "철물점 뒷방 열쇠", "bulk": 1 }],
        "consume_on_use": true
      }
    }
  ]
},
{
  "id": "material_room_search_event",
  "zone_id": "material_room",
  "type": "search",
  "hint_text": "밀봉재와 배관 부속, 금속 부품이 아직 정리된 채 남아 있다.",
  "options": [
    {
      "id": "search_material_room",
      "label": "자재실을 탐색한다",
      "requirements": {},
      "costs": { "minutes": 30, "noise": 0 },
      "outcomes": {
        "discover_loot": [],
        "loot_table": {
          "rolls": 4,
          "allow_duplicates": false,
          "entries": [
            { "id": "sealant_tube", "weight": 4 },
            { "id": "hose_clamp", "weight": 4 },
            { "id": "rubber_gasket", "weight": 3 },
            { "id": "epoxy_putty", "weight": 3 }
          ]
        },
        "consume_on_use": true
      }
    }
  ]
}
```

- [ ] **Step 3: Re-run the content and smoke checks**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_content_depth.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
```

Expected:

- `hardware_01` meets its new depth target and the new hardware items/recipes remain loadable

## Task 5: Deepen `apartment_01` Into A Real Tier-3 Living Site

**Files:**
- Modify: `game/data/events/indoor/apartment_01.json`

- [ ] **Step 1: Add a basement utility route and one additional upper-room branch**

Extend `apartment_01.json` with:

```json
{
  "id": "basement_door",
  "floor_id": "floor_1",
  "label": "지하 보일러실 문",
  "summary": "계단 밑 철문 너머로 오래된 보일러 소리가 멈춘 흔적만 남아 있다.",
  "connected_zone_ids": ["stairwell", "boiler_room"],
  "event_ids": [],
  "map_position": [2, 3],
  "first_visit_cost": 20,
  "revisit_cost": 10
},
{
  "id": "boiler_room",
  "floor_id": "floor_b1",
  "label": "보일러실",
  "summary": "빈 온수통과 세탁 세제, 보수 천이 남아 있는 지하 보일러실이다.",
  "connected_zone_ids": ["basement_door"],
  "event_ids": ["boiler_room_search_event"],
  "map_position": [3, 3],
  "first_visit_cost": 30,
  "revisit_cost": 10,
  "access_requirements": {
    "required_item_ids": ["apartment_boiler_key"]
  }
},
{
  "id": "unit_201_side_room",
  "floor_id": "floor_2",
  "label": "201호 작은 방",
  "summary": "작은 서랍장과 반쯤 접힌 담요, 바느질 도구가 남아 있다.",
  "connected_zone_ids": ["unit_201_room"],
  "event_ids": ["unit_201_side_room_search_event"],
  "map_position": [6, 2],
  "first_visit_cost": 20,
  "revisit_cost": 10
}
```

- [ ] **Step 2: Add living-site item loops**

Add these events:

```json
{
  "id": "laundry_room_search_event_v2",
  "zone_id": "laundry_room",
  "type": "search",
  "hint_text": "세탁실 선반에는 세제와 생활 잡화가 남아 있을 수 있다.",
  "options": [
    {
      "id": "search_laundry_room_v2",
      "label": "세탁실 선반을 뒤진다",
      "requirements": {},
      "costs": { "minutes": 30, "noise": 0 },
      "outcomes": {
        "discover_loot": [],
        "loot_table": {
          "rolls": 3,
          "allow_duplicates": false,
          "entries": [
            { "id": "detergent_pod_pack", "weight": 4 },
            { "id": "slippers", "weight": 3 },
            { "id": "towel", "weight": 2 }
          ]
        },
        "consume_on_use": true
      }
    }
  ]
},
{
  "id": "unit_201_side_room_search_event",
  "zone_id": "unit_201_side_room",
  "type": "search",
  "hint_text": "작은 생활 도구와 겨울용 옷이 남아 있다.",
  "options": [
    {
      "id": "search_unit_201_side_room",
      "label": "작은 방을 탐색한다",
      "requirements": {},
      "costs": { "minutes": 30, "noise": 0 },
      "outcomes": {
        "discover_loot": [],
        "loot_table": {
          "rolls": 3,
          "allow_duplicates": false,
          "entries": [
            { "id": "sewing_kit", "weight": 4 },
            { "id": "knit_cap", "weight": 3 },
            { "id": "old_blanket", "weight": 2 }
          ]
        },
        "consume_on_use": true
      }
    }
  ]
},
{
  "id": "boiler_room_search_event",
  "zone_id": "boiler_room",
  "type": "search",
  "hint_text": "보일러실 구석에는 세척제와 낡은 수건, 열쇠가 남아 있을 수 있다.",
  "options": [
    {
      "id": "search_boiler_room",
      "label": "보일러실을 탐색한다",
      "requirements": {},
      "costs": { "minutes": 30, "noise": 0 },
      "outcomes": {
        "discover_loot": [{ "id": "apartment_boiler_key", "name": "보일러실 열쇠", "bulk": 1 }],
        "loot_table": {
          "rolls": 2,
          "allow_duplicates": false,
          "entries": [
            { "id": "detergent_pod_pack", "weight": 3 },
            { "id": "shop_towel_bundle", "weight": 2 },
            { "id": "bottled_water", "weight": 2 }
          ]
        },
        "consume_on_use": true
      }
    }
  ]
}
```

- [ ] **Step 3: Verify apartment depth and regression**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_content_depth.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- apartment depth target passes and first-playable flow still boots

## Task 6: Deepen The Linked Logistics Site (`warehouse_01` + `garage_01`)

**Files:**
- Modify: `game/data/events/indoor/warehouse_01.json`
- Modify: `game/data/events/indoor/garage_01.json`

- [ ] **Step 1: Expand warehouse and garage into linked multi-zone sites**

Replace the one-zone warehouse and garage shells with these minimum structures:

```json
{
  "warehouse_zones": [
    "loading",
    "pallet_aisle",
    "cage_storage",
    "shutter_inner"
  ],
  "garage_zones": [
    "garage_floor",
    "tool_cabinet",
    "maintenance_pit"
  ]
}
```

Use this access rule:

```json
{
  "access_requirements": {
    "required_item_ids": ["warehouse_shutter_key"]
  }
}
```

The key itself should be discoverable in `garage_01`, so the garage acts as the first half of the logistics loop and `warehouse_01` acts as the better payoff site.

- [ ] **Step 2: Add logistics-site loot and recipe-support items**

Use these event payloads as the core new loops:

```json
{
  "garage_key_cache": {
    "discover_loot": [{ "id": "warehouse_shutter_key", "name": "셔터 열쇠", "bulk": 1 }],
    "loot_table": {
      "rolls": 3,
      "allow_duplicates": false,
      "entries": [
        { "id": "siphon_hose", "weight": 4 },
        { "id": "hose_clamp", "weight": 3 },
        { "id": "drain_funnel", "weight": 3 },
        { "id": "work_gloves", "weight": 2 }
      ]
    }
  },
  "warehouse_inner_cache": {
    "loot_table": {
      "rolls": 4,
      "allow_duplicates": false,
      "entries": [
        { "id": "empty_jerrycan", "weight": 4 },
        { "id": "shop_towel_bundle", "weight": 4 },
        { "id": "tarp_sheet", "weight": 3 },
        { "id": "spare_batteries", "weight": 2 }
      ]
    }
  }
}
```

- [ ] **Step 3: Re-run content, controller, and smoke coverage**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_content_depth.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- logistics-site depth and items are now contractual and smoke still passes

## Task 7: Lift The Remaining Shallow Buildings And Add Outdoor Entry Briefings

**Files:**
- Modify: `game/data/buildings.json`
- Modify: the one-zone indoor files listed in **File Structure**
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Add shared depth and briefing metadata to buildings**

Extend the relevant rows in `game/data/buildings.json` like this:

```json
{
  "id": "hardware_01",
  "name": "철물점",
  "category": "retail",
  "depth_tier": "tier_3",
  "site_tags": ["repair", "materials", "gated_backroom"],
  "entry_briefing": "앞쪽은 금방 훑을 수 있지만 안쪽 자재실은 따로 잠겨 있다.",
  "base_candidate": false,
  "outdoor_block_coord": { "x": 1, "y": 1 },
  "outdoor_anchor_id": "hardware_anchor",
  "indoor_event_path": "res://data/events/indoor/hardware_01.json"
}
```

For the uplifted shallow buildings, use `depth_tier: "tier_2"` plus one short `entry_briefing` sentence describing what makes the site different.

- [ ] **Step 2: Batch-uplift the shallow one-zone sites into minimum two-zone interiors**

Apply one of these exact uplift patterns to every currently one-zone indoor file:

```json
{
  "shop_two_zone_pattern": {
    "entry_zone_id": "front_room",
    "zones": [
      {
        "id": "front_room",
        "label": "앞쪽 매장",
        "connected_zone_ids": ["back_room"],
        "event_ids": ["front_room_search_event"]
      },
      {
        "id": "back_room",
        "label": "안쪽 창고",
        "connected_zone_ids": ["front_room"],
        "event_ids": ["back_room_search_event"]
      }
    ]
  },
  "public_room_pattern": {
    "entry_zone_id": "main_room",
    "zones": [
      {
        "id": "main_room",
        "label": "안쪽 홀",
        "connected_zone_ids": ["side_room"],
        "event_ids": ["main_room_search_event"]
      },
      {
        "id": "side_room",
        "label": "안쪽 방",
        "connected_zone_ids": ["main_room"],
        "event_ids": ["side_room_search_event"]
      }
    ]
  }
}
```

Use the shop pattern for:

- `bakery_01`
- `bookstore_01`
- `butcher_01`
- `corner_store_01`
- `deli_01`
- `pharmacy_01`
- `repair_shop_01`
- `tea_shop_01`

Use the public-room pattern for:

- `cafe_01`
- `canteen_01`
- `chapel_01`
- `church_01`
- `restaurant_01`

Use an entry-plus-inner-room variant for:

- `hostel_01`
- `police_box_01`
- `residence_01`
- `row_house_01`
- `school_gate_01`
- `storage_depot_01`

- [ ] **Step 3: Replace the generic outdoor enter text with a real entry briefing**

In `game/scripts/outdoor/outdoor_controller.gd`, replace the current nearby-building hint:

```gdscript
_hint_label.text = "[E] %s 진입" % String(nearby_building_data.get("name", "건물"))
```

with:

```gdscript
var building_name := String(nearby_building_data.get("name", "건물"))
var briefing := String(nearby_building_data.get("entry_briefing", ""))
if briefing.is_empty():
	_hint_label.text = "[E] %s 진입" % building_name
else:
	_hint_label.text = "[E] %s 진입 · %s" % [building_name, briefing]
```

Then extend `game/tests/unit/test_outdoor_controller.gd` with:

```gdscript
	var building_row := controller._get_building_data("hardware_01")
	assert_true(not String(building_row.get("entry_briefing", "")).is_empty(), "Hardware store should expose an entry briefing after the indoor-depth pass.")
```

- [ ] **Step 4: Run the shallow-site, controller, and smoke tests**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_content_depth.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- shallow buildings are no longer one-zone shells
- outdoor entry briefings load correctly
- smoke remains stable

## Task 8: Final Documentation Sweep, Full Verification, And Wrap-Up Commit

**Files:**
- Modify: `docs/CURRENT_STATE.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/resource_requests/2026-04-20-indoor-depth-expansion-ledger.md`

- [ ] **Step 1: Update routing docs so the pass becomes discoverable**

Add this plan to the top of the active plans list in both files:

```markdown
- [Indoor Depth and Item Expansion](superpowers/plans/2026-04-20-indoor-depth-item-expansion.md)
```

And add this immediate-priority note to `docs/CURRENT_STATE.md` if it is not already present:

```markdown
- Deepen the authored building set before pushing outdoor radius again: anchor four buildings into real multi-zone sites, lift the shallow shells, and thicken the item dictionary with site-specific finds.
```

- [ ] **Step 2: Run the full verification batch**

Run:

```bash
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_content_depth.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
HOME=/tmp /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- every command exits `0`
- no regressions in indoor UI, content loading, outdoor entry, or smoke flow

- [ ] **Step 3: Create the single wrap-up commit after the full pass is verified**

Run:

```bash
git add docs/CURRENT_STATE.md docs/INDEX.md docs/resource_requests/2026-04-20-indoor-depth-expansion-ledger.md \
  game/data/items.json game/data/crafting_combinations.json game/data/buildings.json \
  game/data/events/indoor/*.json game/scripts/outdoor/outdoor_controller.gd \
  game/tests/unit/test_content_library.gd game/tests/unit/test_indoor_content_depth.gd \
  game/tests/unit/test_outdoor_controller.gd game/tests/smoke/test_first_playable_loop.gd
git commit -m "feat: deepen indoor sites and expand item ecology"
```
