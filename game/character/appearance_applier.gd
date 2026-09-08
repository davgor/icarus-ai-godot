extends RefCounted

## Shared appearance bus: record → preview and in-world body. Hybrid morphs land as catalogs fill.

const CapsuleBuilderScript := preload("res://game/character/capsule_builder.gd")
const CharacterRecordScript := preload("res://game/character/character_record.gd")
const CatalogScript := preload("res://game/character/appearance_catalog.gd")

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
	_apply_catalog(record, preview_root)
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
	_ensure_jiggle_spring(preview_root)


static func jiggle_amplitude_of(preview_root: Node) -> float:
	if preview_root == null:
		return 0.5
	if preview_root.has_meta("jiggle_amplitude"):
		return float(preview_root.get_meta("jiggle_amplitude"))
	return 0.5


## Bone-spring secondary motion. Outfits inherit at 0.55 damp (cape cloth is DEF-010).
static func tick_jiggle(preview_root: Node, delta: float) -> void:
	if preview_root == null:
		return
	var amplitude := jiggle_amplitude_of(preview_root)
	var t := float(preview_root.get_meta("jiggle_t", 0.0)) + delta
	preview_root.set_meta("jiggle_t", t)
	var angle := sin(t * (3.2 + amplitude * 1.4)) * amplitude * 0.12
	preview_root.set_meta("jiggle_angle", angle)
	_ensure_jiggle_spring(preview_root)
	var spring := preview_root.get_node_or_null("Preview/JiggleSpring") as Node3D
	if spring:
		spring.rotation.z = angle
		spring.rotation.x = angle * 0.35
	var kit := preview_root.get_node_or_null("Preview/BodyKit") as Node3D
	if kit:
		_spring_soft_bones(kit, angle)
	var tail := preview_root.get_node_or_null("Preview/TailPart") as Node3D
	if tail:
		tail.rotation.z = angle * 1.35
	var outfit := preview_root.get_node_or_null("Preview/Outfit") as Node3D
	if outfit:
		outfit.rotation.z = angle * 0.55


static func jiggle_sample(preview_root: Node) -> float:
	if preview_root == null:
		return 0.0
	return absf(float(preview_root.get_meta("jiggle_angle", 0.0)))


static func _ensure_jiggle_spring(preview_root: Node) -> void:
	var preview := preview_root.get_node_or_null("Preview") as Node3D
	if preview == null:
		return
	if preview.get_node_or_null("JiggleSpring") != null:
		return
	var spring := Node3D.new()
	spring.name = "JiggleSpring"
	preview.add_child(spring)


static func _spring_soft_bones(kit: Node3D, angle: float) -> void:
	var stack: Array[Node] = [kit]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is Skeleton3D):
			continue
		var skel := node as Skeleton3D
		for i in skel.get_bone_count():
			var bone_name := skel.get_bone_name(i).to_lower()
			if (
				bone_name.find("breast") < 0
				and bone_name.find("bust") < 0
				and bone_name.find("hip") < 0
				and bone_name.find("belly") < 0
				and bone_name.find("soft") < 0
			):
				continue
			var rest := skel.get_bone_rest(i)
			var pose := rest
			pose.basis = rest.basis.rotated(Vector3.FORWARD, angle)
			skel.set_bone_pose(i, pose)


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


