extends RefCounted

## Engine-owned appearance record (schema v1). See docs/13-CHARACTER-APPEARANCE.md.

const SCHEMA_VERSION := 1
const RACES: PackedStringArray = [
	"human", "elf", "dwarf", "gnome", "halfling", "demi_human"
]
const SEXES: PackedStringArray = ["male", "female"]
const CATEGORIES: PackedStringArray = ["race", "body", "face", "features"]
const OUTFIT_NONE := "none"
const FACE_MORPH_IDS: PackedStringArray = [
	"brow", "eye_shape", "nose", "cheek", "jaw", "mouth", "chin"
]
const PROPORTION_IDS: PackedStringArray = ["head", "torso", "arms", "legs"]
const SKIN_SWATCHES: PackedStringArray = [
	"#f3d2b5", "#e8c4a0", "#c8a07a", "#a0724e", "#6f4a32", "#3d2a22"
]
const DEFAULT_SKIN := "#c8a07a"

var schema_version: int = SCHEMA_VERSION
var id: String = ""
var display_name: String = ""
var race: String = "human"
var body: Dictionary = {}
var face: Dictionary = {}
var features: Dictionary = {}
var outfit: Dictionary = {}
var loadout: Dictionary = {}


func _init() -> void:
	reset_to_defaults()


func reset_to_defaults() -> void:
	schema_version = SCHEMA_VERSION
	if id.is_empty():
		id = ""
	race = "human"
	body = {
		"sex": "male",
		"height": 0.5,
		"weight": 0.5,
		"muscle_fat": 0.5,
		"skin_color": DEFAULT_SKIN,
		"proportions": {
			"head": 0.5,
			"torso": 0.5,
			"arms": 0.5,
			"legs": 0.5,
		},
	}
	face = {
		"shape_id": "face_default",
		"morphs": _default_morphs(),
		"eyes_id": "eyes_default",
		"eye_color": "#4a6fa5",
		"hair_id": "hair_default",
		"hair_color": "#2a1a12",
		"scar_id": null,
		"marking_id": null,
	}
	features = {
		"ears_id": null,
		"horns_id": null,
		"tails_id": null,
	}
	outfit = {"id": OUTFIT_NONE}
	loadout = {
		"hands": {"main": null, "off": null},
		"armor": {},
		"accessories": {},
	}


func apply_race_preset(race_id: String) -> void:
	var presets := preload("res://game/character/race_presets.gd")
	presets.apply(self, race_id)


func reset_category(category: String) -> void:
	var presets := preload("res://game/character/race_presets.gd")
	presets.reset_category(self, category)


func randomize_all(rng: RandomNumberGenerator) -> void:
	race = RACES[rng.randi_range(0, RACES.size() - 1)]
	apply_race_preset(race)
	_randomize_body(rng)
	_randomize_face(rng)
	_randomize_features(rng)
	outfit["id"] = OUTFIT_NONE


func randomize_category(category: String, rng: RandomNumberGenerator) -> void:
	match category:
		"race":
			race = RACES[rng.randi_range(0, RACES.size() - 1)]
			apply_race_preset(race)
		"body":
			_randomize_body(rng)
		"face":
			_randomize_face(rng)
		"features":
			_randomize_features(rng)


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"id": id,
		"display_name": display_name,
		"race": race,
		"body": body.duplicate(true),
		"face": face.duplicate(true),
		"features": features.duplicate(true),
		"outfit": outfit.duplicate(true),
		"loadout": loadout.duplicate(true),
	}


func from_dict(data: Dictionary) -> bool:
	if not validate_dict(data).is_empty():
		return false
	schema_version = int(data.get("schema_version", SCHEMA_VERSION))
	id = str(data.get("id", ""))
	display_name = str(data.get("display_name", ""))
	race = str(data.get("race", "human"))
	body = (data.get("body", {}) as Dictionary).duplicate(true)
	face = (data.get("face", {}) as Dictionary).duplicate(true)
	features = (data.get("features", {}) as Dictionary).duplicate(true)
	outfit = (data.get("outfit", {}) as Dictionary).duplicate(true)
	loadout = (data.get("loadout", {}) as Dictionary).duplicate(true)
	_ensure_shape()
	return true


