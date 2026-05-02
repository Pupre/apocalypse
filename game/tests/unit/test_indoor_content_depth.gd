extends "res://tests/support/test_case.gd"

const ANCHOR_MIN_ZONE_COUNTS := {
	"mart_01": 14,
	"hardware_01": 6,
	"apartment_01": 13,
	"warehouse_01": 4,
	"garage_01": 3,
	"restaurant_01": 3,
	"pharmacy_01": 3,
	"cafe_01": 3,
	"police_box_01": 3,
	"residence_01": 4,
	"bakery_01": 4,
	"bookstore_01": 4,
	"butcher_01": 4,
	"school_gate_01": 4,
	"corner_store_01": 4,
	"deli_01": 4,
	"repair_shop_01": 4,
	"storage_depot_01": 4,
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
	"wrapped_hot_water_bottle",
	"warm_cocoa",
	"sealed_warm_cocoa",
]

const REQUIRED_ACTION_IDS_BY_BUILDING := {
	"corner_store_01": [
		"search_corner_cashier_fast",
		"search_corner_cashier_with_gloves",
		"search_corner_rear_fridge",
	],
	"deli_01": [
		"search_deli_display_fast",
		"search_deli_display_with_gloves",
		"search_deli_cold_room",
	],
	"repair_shop_01": [
		"force_repair_tool_locker",
		"open_repair_tool_locker_with_screwdriver",
		"search_repair_service_bay_fast",
		"search_repair_service_bay_with_gloves",
	],
	"storage_depot_01": [
		"search_storage_office_cage",
		"search_storage_pallet_fast",
		"search_storage_pallet_with_gloves",
	],
}

const REQUIRED_ITEM_GATES_BY_ACTION := {
	"search_corner_cashier_with_gloves": ["work_gloves"],
	"search_deli_display_with_gloves": ["work_gloves"],
	"open_repair_tool_locker_with_screwdriver": ["screwdriver"],
	"search_repair_service_bay_with_gloves": ["work_gloves"],
	"search_storage_pallet_with_gloves": ["work_gloves"],
}


func _init() -> void:
	call_deferred("_run_test")


func _event_path_for(building_id: String) -> String:
	var content_library = root.get_node_or_null("ContentLibrary")
	if content_library == null:
		return ""
	var building: Dictionary = content_library.get_building(building_id)
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
		var content_library = root.get_node_or_null("ContentLibrary")
		assert_true(content_library != null, "ContentLibrary autoload should be registered.")
		var row: Dictionary = content_library.get_item(item_id)
		assert_true(not row.is_empty(), "Expected new item '%s' to exist." % item_id)

	for building_id in REQUIRED_ACTION_IDS_BY_BUILDING.keys():
		var event_data := _load_json(_event_path_for(building_id))
		assert_true(not event_data.is_empty(), "Expected event data for required action checks in '%s'." % building_id)
		for action_id in REQUIRED_ACTION_IDS_BY_BUILDING[building_id]:
			var option := _option_by_id(event_data, action_id)
			assert_true(not option.is_empty(), "Expected '%s' to expose action '%s'." % [building_id, action_id])
			var required_item_ids := _string_values((option.get("requirements", {}) as Dictionary).get("required_item_ids", []))
			for required_item_id in REQUIRED_ITEM_GATES_BY_ACTION.get(action_id, []):
				assert_true(required_item_ids.has(required_item_id), "Action '%s' should require '%s'." % [action_id, required_item_id])

	pass_test("INDOOR_CONTENT_DEPTH_OK")


func _option_by_id(event_data: Dictionary, option_id: String) -> Dictionary:
	for event_variant in event_data.get("events", []):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event := event_variant as Dictionary
		for option_variant in event.get("options", []):
			if typeof(option_variant) != TYPE_DICTIONARY:
				continue
			var option := option_variant as Dictionary
			if String(option.get("id", "")) == option_id:
				return option
	return {}


func _string_values(values) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
