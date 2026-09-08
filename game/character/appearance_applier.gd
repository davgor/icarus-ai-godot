extends RefCounted

## Shared appearance bus: record → preview and in-world body. Hybrid morphs land as catalogs fill.

const CapsuleBuilderScript := preload("res://game/character/capsule_builder.gd")
const CharacterRecordScript := preload("res://game/character/character_record.gd")

const KIT_PATHS := {
	"male": "res://game/art/characters/body_base_male.glb",
	"female": "res://game/art/characters/body_base_female.glb",
}
const MALE_FALLBACK := "res://game/art/characters/body_base_underwear.glb"
const HEAD_BONE_NAMES: PackedStringArray = [
	"Head", "head", "mixamorigHead", "mixamorig:Head", "DEF-head", "spine.006"
]


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
		_apply_head_bone(kit, CapsuleBuilderScript.head_scale(body))
		_apply_skin(kit, parse_color(str(body.get("skin_color", "#c8a07a"))))
		_apply_muscle_fat(kit, clampf(float(body.get("muscle_fat", 0.5)), 0.0, 1.0))
	if mannequin:
		mannequin.scale = scales
		var mat := mannequin.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mannequin.material_override = mat
		mat.albedo_color = parse_color(str(body.get("skin_color", "#c8a07a")))
		mat.metallic = 0.05
		var fatness := clampf(float(body.get("muscle_fat", 0.5)), 0.0, 1.0)
		mat.roughness = lerpf(0.38, 0.58, fatness)
	var amplitude := CapsuleBuilderScript.jiggle_amplitude(body)
	if preview_root.has_method("set_jiggle_from_muscle_fat"):
		preview_root.set_jiggle_from_muscle_fat(amplitude)
	preview_root.set_meta("jiggle_amplitude", amplitude)


static func jiggle_amplitude_of(preview_root: Node) -> float:
	if preview_root == null:
		return 0.5
	if preview_root.has_meta("jiggle_amplitude"):
		return float(preview_root.get_meta("jiggle_amplitude"))
	return 0.5


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


static func _apply_skin(kit: Node3D, color: Color) -> void:
	var stack: Array[Node] = [kit]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		var mesh := mi.mesh
		if mesh == null:
			continue
		var surfaces := mesh.get_surface_count()
		for i in surfaces:
			var source: Material = mi.get_active_material(i)
			if source == null and mesh is ArrayMesh:
				source = (mesh as ArrayMesh).surface_get_material(i)
			var mat: StandardMaterial3D
			if source is StandardMaterial3D:
				mat = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
			else:
				mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mi.set_surface_override_material(i, mat)


static func _apply_muscle_fat(kit: Node3D, amount: float) -> void:
	var stack: Array[Node] = [kit]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		_apply_blendshapes(mi, amount)
		var mat := mi.get_active_material(0) as StandardMaterial3D
		if mat:
			mat.roughness = lerpf(0.36, 0.62, amount)


static func _apply_blendshapes(mi: MeshInstance3D, amount: float) -> void:
	var mesh := mi.mesh
	if mesh == null or not (mesh is ArrayMesh):
		return
	var array_mesh := mesh as ArrayMesh
	var count := array_mesh.get_blend_shape_count()
	for i in count:
		var shape_name := array_mesh.get_blend_shape_name(i)
		var lower := shape_name.to_lower()
		if lower.find("fat") >= 0 or lower.find("soft") >= 0:
			mi.set("blend_shapes/%s" % shape_name, amount)
		elif lower.find("muscle") >= 0 or lower.find("lean") >= 0:
			mi.set("blend_shapes/%s" % shape_name, 1.0 - amount)


static func _apply_head_bone(kit: Node3D, scale_amount: float) -> void:
	var stack: Array[Node] = [kit]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is Skeleton3D:
			_scale_named_bone(node as Skeleton3D, scale_amount)


static func _scale_named_bone(skel: Skeleton3D, scale_amount: float) -> void:
	for bone_name in HEAD_BONE_NAMES:
		var idx := skel.find_bone(bone_name)
		if idx < 0:
			continue
		var rest := skel.get_bone_rest(idx)
		var pose := rest
		pose.basis = rest.basis.scaled(Vector3.ONE * scale_amount)
		skel.set_bone_pose(idx, pose)
		return