static func validate_dict(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("schema_version")
	var race_id := str(data.get("race", ""))
	if RACES.find(race_id) < 0:
		errors.append("race")
	var body_data: Dictionary = data.get("body", {})
	if body_data.is_empty() or not body_data.has("skin_color"):
		errors.append("skin_color")
	if SEXES.find(str(body_data.get("sex", ""))) < 0:
		errors.append("body.sex")
	for key in ["height", "weight", "muscle_fat"]:
		if not _is_unit(body_data.get(key, -1.0)):
			errors.append("body.%s" % key)
	var morphs: Dictionary = (data.get("face", {}) as Dictionary).get("morphs", {})
	for morph_id in FACE_MORPH_IDS:
		if not morphs.has(morph_id):
			errors.append("face.morphs.%s" % morph_id)
	var outfit_data: Dictionary = data.get("outfit", {})
	var Catalog := preload("res://game/character/appearance_catalog.gd")
	if not Catalog.is_legal_outfit_id(str(outfit_data.get("id", ""))):
		errors.append("outfit.id")
	var face_data: Dictionary = data.get("face", {})
	if Catalog.HAIR_IDS.find(str(face_data.get("hair_id", ""))) < 0:
		errors.append("face.hair_id")
	if Catalog.EYE_IDS.find(str(face_data.get("eyes_id", ""))) < 0:
		errors.append("face.eyes_id")
	var scar_id: Variant = face_data.get("scar_id", null)
	if scar_id != null and str(scar_id) != "" and Catalog.SCAR_IDS.find(str(scar_id)) < 0:
		errors.append("face.scar_id")
	var marking_id: Variant = face_data.get("marking_id", null)
	if marking_id != null and str(marking_id) != "" and Catalog.MARKING_IDS.find(str(marking_id)) < 0:
		errors.append("face.marking_id")
	var feat: Dictionary = data.get("features", {})
	var ears_id: Variant = feat.get("ears_id", null)
	if ears_id != null and str(ears_id) != "" and Catalog.EAR_IDS.find(str(ears_id)) < 0:
		errors.append("features.ears_id")
	var horns_id: Variant = feat.get("horns_id", null)
	if horns_id != null and str(horns_id) != "" and Catalog.HORN_IDS.find(str(horns_id)) < 0:
		errors.append("features.horns_id")
	var tails_id: Variant = feat.get("tails_id", null)
	if tails_id != null and str(tails_id) != "" and Catalog.TAIL_IDS.find(str(tails_id)) < 0:
		errors.append("features.tails_id")
	return errors


func duplicate_record():
	var copy = get_script().new()
	copy.from_dict(to_dict())
	return copy


func _ensure_shape() -> void:
	if SEXES.find(str(body.get("sex", ""))) < 0:
		body["sex"] = "male"
	if not body.has("proportions"):
		body["proportions"] = {}
	var props: Dictionary = body["proportions"]
	for key in PROPORTION_IDS:
		if not props.has(key):
			props[key] = 0.5
	if not body.has("skin_color"):
		body["skin_color"] = DEFAULT_SKIN
	if not face.has("morphs"):
		face["morphs"] = _default_morphs()
	var morphs: Dictionary = face["morphs"]
	for morph_id in FACE_MORPH_IDS:
		if not morphs.has(morph_id):
			morphs[morph_id] = 0.5
	if not outfit.has("id") or str(outfit.get("id", "")).is_empty():
		outfit["id"] = OUTFIT_NONE
	if not loadout.has("hands"):
		loadout = {
			"hands": {"main": null, "off": null},
			"armor": {},
			"accessories": {},
		}


func _default_morphs() -> Dictionary:
	var morphs := {}
	for morph_id in FACE_MORPH_IDS:
		morphs[morph_id] = 0.5
	return morphs


func _randomize_body(rng: RandomNumberGenerator) -> void:
	body["sex"] = SEXES[rng.randi_range(0, SEXES.size() - 1)]
	body["height"] = rng.randf()
	body["weight"] = rng.randf()
	body["muscle_fat"] = rng.randf()
	body["skin_color"] = SKIN_SWATCHES[rng.randi_range(0, SKIN_SWATCHES.size() - 1)]
	var props: Dictionary = body.get("proportions", {})
	for key in PROPORTION_IDS:
		props[key] = rng.randf()
	body["proportions"] = props


func _randomize_face(rng: RandomNumberGenerator) -> void:
	var morphs: Dictionary = face.get("morphs", {})
	for morph_id in FACE_MORPH_IDS:
		morphs[morph_id] = rng.randf()
	face["morphs"] = morphs
	var Catalog := preload("res://game/character/appearance_catalog.gd")
	face["hair_id"] = Catalog.HAIR_IDS[rng.randi_range(0, Catalog.HAIR_IDS.size() - 1)]
	face["eyes_id"] = Catalog.EYE_IDS[rng.randi_range(0, Catalog.EYE_IDS.size() - 1)]
	face["hair_color"] = Catalog.HAIR_COLORS[rng.randi_range(0, Catalog.HAIR_COLORS.size() - 1)]
	face["eye_color"] = Catalog.EYE_COLORS[rng.randi_range(0, Catalog.EYE_COLORS.size() - 1)]
	if rng.randf() > 0.65:
		face["scar_id"] = Catalog.SCAR_IDS[0]
	else:
		face["scar_id"] = null
	if rng.randf() > 0.7:
		face["marking_id"] = Catalog.MARKING_IDS[0]
	else:
		face["marking_id"] = null


func _randomize_features(rng: RandomNumberGenerator) -> void:
	if rng.randf() > 0.55:
		features["ears_id"] = "ears_starter"
	else:
		features["ears_id"] = null
	if rng.randf() > 0.7:
		features["horns_id"] = "horns_starter"
	else:
		features["horns_id"] = null
	if rng.randf() > 0.65:
		features["tails_id"] = "tails_lizard" if rng.randf() > 0.5 else "tails_starter"
	else:
		features["tails_id"] = null


static func _is_unit(value: Variant) -> bool:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return false
	var amount := float(value)
	return amount >= 0.0 and amount <= 1.0
