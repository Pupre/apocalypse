extends RefCounted

const BASE_UI_KIT_ROOT := "res://../resources/ui/base"
const BASE_MANIFEST_PATH := BASE_UI_KIT_ROOT + "/ui_manifest.json"
const MASTER_UI_KIT_ROOT := "res://../resources/ui/master"
const MASTER_MANIFEST_PATH := MASTER_UI_KIT_ROOT + "/master_manifest.json"
const PATH_ALIASES := {
	"hud/hud_header_chip_compact.png": "@master/hud/hud_header_chip_compact.png",
	"hud/hud_gauge_strip_compact.png": "@master/hud/hud_gauge_strip_compact.png",
	"hud/gauge_frame_short_compact.png": "@master/hud/gauge_frame_short_compact.png",
	"hud/gauge_fill_health.png": "@master/hud/gauge_fill_health.png",
	"hud/gauge_fill_hunger.png": "@master/hud/gauge_fill_hunger.png",
	"hud/gauge_fill_thirst.png": "@master/hud/gauge_fill_thirst.png",
	"hud/gauge_fill_fatigue.png": "@master/hud/gauge_fill_fatigue.png",
	"hud/gauge_fill_cold.png": "@master/hud/gauge_fill_cold.png",
	"hud/hud_status_pill.png": "@master/hud/hud_status_pill.png",
	"hud/hud_divider_subtle.png": "@master/hud/hud_divider_subtle.png",
	"hud/hud_icon_button_compact_normal.png": "@master/hud/hud_icon_button_compact_normal.png",
	"hud/hud_icon_button_compact_pressed.png": "@master/hud/hud_icon_button_compact_pressed.png",
	"hud/hud_icon_button_compact_disabled.png": "@master/hud/hud_icon_button_compact_disabled.png",
	"hud/hud_icon_button_compact_active.png": "@master/hud/hud_icon_button_compact_normal.png",
	"top_hud/hud_button_normal.png": "hud/hud_icon_button_compact_normal.png",
	"top_hud/hud_button_pressed.png": "hud/hud_icon_button_compact_pressed.png",
	"top_hud/hud_button_active.png": "hud/hud_icon_button_compact_normal.png",
	"top_hud/hud_button_disabled.png": "hud/hud_icon_button_compact_disabled.png",
	"top_hud/gauge_frame_short.png": "hud/gauge_frame_short_compact.png",
	"top_hud/gauge_fill_health.png": "hud/gauge_fill_health.png",
	"top_hud/gauge_fill_hunger.png": "hud/gauge_fill_hunger.png",
	"top_hud/gauge_fill_thirst.png": "hud/gauge_fill_thirst.png",
	"top_hud/gauge_fill_fatigue.png": "hud/gauge_fill_fatigue.png",
	"top_hud/gauge_fill_cold.png": "hud/gauge_fill_cold.png",
	"top_hud/hud_status_pill.png": "hud/hud_status_pill.png",
	"overlay/overlay_map_panel_clean.png": "@master/overlay/overlay_map_panel_clean.png",
	"overlay/overlay_building_detail_panel.png": "@master/overlay/overlay_building_detail_panel.png",
	"overlay/overlay_close_button_compact_normal.png": "@master/overlay/overlay_close_button_compact_normal.png",
	"overlay/overlay_close_button_compact_pressed.png": "@master/overlay/overlay_close_button_compact_pressed.png",
	"overlay/overlay_zoom_plus.png": "@master/overlay/overlay_zoom_plus.png",
	"overlay/overlay_zoom_minus.png": "@master/overlay/overlay_zoom_minus.png",
	"overlay/map_info_chip.png": "@master/overlay/map_info_chip.png",
	"overlay_map/map_panel_bg.png": "overlay/overlay_map_panel_clean.png",
	"overlay_map/building_detail_panel.png": "overlay/overlay_building_detail_panel.png",
	"overlay_map/map_detail_card.png": "overlay/map_info_chip.png",
	"sheet/sheet_bg_compact.png": "@master/sheet/sheet_bg_compact.png",
	"sheet/detail_panel_compact.png": "@master/sheet/sheet_detail_panel_compact.png",
	"sheet/sheet_header_strip_compact.png": "@master/sheet/sheet_header_strip_compact.png",
	"sheet/sheet_tab_compact_idle.png": "@master/sheet/sheet_tab_compact_idle.png",
	"sheet/sheet_tab_compact_active.png": "@master/sheet/sheet_tab_compact_active.png",
	"sheet/inventory_icon_slot.png": "@master/sheet/inventory_icon_slot.png",
	"sheet/inventory_row_compact_idle.png": "@master/sheet/inventory_row_compact_idle.png",
	"sheet/inventory_row_compact_selected.png": "@master/sheet/inventory_row_compact_selected.png",
	"sheet/inventory_row_compact_highlighted.png": "@master/sheet/inventory_row_compact_highlighted.png",
	"sheet/craft_card_attached.png": "@master/sheet/craft_card_attached.png",
	"sheet/sheet_button_primary_normal.png": "@master/sheet/sheet_button_secondary_normal.png",
	"sheet/sheet_button_primary_pressed.png": "@master/sheet/sheet_button_secondary_pressed.png",
	"sheet/sheet_button_secondary_normal.png": "@master/sheet/sheet_button_secondary_normal.png",
	"sheet/sheet_button_secondary_pressed.png": "@master/sheet/sheet_button_secondary_pressed.png",
	"sheet_set/sheet_bg_large.png": "sheet/sheet_bg_compact.png",
	"sheet_set/sheet_detail_panel.png": "sheet/detail_panel_compact.png",
	"sheet_set/craft_tab_card.png": "sheet/craft_card_attached.png",
	"sheet_set/item_row_idle.png": "sheet/inventory_row_compact_idle.png",
	"sheet_set/item_row_selected.png": "sheet/inventory_row_compact_selected.png",
	"sheet_set/item_row_highlighted.png": "sheet/inventory_row_compact_highlighted.png",
	"sheet_set/action_button_primary_normal.png": "sheet/sheet_button_secondary_normal.png",
	"sheet_set/action_button_primary_pressed.png": "sheet/sheet_button_secondary_pressed.png",
	"sheet_set/action_button_secondary_normal.png": "sheet/sheet_button_secondary_normal.png",
	"sheet_set/action_button_secondary_pressed.png": "sheet/sheet_button_secondary_pressed.png",
	"sheet_set/sheet_tab_active.png": "sheet/sheet_tab_compact_active.png",
	"sheet_set/sheet_tab_idle.png": "sheet/sheet_tab_compact_idle.png",
	"indoor_cards/action_row_idle.png": "indoor/indoor_action_row_compact_idle.png",
	"indoor_cards/action_row_pressed.png": "indoor/indoor_action_row_compact_pressed.png",
	"indoor/indoor_surface_panel_compact.png": "@master/indoor/indoor_surface_panel_compact.png",
	"indoor/indoor_location_strip_compact.png": "@master/indoor/indoor_location_strip_compact.png",
	"indoor/indoor_reading_panel_plain.png": "@master/indoor/indoor_reading_panel_plain.png",
	"indoor/indoor_minimap_frame.png": "@master/indoor/indoor_minimap_frame.png",
	"indoor/indoor_result_chip_compact.png": "@master/indoor/indoor_result_chip_compact.png",
	"indoor/indoor_section_header_plain_compact.png": "@master/indoor/indoor_section_header_plain_compact.png",
	"indoor/indoor_event_convenience_frozen.png": "@master/indoor/indoor_event_convenience_frozen.png",
	"indoor/indoor_event_medical_clinic.png": "@master/indoor/indoor_event_medical_clinic.png",
	"indoor/indoor_event_residential_stairwell.png": "@master/indoor/indoor_event_residential_stairwell.png",
	"indoor/indoor_event_industrial_garage.png": "@master/indoor/indoor_event_industrial_garage.png",
	"indoor/indoor_event_food_kitchen.png": "@master/indoor/indoor_event_food_kitchen.png",
	"structure/structure_panel_bg.png": "@master/structure/structure_panel_bg.png",
	"structure/structure_room_node_known.png": "@master/structure/structure_room_node_known.png",
	"structure/structure_room_node_current.png": "@master/structure/structure_room_node_current.png",
	"structure/structure_room_node_unknown.png": "@master/structure/structure_room_node_unknown.png",
	"structure/structure_room_link_line.png": "@master/structure/structure_room_link_line.png",
	"structure/structure_room_link_locked.png": "@master/structure/structure_room_link_locked.png",
	"feedback/toast_info.png": "@master/feedback/toast_info.png",
	"feedback/toast_success.png": "@master/feedback/toast_success.png",
	"feedback/toast_warning.png": "@master/feedback/toast_warning.png",
	"feedback/status_chip_fire.png": "@master/feedback/status_chip_fire.png",
	"feedback/status_chip_cold.png": "@master/feedback/status_chip_cold.png",
	"feedback/status_chip_danger.png": "@master/feedback/status_chip_danger.png",
	"feedback/status_chip_overweight.png": "@master/feedback/status_chip_overweight.png",
	"feedback/frost_screen_overlay.png": "@master/feedback/frost_screen_overlay_phone_ice.png",
	"feedback/frost_screen_overlay_phone_ice.png": "@master/feedback/frost_screen_overlay_phone_ice.png",
}

