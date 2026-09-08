extends Object

## Schema v1 character save. Not Living Town / Millbrook JSON.

const SAVE_PATH := "user://icarus_character_v1.json"


static func write_record(record, path: String = SAVE_PATH) -> bool:
	if record == null:
		return false
	var data: Dictionary = record.to_dict()
	var RecordScript := preload("res://game/character/character_record.gd")
	if not RecordScript.validate_dict(data).is_empty():
		return false
	if str(data.get("display_name", "")).strip_edges().is_empty():
		return false
	if str(data.get("id", "")).is_empty():
		data["id"] = "char_%s" % str(Time.get_unix_time_from_system()).replace(".", "")
		record.id = str(data["id"])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


static func read_record(path: String = SAVE_PATH):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var RecordScript := preload("res://game/character/character_record.gd")
	var record = RecordScript.new()
	if not record.from_dict(parsed):
		return null
	return record


static func exists(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)