static func _apply_catalog(record, preview_root: Node3D) -> void:
	var preview := preview_root.get_node_or_null("Preview") as Node3D
	if preview == null:
		return
	var face: Dictionary = record.face
	var features: Dictionary = record.features
	var outfit: Dictionary = record.outfit
	_apply_face_morphs(preview, face.get("morphs", {}))
	_attach_or_proxy(
		preview,
		"Hair",
		str(face.get("hair_id", "hair_default")),
		preview.get_node_or_null("Head") as Node3D,
		parse_color(str(face.get("hair_color", "#2a1a12"))),
		Vector3(0, 0.08, 0.04),
		"hair"
	)
	_attach_or_proxy(
		preview,
		"Eyes",
		str(face.get("eyes_id", "eyes_default")),
		preview.get_node_or_null("Head") as Node3D,
		parse_color(str(face.get("eye_color", "#4a6fa5"))),
		Vector3(0, 0.02, 0.12),
		"eyes"
	)
	_attach_overlay(preview, "Scar", face.get("scar_id", null), Vector3(-0.08, 0.02, 0.13), Color(0.55, 0.28, 0.22))
	_attach_overlay(preview, "Marking", face.get("marking_id", null), Vector3(0.08, 0.0, 0.13), Color(0.35, 0.75, 1.0))
	_attach_or_proxy(
		preview,
		"EarPart",
		str(features.get("ears_id", "")),
		preview.get_node_or_null("Ears") as Node3D,
		Color(0.85, 0.7, 0.55),
		Vector3.ZERO,
		"ears"
	)
	_attach_or_proxy(
		preview,
		"HornPart",
		str(features.get("horns_id", "")),
		preview.get_node_or_null("Horns") as Node3D,
		Color(0.45, 0.32, 0.28),
		Vector3.ZERO,
		"horns"
	)
	_attach_or_proxy(
		preview,
		"TailPart",
		str(features.get("tails_id", "")),
		preview.get_node_or_null("Tail") as Node3D,
		Color(0.35, 0.55, 0.32) if str(features.get("tails_id", "")) == "tails_lizard" else Color(0.55, 0.32, 0.18),
		Vector3.ZERO,
		"tail"
	)
	_attach_or_proxy(
		preview,
		"Outfit",
		str(outfit.get("id", "outfit_starter_01")),
		preview,
		_outfit_color(str(outfit.get("id", "outfit_starter_01"))),
		Vector3(0, 0.72, 0.08),
		"outfit"
	)


static func _outfit_color(outfit_id: String) -> Color:
	match outfit_id:
		"outfit_starter_02":
			return Color(0.28, 0.16, 0.38)
		"outfit_starter_03":
			return Color(0.18, 0.28, 0.42)
		_:
			return Color(0.22, 0.18, 0.16)


static func _apply_face_morphs(preview: Node3D, morphs: Dictionary) -> void:
	var kit := preview.get_node_or_null("BodyKit") as Node3D
	if kit:
		_apply_named_face_blendshapes(kit, morphs)
	var head := preview.get_node_or_null("Head") as Node3D
	if head == null:
		return
	var brow := clampf(float(morphs.get("brow", 0.5)), 0.0, 1.0)
	var eye_shape := clampf(float(morphs.get("eye_shape", 0.5)), 0.0, 1.0)
	var nose := clampf(float(morphs.get("nose", 0.5)), 0.0, 1.0)
	var cheek := clampf(float(morphs.get("cheek", 0.5)), 0.0, 1.0)
	var jaw := clampf(float(morphs.get("jaw", 0.5)), 0.0, 1.0)
	var mouth := clampf(float(morphs.get("mouth", 0.5)), 0.0, 1.0)
	var chin := clampf(float(morphs.get("chin", 0.5)), 0.0, 1.0)
	head.scale = Vector3(
		lerpf(0.92, 1.12, (jaw + cheek) * 0.5),
		lerpf(0.94, 1.1, (chin + brow) * 0.5),
		lerpf(0.96, 1.06, nose)
	)
	_set_face_proxy(head, "BrowProxy", Vector3(0, 0.11, 0.08), Vector3(lerpf(0.7, 1.2, brow), lerpf(0.45, 1.15, brow), 0.35), Color(0.35, 0.22, 0.18))
	_set_face_proxy(head, "NoseProxy", Vector3(0, 0.02, 0.13), Vector3(lerpf(0.45, 1.1, nose), lerpf(0.55, 1.25, nose), 0.4), Color(0.78, 0.58, 0.46))
	_set_face_proxy(head, "MouthProxy", Vector3(0, -0.06, 0.12), Vector3(lerpf(0.55, 1.25, mouth), 0.28, 0.28), Color(0.62, 0.28, 0.32))
	var eyes := preview.get_node_or_null("Eyes") as Node3D
	if eyes:
		eyes.scale = Vector3(lerpf(0.85, 1.18, eye_shape), lerpf(0.72, 1.22, eye_shape), 1.0)