var _manifest_loaded := false
var _manifest: Dictionary = {}
var _texture_cache: Dictionary = {}
var _stylebox_cache: Dictionary = {}


func get_texture(relative_path: String) -> Texture2D:
	if relative_path.is_empty():
		return null
	var resolved_path := _resolve_asset_path(relative_path)
	if _texture_cache.has(resolved_path):
		return _texture_cache[resolved_path] as Texture2D

	var root_info := _root_for_path(resolved_path)
	var absolute_path := ProjectSettings.globalize_path("%s/%s" % [String(root_info.get("root", "")), String(root_info.get("path", ""))])
	if not FileAccess.file_exists(absolute_path):
		return null

	var image := Image.new()
	if image.load(absolute_path) != OK:
		return null

	var texture := ImageTexture.create_from_image(image)
	_texture_cache[resolved_path] = texture
	return texture


func get_stylebox(relative_path: String, draw_center: bool = true) -> StyleBoxTexture:
	var resolved_path := _resolve_asset_path(relative_path)
	var cache_key := "%s::%s" % [resolved_path, str(draw_center)]
	if _stylebox_cache.has(cache_key):
		return _stylebox_cache[cache_key] as StyleBoxTexture

	var texture := get_texture(resolved_path)
	if texture == null:
		return null

	var style := StyleBoxTexture.new()
	style.texture = texture
	style.draw_center = draw_center

	var slice := _recommended_slice(resolved_path)
	if not slice.is_empty():
		style.texture_margin_left = int(slice.get("left", 0))
		style.texture_margin_top = int(slice.get("top", 0))
		style.texture_margin_right = int(slice.get("right", 0))
		style.texture_margin_bottom = int(slice.get("bottom", 0))

	_stylebox_cache[cache_key] = style
	return style


