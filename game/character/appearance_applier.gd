extends RefCounted

## Shared appearance bus: record → preview and in-world body. Hybrid morphs land as catalogs fill.

const CapsuleBuilderScript := preload("res://game/character/capsule_builder.gd")


static func apply(record, preview_root: Node3D) -> void:
	if preview_root == null or record == null:
		return
	var body: Dictionary = record.body
	var mannequin := preview_root.get_node_or_null("Preview/Mannequin") as MeshInstance3D
	if mannequin == null:
		mannequin = preview_root.get_node_or_null("Mannequin") as MeshInstance3D
	if mannequin:
		var scales: Vector3 = CapsuleBuilderScript.preview_scale(body)
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


static func parse_color(value: String) -> Color:
	var color := Color(value)
	if color.a <= 0.0 and not value.begins_with("#"):
		return Color(0.78, 0.63, 0.48)
	return color