static func _apply_named_face_blendshapes(kit: Node3D, morphs: Dictionary) -> void:
	var stack: Array[Node] = [kit]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		var mesh := mi.mesh
		if mesh == null or not (mesh is ArrayMesh):
			continue
		var array_mesh := mesh as ArrayMesh
		for i in array_mesh.get_blend_shape_count():
			var shape_name := array_mesh.get_blend_shape_name(i)
			var key := shape_name.to_lower()
			for morph_id in CharacterRecordScript.FACE_MORPH_IDS:
				if key.find(morph_id) >= 0 or key.find(str(morph_id).replace("_", "")) >= 0:
					mi.set("blend_shapes/%s" % shape_name, clampf(float(morphs.get(morph_id, 0.5)), 0.0, 1.0))


static func _set_face_proxy(head: Node3D, node_name: String, offset: Vector3, scale: Vector3, color: Color) -> void:
	var proxy := head.get_node_or_null(node_name) as MeshInstance3D
	if proxy == null:
		proxy = MeshInstance3D.new()
		proxy.name = node_name
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.04, 0.04)
		proxy.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.5
		proxy.material_override = mat
		head.add_child(proxy)
	proxy.position = offset
	proxy.scale = scale


static func _attach_overlay(preview: Node3D, node_name: String, part_id: Variant, offset: Vector3, color: Color) -> void:
	var id := "" if part_id == null else str(part_id)
	if id.is_empty() or id == "null":
		_free_named(preview, node_name)
		return
	_attach_or_proxy(preview, node_name, id, preview.get_node_or_null("Head") as Node3D, color, offset, "overlay")


static func _attach_or_proxy(
	preview: Node3D,
	node_name: String,
	part_id: String,
	socket: Node3D,
	color: Color,
	offset: Vector3,
	kind: String
) -> void:
	if part_id.is_empty() or part_id == "null":
		_free_named(preview, node_name)
		return
	var mesh_file := CatalogScript.mesh_path(part_id)
	var holder := preview.get_node_or_null(node_name) as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = node_name
		preview.add_child(holder)
	holder.set_meta("part_id", part_id)
	if socket:
		holder.global_position = socket.global_position + offset
	else:
		holder.position = offset
	for child in holder.get_children():
		holder.remove_child(child)
		child.free()
	if ResourceLoader.exists(mesh_file):
		var packed := load(mesh_file) as PackedScene
		if packed:
			var inst := packed.instantiate() as Node3D
			if inst:
				holder.add_child(inst)
				return
	holder.add_child(_proxy_mesh(kind, color, part_id))


static func _free_named(parent: Node, node_name: String) -> void:
	var node := parent.get_node_or_null(node_name)
	if node:
		parent.remove_child(node)
		node.free()


static func _proxy_mesh(kind: String, color: Color, part_id: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Proxy"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.45
	mi.material_override = mat
	match kind:
		"hair":
			var hair := SphereMesh.new()
			hair.radius = 0.16 if part_id != "hair_spike" else 0.14
			hair.height = 0.28 if part_id == "hair_wave" else 0.22
			mi.mesh = hair
			mi.position = Vector3(0, 0.06, 0)
		"eyes":
			var eye := SphereMesh.new()
			eye.radius = 0.035 if part_id != "eyes_sharp" else 0.028
			eye.height = 0.06
			mi.mesh = eye
		"ears":
			var ear := SphereMesh.new()
			ear.radius = 0.05
			ear.height = 0.14
			mi.mesh = ear
			mi.scale = Vector3(0.45, 1.3, 0.35)
		"horns":
			var horn := CylinderMesh.new()
			horn.top_radius = 0.01
			horn.bottom_radius = 0.04
			horn.height = 0.22
			mi.mesh = horn
			mi.rotation_degrees = Vector3(18, 0, 0)
		"tail":
			var tail := CylinderMesh.new()
			tail.top_radius = 0.02 if part_id == "tails_lizard" else 0.04
			tail.bottom_radius = 0.05
			tail.height = 0.55 if part_id == "tails_lizard" else 0.42
			mi.mesh = tail
			mi.rotation_degrees = Vector3(70, 0, 0)
			mi.position = Vector3(0, -0.05, -0.16)
		"outfit":
			var robe := CapsuleMesh.new()
			robe.radius = 0.26
			robe.height = 0.62
			mi.mesh = robe
			mi.position = Vector3(0, -0.08, 0.02)
		_:
			var decal := BoxMesh.new()
			decal.size = Vector3(0.08, 0.1, 0.01)
			mi.mesh = decal
	return mi