func apply_panel(panel: Control, relative_path: String) -> void:
	if panel == null:
		return
	var style := get_stylebox(relative_path)
	if style != null:
		panel.add_theme_stylebox_override("panel", style)


func apply_button(
	button: Button,
	normal_path: String,
	pressed_path: String,
	hover_path: String = "",
	disabled_path: String = "",
	focus_path: String = ""
) -> void:
	if button == null:
		return
	var normal_style := get_stylebox(normal_path)
	var pressed_style := get_stylebox(pressed_path if not pressed_path.is_empty() else normal_path)
	var hover_style := get_stylebox(hover_path if not hover_path.is_empty() else normal_path)
	var disabled_style := get_stylebox(disabled_path if not disabled_path.is_empty() else normal_path)
	var focus_style := get_stylebox(focus_path if not focus_path.is_empty() else normal_path)
	if normal_style != null:
		button.add_theme_stylebox_override("normal", normal_style)
	if pressed_style != null:
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_stylebox_override("hover_pressed", pressed_style)
	if hover_style != null:
		button.add_theme_stylebox_override("hover", hover_style)
	if disabled_style != null:
		button.add_theme_stylebox_override("disabled", disabled_style)
	if focus_style != null:
		button.add_theme_stylebox_override("focus", focus_style)


func apply_progress_bar(bar: ProgressBar, frame_path: String, fill_path: String) -> void:
	if bar == null:
		return
	var background := get_stylebox(frame_path)
	var fill := get_stylebox(fill_path)
	if background != null:
		bar.add_theme_stylebox_override("background", background)
	if fill != null:
		bar.add_theme_stylebox_override("fill", fill)


