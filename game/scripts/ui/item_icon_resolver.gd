extends RefCounted

const ICON_PACK_ROOT := "res://../resources/items/icons"
const MANIFEST_PATH := ICON_PACK_ROOT + "/item_icons_manifest.json"
const DEFAULT_ICON_VARIANT := "cutout_24"

var _manifest_loaded := false
var _icon_manifest: Dictionary = {}
var _texture_cache: Dictionary = {}


func get_item_icon(item_id: String, variant: String = DEFAULT_ICON_VARIANT) -> Texture2D:
	if item_id.is_empty():
		return null
	_ensure_manifest_loaded()
	var cache_key := "%s::%s" % [variant, item_id]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D

	var item_entry: Dictionary = _icon_manifest.get(item_id, {})
	if item_entry.is_empty():
		return null

	var relative_path := _relative_icon_path_for_variant(item_entry, variant)
	if relative_path.is_empty():
		return null

	var full_path := "%s/%s" % [ICON_PACK_ROOT, relative_path]
	var texture := _load_texture(full_path)
	if texture != null:
		_texture_cache[cache_key] = texture
	return texture


func _ensure_manifest_loaded() -> void:
	if _manifest_loaded:
		return
	_manifest_loaded = true
	var absolute_path := ProjectSettings.globalize_path(MANIFEST_PATH)
	if not FileAccess.file_exists(absolute_path):
		return
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var items: Array = (parsed as Dictionary).get("items", [])
	for item_variant in items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item_entry: Dictionary = item_variant as Dictionary
		var item_id := String(item_entry.get("id", ""))
		if item_id.is_empty():
			continue
		_icon_manifest[item_id] = item_entry


func _relative_icon_path_for_variant(item_entry: Dictionary, variant: String) -> String:
	match variant:
		"cutout_24":
			return "icons_24_cutout/%s.png" % String(item_entry.get("id", ""))
		_:
			return "icons_24_cutout/%s.png" % String(item_entry.get("id", ""))


func _load_texture(path: String) -> Texture2D:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.new()
	if image.load(absolute_path) != OK:
		return null
	return ImageTexture.create_from_image(image)
