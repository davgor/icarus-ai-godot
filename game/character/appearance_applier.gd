extends RefCounted

## Shared appearance bus: record → preview and in-world body. Hybrid morphs land as catalogs fill.

const CapsuleBuilderScript := preload("res://game/character/capsule_builder.gd")
const CharacterRecordScript := preload("res://game/character/character_record.gd")

const KIT_PATHS := {
	"male": "res://game/art/characters/body_base_male.glb",
	"female": "res://game/art/characters/body_base_female.glb",
}
const MALE_FALLBACK := "res://game/art/characters/body_base_underwear.glb"


static func normalize_sex(value: String) -> String:
	if CharacterRecordScript.SEXES.find(value) >= 0:
		return value
	return "male"


static func body_kit_path(sex: String) -> String:
	sex = normalize_sex(sex)
	var path := str(KIT_PATHS.get(sex, KIT_PATHS["male"]))
	if ResourceLoader.exists(path):
		return path
	if sex == "female":
		var male_path := str(KIT_PATHS["male"])
		if ResourceLoader.exists(male_path):
			return male_path
	if ResourceLoader.exists(MALE_FALLBACK):
		return MALE_FALLBACK
	return path


static func apply(record, preview_root: Node3D) -> void:
	if preview_root == null or record == null:
		return
	var body: Dictionary = record.body
	ensure_body_kit(preview_root, str(body.get("sex", "male")))
	var scales: Vector3 = CapsuleBuilderScript.preview_scale(body)
	var kit := preview_root.get_node_or_null("Preview/BodyKit") as Node3D
	var mannequin := preview_root.get_node_or_null("Preview/Mannequin") as MeshInstance3D
	if mannequin == null:
		mannequin = preview_root.get_node_or_null("Mannequin") as MeshInstance3D
	if kit:
		var base: Vector3 = kit.get_meta("base_scale", Vector3.ONE)
		kit.scale = Vector3(base.x * scales.x, base.y * scales.y, base.z * scales.z)
	if mannequin:
		mannequin.scale = scales
		var mat := mannequin.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mannequin.material_override = mat
		mat.albedo_color = parse_color(str(body.get("skin_color", "#c8a07a")))
		mat.roughness = 0.45
		mat.metallic = 0.05
		var fatness := clampf(float(body.get("muscle_fat", 0.5)), 0.0, 1.0)
		mat.roughness = lerpf(0.38, 0.58, fatness)
	if preview_root.has_method("set_jiggle_from_muscle_fat"):
		preview_root.set_jiggle_from_muscle_fat(float(body.get("muscle_fat", 0.5)))


static func ensure_body_kit(preview_root: Node3D, sex: String) -> Node3D:
	if preview_root == null:
		return null
	sex = normalize_sex(sex)
	var preview := preview_root.get_node_or_null("Preview") as Node3D
	if preview == null:
		preview = Node3D.new()
		preview.name = "Preview"
		preview_root.add_child(preview)
	var path := body_kit_path(sex)
	var kit := preview.get_node_or_null("BodyKit") as Node3D
	if (
		kit
		and str(kit.get_meta("kit_id", "")) == sex
		and str(kit.get_meta("kit_path", "")) == path
	):
		return kit
	if kit:
		preview.remove_child(kit)
		kit.free()
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	kit = packed.instantiate() as Node3D
	if kit == null:
		return null
	kit.name = "BodyKit"
	kit.set_meta("kit_id", sex)
	kit.set_meta("kit_path", path)
	preview.add_child(kit)
	if preview_root.has_method("prepare_body_kit"):
		preview_root.prepare_body_kit(kit)
	var mannequin := preview.get_node_or_null("Mannequin") as MeshInstance3D
	if mannequin:
		mannequin.visible = false
	return kit


static func parse_color(value: String) -> Color:
	var color := Color(value)
	if color.a <= 0.0 and not value.begins_with("#"):
		return Color(0.78, 0.63, 0.48)
	return color