func _recommended_slice(relative_path: String) -> Dictionary:
	var resolved_path := _resolve_asset_path(relative_path)
	_ensure_manifest_loaded()
	var entry_variant: Variant = _manifest.get(resolved_path, {})
	if typeof(entry_variant) != TYPE_DICTIONARY:
		return {}
	return (entry_variant as Dictionary).get("recommended_9slice", {}) as Dictionary


func _ensure_manifest_loaded() -> void:
	if _manifest_loaded:
		return
	_manifest_loaded = true
	_load_base_manifest()
	_load_master_manifests()

func _load_base_manifest() -> void:
	var absolute_path := ProjectSettings.globalize_path(BASE_MANIFEST_PATH)
	if not FileAccess.file_exists(absolute_path):
		return

	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var parsed_dict := parsed as Dictionary
	for asset_variant in parsed_dict.get("assets", []):
		if typeof(asset_variant) != TYPE_DICTIONARY:
			continue
		var asset := asset_variant as Dictionary
		var file_path := String(asset.get("file", ""))
		if file_path.is_empty():
			continue
		_manifest["@base/%s" % file_path] = {
			"recommended_9slice": _extract_nine_slice(asset.get("nine_slice", null)),
		}


func _load_master_manifests() -> void:
	var absolute_path := ProjectSettings.globalize_path(MASTER_MANIFEST_PATH)
	if not FileAccess.file_exists(absolute_path):
		return
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var parsed_dict := parsed as Dictionary
	for pack_variant in parsed_dict.get("packs", []):
		if typeof(pack_variant) != TYPE_DICTIONARY:
			continue
		var pack := pack_variant as Dictionary
		_load_master_pack_manifest(String(pack.get("pack_folder", "")), String(pack.get("manifest", "")))


func _load_master_pack_manifest(pack_folder: String, manifest_name: String) -> void:
	if pack_folder.is_empty() or manifest_name.is_empty():
		return
	var manifest_path := "%s/%s/%s" % [MASTER_UI_KIT_ROOT, pack_folder, manifest_name]
	var absolute_path := ProjectSettings.globalize_path(manifest_path)
	if not FileAccess.file_exists(absolute_path):
		return
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var parsed_dict := parsed as Dictionary
	for asset_variant in parsed_dict.get("assets", []):
		if typeof(asset_variant) != TYPE_DICTIONARY:
			continue
		var asset := asset_variant as Dictionary
		var filename := String(asset.get("filename", ""))
		if filename.is_empty():
			continue
		var manifest_key := "@master/%s/%s" % [pack_folder, filename]
		_manifest[manifest_key] = {
			"recommended_9slice": _extract_nine_slice(asset.get("nine_slice", null)),
		}


func _extract_nine_slice(nine_slice_variant: Variant) -> Dictionary:
	var recommended_9slice := {}
	if typeof(nine_slice_variant) == TYPE_ARRAY:
		var nine_slice := nine_slice_variant as Array
		if nine_slice.size() == 4:
			recommended_9slice = {
				"left": int(nine_slice[0]),
				"right": int(nine_slice[1]),
				"top": int(nine_slice[2]),
				"bottom": int(nine_slice[3]),
			}
	elif typeof(nine_slice_variant) == TYPE_DICTIONARY:
		var slice_dict := nine_slice_variant as Dictionary
		recommended_9slice = {
			"left": int(slice_dict.get("left", 0)),
			"right": int(slice_dict.get("right", 0)),
			"top": int(slice_dict.get("top", 0)),
			"bottom": int(slice_dict.get("bottom", 0)),
		}
	return recommended_9slice


func _resolve_asset_path(relative_path: String) -> String:
	var current := relative_path
	var visited := {}
	while PATH_ALIASES.has(current) and not visited.has(current):
		visited[current] = true
		current = String(PATH_ALIASES.get(current, current))
	return current


func _root_for_path(resolved_path: String) -> Dictionary:
	if resolved_path.begins_with("@master/"):
		return {
			"root": MASTER_UI_KIT_ROOT,
			"path": resolved_path.trim_prefix("@master/"),
		}
	if resolved_path.begins_with("@base/"):
		return {
			"root": BASE_UI_KIT_ROOT,
			"path": resolved_path.trim_prefix("@base/"),
		}
	return {
		"root": BASE_UI_KIT_ROOT,
		"path": resolved_path,
	}
