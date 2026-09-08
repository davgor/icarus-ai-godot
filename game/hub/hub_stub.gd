extends Node3D

## Empty Sanctum stand-in until pack 03. Not Millbrook.

const AppearanceApplierScript := preload("res://game/character/appearance_applier.gd")

var _built := false


func _ready() -> void:
	_ensure()


func _process(delta: float) -> void:
	AppearanceApplierScript.tick_jiggle(self, delta)


func apply_record(record) -> void:
	_ensure()
	AppearanceApplierScript.apply(record, self)


func _ensure() -> void:
	if _built:
		return
	_built = true

	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.05, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.28, 0.22, 0.38)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.18, 0.12, 0.22)
	env.fog_density = 0.012
	env.glow_enabled = true
	env_node.environment = env
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(0.95, 0.78, 0.62)
	sun.light_energy = 0.85
	sun.rotation_degrees = Vector3(-42, -28, 8)
	sun.shadow_enabled = true
	add_child(sun)

	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.position = Vector3(0, -0.05, 0)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "Mesh"
	var plane := BoxMesh.new()
	plane.size = Vector3(28, 0.1, 28)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.12, 0.1, 0.16)
	floor_mat.roughness = 0.86
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(28, 0.1, 28)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	add_child(floor_body)

	var portal := MeshInstance3D.new()
	portal.name = "PortalHint"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.72
	ring.outer_radius = 0.92
	portal.mesh = ring
	portal.position = Vector3(0, 1.4, -7.5)
	portal.rotation_degrees = Vector3(90, 0, 0)
	var portal_mat := StandardMaterial3D.new()
	portal_mat.albedo_color = Color(0.35, 0.82, 1.0)
	portal_mat.emission_enabled = true
	portal_mat.emission = Color(0.2, 0.65, 1.0)
	portal_mat.emission_energy_multiplier = 2.2
	portal.material_override = portal_mat
	add_child(portal)

	var label := Label3D.new()
	label.name = "StubLabel"
	label.text = "Sanctum (stub)"
	label.font_size = 42
	label.modulate = Color(0.82, 0.9, 1.0)
	label.position = Vector3(0, 2.8, -7.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

	var preview := Node3D.new()
	preview.name = "Preview"
	add_child(preview)

	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0, 0.1, 2.4)
	add_child(spawn)
