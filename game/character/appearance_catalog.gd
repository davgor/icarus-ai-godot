extends Object

## Data-driven creator catalog. Generators may only sample these ids.

const HAIR_IDS: PackedStringArray = ["hair_default", "hair_wave", "hair_spike"]
const EYE_IDS: PackedStringArray = ["eyes_default", "eyes_sharp", "eyes_soft"]
const SCAR_IDS: PackedStringArray = ["scar_cheek"]
const MARKING_IDS: PackedStringArray = ["marking_rune"]
const EAR_IDS: PackedStringArray = ["ears_starter"]
const HORN_IDS: PackedStringArray = ["horns_starter"]
const TAIL_IDS: PackedStringArray = ["tails_starter", "tails_lizard"]
## Wardrobe ids for the outfit engine (pack 08). Creator Confirm uses OUTFIT_NONE only.
const OUTFIT_NONE := "none"
const OUTFIT_IDS: PackedStringArray = ["outfit_starter_01", "outfit_starter_02", "outfit_starter_03"]

const HAIR_COLORS: PackedStringArray = ["#2a1a12", "#4a2a18", "#8a5a2a", "#c8b8a0", "#1a1a22", "#5a1a22"]
const EYE_COLORS: PackedStringArray = ["#4a6fa5", "#2f6b4a", "#6a3a22", "#3a2a55", "#a8c4e8", "#c45a3a"]

const LABELS := {
	"hair_default": "Short",
	"hair_wave": "Wave",
	"hair_spike": "Spike",
	"eyes_default": "Round",
	"eyes_sharp": "Sharp",
	"eyes_soft": "Soft",
	"scar_cheek": "Cheek",
	"marking_rune": "Rune",
	"ears_starter": "Elf-like",
	"horns_starter": "Horns",
	"tails_starter": "Fox",
	"tails_lizard": "Lizard",
	"outfit_starter_01": "Traveler",
	"outfit_starter_02": "Dusk wrap",
	"outfit_starter_03": "Sanctum coat",
	"none": "None",
}

const ICON_PATHS := {
	"hair_default": "res://game/art/characters/hair_short.png",
	"hair_wave": "res://game/art/characters/hair_wave.png",
	"hair_spike": "res://game/art/characters/hair_spike.png",
	"eyes_default": "res://game/art/characters/eyes_sheet.png",
	"eyes_sharp": "res://game/art/characters/eyes_sheet.png",
	"eyes_soft": "res://game/art/characters/eyes_sheet.png",
	"scar_cheek": "res://game/art/characters/scar_cheek.png",
	"marking_rune": "res://game/art/characters/marking_rune.png",
	"ears_starter": "res://game/art/characters/feature_ears_starter.png",
	"horns_starter": "res://game/art/characters/feature_horns_starter.png",
	"tails_starter": "res://game/art/characters/feature_tails_starter.png",
	"tails_lizard": "res://game/art/characters/feature_tails_lizard.png",
	"outfit_starter_01": "res://game/art/characters/outfit_starter_01.png",
	"outfit_starter_02": "res://game/art/characters/outfit_starter_02.png",
	"outfit_starter_03": "res://game/art/characters/outfit_starter_03.png",
}

const MESH_PATHS := {
	"hair_default": "res://game/art/characters/hair_short.glb",
	"hair_wave": "res://game/art/characters/hair_wave.glb",
	"hair_spike": "res://game/art/characters/hair_spike.glb",
	"ears_starter": "res://game/art/characters/feature_ears_starter.glb",
	"horns_starter": "res://game/art/characters/feature_horns_starter.glb",
	"tails_starter": "res://game/art/characters/feature_tails_starter.glb",
	"tails_lizard": "res://game/art/characters/feature_tails_lizard.glb",
	"outfit_starter_01": "res://game/art/characters/outfit_starter_01.glb",
	"outfit_starter_02": "res://game/art/characters/outfit_starter_02.glb",
	"outfit_starter_03": "res://game/art/characters/outfit_starter_03.glb",
}


static func label_for(part_id: String) -> String:
	if part_id.is_empty():
		return str(LABELS.get("none", "None"))
	return str(LABELS.get(part_id, part_id.capitalize()))


static func icon_path(part_id: String) -> String:
	return str(ICON_PATHS.get(part_id, ""))


static func mesh_path(part_id: String) -> String:
	return str(MESH_PATHS.get(part_id, ""))


static func legal_or_default(part_id: String, allowed: PackedStringArray, fallback: String) -> String:
	if allowed.find(part_id) >= 0:
		return part_id
	return fallback


static func is_legal_outfit_id(outfit_id: String) -> bool:
	if outfit_id == OUTFIT_NONE:
		return true
	return OUTFIT_IDS.find(outfit_id) >= 0
