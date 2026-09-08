extends Object

## Race is a preset + story tag. Morphs stay overrideable after apply.

const LABELS := {
	"human": "Human",
	"elf": "Elf",
	"dwarf": "Dwarf",
	"gnome": "Gnome",
	"halfling": "Halfling",
	"demi_human": "Demi-human",
}

const CARD_PATHS := {
	"human": "res://game/art/characters/race_human.png",
	"elf": "res://game/art/characters/race_elf.png",
	"dwarf": "res://game/art/characters/race_dwarf.png",
	"gnome": "res://game/art/characters/race_gnome.png",
	"halfling": "res://game/art/characters/race_halfling.png",
	"demi_human": "res://game/art/characters/race_demi.png",
}


static func label_for(race_id: String) -> String:
	return str(LABELS.get(race_id, race_id.capitalize()))


static func card_path(race_id: String) -> String:
	return str(CARD_PATHS.get(race_id, CARD_PATHS["human"]))


const PRESETS := {
	"human": {
		"height": 0.5,
		"weight": 0.5,
		"muscle_fat": 0.5,
		"skin_color": "#c8a07a",
		"proportions": {"head": 0.5, "torso": 0.5, "arms": 0.5, "legs": 0.5},
		"features": {"ears_id": null, "horns_id": null, "tails_id": null},
	},
	"elf": {
		"height": 0.62,
		"weight": 0.38,
		"muscle_fat": 0.42,
		"skin_color": "#e8c4a0",
		"proportions": {"head": 0.48, "torso": 0.46, "arms": 0.48, "legs": 0.6},
		"features": {"ears_id": "ears_starter", "horns_id": null, "tails_id": null},
	},
	"dwarf": {
		"height": 0.28,
		"weight": 0.7,
		"muscle_fat": 0.48,
		"skin_color": "#a0724e",
		"proportions": {"head": 0.58, "torso": 0.64, "arms": 0.58, "legs": 0.36},
		"features": {"ears_id": null, "horns_id": null, "tails_id": null},
	},
	"gnome": {
		"height": 0.18,
		"weight": 0.4,
		"muscle_fat": 0.46,
		"skin_color": "#f3d2b5",
		"proportions": {"head": 0.64, "torso": 0.5, "arms": 0.46, "legs": 0.32},
		"features": {"ears_id": null, "horns_id": null, "tails_id": null},
	},
	"halfling": {
		"height": 0.32,
		"weight": 0.46,
		"muscle_fat": 0.55,
		"skin_color": "#e8c4a0",
		"proportions": {"head": 0.56, "torso": 0.5, "arms": 0.46, "legs": 0.38},
		"features": {"ears_id": null, "horns_id": null, "tails_id": null},
	},
	"demi_human": {
		"height": 0.52,
		"weight": 0.5,
		"muscle_fat": 0.5,
		"skin_color": "#c8a07a",
		"proportions": {"head": 0.5, "torso": 0.5, "arms": 0.5, "legs": 0.52},
		"features": {"ears_id": "ears_starter", "horns_id": "horns_starter", "tails_id": "tails_starter"},
	},
}


static func apply(record, race_id: String) -> void:
	if not PRESETS.has(race_id):
		race_id = "human"
	record.race = race_id
	var preset: Dictionary = PRESETS[race_id]
	record.body["height"] = preset["height"]
	record.body["weight"] = preset["weight"]
	record.body["muscle_fat"] = preset["muscle_fat"]
	record.body["skin_color"] = preset["skin_color"]
	record.body["proportions"] = (preset["proportions"] as Dictionary).duplicate(true)
	record.features = (preset["features"] as Dictionary).duplicate(true)


static func reset_category(record, category: String) -> void:
	var race_id := str(record.race)
	if not PRESETS.has(race_id):
		race_id = "human"
	var preset: Dictionary = PRESETS[race_id]
	match category:
		"race":
			apply(record, race_id)
		"body":
			record.body["height"] = preset["height"]
			record.body["weight"] = preset["weight"]
			record.body["muscle_fat"] = preset["muscle_fat"]
			record.body["skin_color"] = preset["skin_color"]
			record.body["proportions"] = (preset["proportions"] as Dictionary).duplicate(true)
		"face":
			var morphs := {}
			for morph_id in record.FACE_MORPH_IDS:
				morphs[morph_id] = 0.5
			record.face["morphs"] = morphs
			record.face["scar_id"] = null
			record.face["marking_id"] = null
		"features":
			record.features = (preset["features"] as Dictionary).duplicate(true)
		"outfit":
			record.outfit["id"] = "outfit_starter_01"
