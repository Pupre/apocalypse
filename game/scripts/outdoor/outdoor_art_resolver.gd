extends RefCounted
class_name OutdoorArtResolver

const PACK_ROOT := "res://../resources/world/city"
const TERRAIN_DIR := "%s/terrain" % PACK_ROOT
const BUILDING_DIR := "%s/buildings_cutout" % PACK_ROOT
const PROP_DIR := "%s/props_cutout" % PACK_ROOT
const DECAL_DIR := "%s/decals" % PACK_ROOT
const PLAYER_DIR := "%s/player" % PACK_ROOT
const PLAYER_WALK_FRAME_COUNT := 8

var _texture_cache: Dictionary = {}


func get_building_texture(building_data: Dictionary) -> Texture2D:
	var building_id := String(building_data.get("id", ""))
	var file_name := "building_office.png"

	match building_id:
		"mart_01":
			file_name = "building_mart.png"
		"convenience_01":
			file_name = "building_convenience.png"
		"apartment_01", "residence_01":
			file_name = "building_apartment.png"
		"clinic_01":
			file_name = "building_clinic.png"
		"pharmacy_01":
			file_name = "building_pharmacy.png"
		"office_01", "laundry_01":
			file_name = "building_office.png"
		"hardware_01", "warehouse_01":
			file_name = "building_warehouse.png"
		"repair_shop_01":
			file_name = "building_garage.png"
		"gas_station_01":
			file_name = "building_gas_station.png"
		"cafe_01", "restaurant_01":
			file_name = "building_cafe.png"
		"bakery_01":
			file_name = "building_bakery.png"
		"police_box_01":
			file_name = "building_police.png"
		"bookstore_01":
			file_name = "building_bookstore.png"
		"deli_01":
			file_name = "building_deli.png"
		"butcher_01":
			file_name = "building_butcher.png"
		"hostel_01":
			file_name = "building_hostel.png"
		"storage_depot_01":
			file_name = "building_storage_depot.png"
		"garage_01":
			file_name = "building_garage.png"
		"canteen_01":
			file_name = "building_canteen.png"
		"church_01", "chapel_01":
			file_name = "building_church.png"
		"corner_store_01":
			file_name = "building_corner_store.png"
		"school_gate_01":
			file_name = "building_school.png"
		"row_house_01":
			file_name = "building_row_house.png"
		"tea_shop_01":
			file_name = "building_tea_shop.png"
		_:
			var category := String(building_data.get("category", ""))
			match category:
				"retail":
					file_name = "building_mart.png"
				"medical":
					file_name = "building_clinic.png"
				"residential":
					file_name = "building_apartment.png"
				"food_service":
					file_name = "building_cafe.png"
				"industrial":
					file_name = "building_warehouse.png"
				"security":
					file_name = "building_police.png"

	return _load_texture("%s/%s" % [BUILDING_DIR, file_name])


func get_prop_texture(obstacle_kind: String, obstacle_rect: Rect2 = Rect2(), asset_id: String = "") -> Texture2D:
	if not asset_id.is_empty():
		var explicit_file_name := asset_id if asset_id.ends_with(".png") else "%s.png" % asset_id
		var explicit_texture := _load_texture("%s/%s" % [PROP_DIR, explicit_file_name])
		if explicit_texture != null:
			return explicit_texture

	var file_name := "crate_stack.png"
	match obstacle_kind:
		"vehicle":
			file_name = "frozen_car.png"
		"rubble":
			file_name = "dumpster_snow.png" if obstacle_rect.size.x >= 100.0 or obstacle_rect.size.y >= 80.0 else "roadblock.png"
		"tree":
			file_name = "dead_tree.png"
		"barrier":
			file_name = "sandbags.png"
		"light":
			file_name = "street_lamp.png"
		"cart":
			file_name = "shopping_cart.png"
		"snow":
			file_name = "snow_drift.png"
		"fire":
			file_name = "barrel_fire.png"
		"cone":
			file_name = "traffic_cone.png"
		"sign":
			file_name = "bus_stop_sign.png"
	return _load_texture("%s/%s" % [PROP_DIR, file_name])


func get_player_texture(facing_id: String, walking: bool, frame_index: int = 0) -> Texture2D:
	var resolved_facing := facing_id if facing_id in ["up", "down", "left", "right"] else "down"
	var frame_suffix := "idle"
	if walking:
		frame_suffix = "walk%d" % (((frame_index % PLAYER_WALK_FRAME_COUNT) + PLAYER_WALK_FRAME_COUNT) % PLAYER_WALK_FRAME_COUNT + 1)
	return _load_texture("%s/%s_%s.png" % [PLAYER_DIR, resolved_facing, frame_suffix])


func get_terrain_texture(texture_id: String) -> Texture2D:
	var file_name := "%s.png" % texture_id
	return _load_texture("%s/%s" % [TERRAIN_DIR, file_name])


func get_decal_texture(texture_id: String) -> Texture2D:
	var file_name := "%s.png" % texture_id
	return _load_texture("%s/%s" % [DECAL_DIR, file_name])


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null

	var image := Image.new()
	var err := image.load(absolute_path)
	if err != OK:
		return null

	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture
