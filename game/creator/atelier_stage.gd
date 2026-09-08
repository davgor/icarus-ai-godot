extends Node3D

## 3D atelier preview: generated hall, capsule mannequin, Full/Dawn/Dusk lights, orbit camera.

signal lighting_changed(preset: String)

const ROOM_MESH := "res://game/art/characters/creator_atelier_chamber.glb"
const BACKDROP := "res://game/art/characters/creator_atelier_bg.png"
const PRESETS: PackedStringArray = ["full", "dawn", "dusk"]
const ORBIT_SENS := 0.006
const PAD_ORBIT_SPEED := 1.6
const MIN_PITCH := deg_to_rad(-8.0)
const MAX_PITCH := deg_to_rad(22.0)
const MIN_YAW := -0.95
const MAX_YAW := 0.95
const MIN_ZOOM := 4.6
const MAX_ZOOM := 9.2
const DEFAULT_ZOOM := 6.35
const TARGET_ROOM_SIZE := 5.8

const AppearanceApplierScript := preload("res://game/character/appearance_applier.gd")

var lighting_preset: String = "full"

var _built := false
var _world_env: WorldEnvironment
var _key: DirectionalLight3D
var _fill: DirectionalLight3D
var _rim: DirectionalLight3D
var _shaft: SpotLight3D
var _dais_glow: OmniLight3D
var _pivot: Node3D
var _camera: Camera3D
var _mannequin: MeshInstance3D
var _yaw := 0.28
var _pitch := 0.08
var _zoom := DEFAULT_ZOOM
var _orbiting := false
var _cached_dais_y := -1.0


func _ready() -> void:
	_ensure_stage()
	apply_lighting("full")
	_refresh_camera()


func _process(delta: float) -> void:
	if not visible:
		return
	var pad := Vector2(
		Input.get_axis("creator_orbit_left", "creator_orbit_right"),
		Input.get_axis("creator_orbit_down", "creator_orbit_up")
	)
	if pad.length() > 0.12:
		orbit(pad.x * PAD_ORBIT_SPEED * delta, pad.y * PAD_ORBIT_SPEED * delta)


func handle_stage_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mouse.pressed
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(-0.22)
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(0.22)
	elif event is InputEventMouseMotion and _orbiting:
		var motion := event as InputEventMouseMotion
		orbit(-motion.relative.x * ORBIT_SENS, -motion.relative.y * ORBIT_SENS)


func orbit(delta_yaw: float, delta_pitch: float) -> void:
	_yaw = clampf(_yaw + delta_yaw, MIN_YAW, MAX_YAW)
	_pitch = clampf(_pitch + delta_pitch, MIN_PITCH, MAX_PITCH)
	_refresh_camera()


func zoom_by(amount: float) -> void:
	_zoom = clampf(_zoom + amount, MIN_ZOOM, MAX_ZOOM)
	_refresh_camera()


func apply_record(record) -> void:
	_ensure_stage()
	AppearanceApplierScript.apply(record, self)
	_plant_preview_on_dais()


func current_kit_id() -> String:
	var kit := get_node_or_null("Preview/BodyKit") as Node3D
	if kit:
		return str(kit.get_meta("kit_id", ""))
	return ""


func prepare_body_kit(kit: Node3D) -> void:
	if kit == null:
		return
	_hide_kit_helpers(kit)
	_fit_preview_body(kit)


func apply_lighting(preset: String) -> void:
	_ensure_stage()
	if PRESETS.find(preset) < 0:
		preset = "full"
	lighting_preset = preset
	var env := _world_env.environment
	match preset:
		"dawn":
			_configure_light(_key, Color(1.0, 0.72, 0.42), 0.95, Vector3(-32, -38, 18))
			_configure_light(_fill, Color(0.92, 0.48, 0.32), 0.22, Vector3(50, -10, -20))
			_configure_light(_rim, Color(1.0, 0.82, 0.55), 0.55, Vector3(160, -8, 12))
			_configure_shaft(Color(1.0, 0.78, 0.48), 1.6)
			_configure_dais(Color(1.0, 0.82, 0.55), 0.7)
			env.ambient_light_color = Color(0.48, 0.3, 0.22)
			env.ambient_light_energy = 0.32
			env.background_color = Color(0.12, 0.07, 0.06)
			env.fog_light_color = Color(0.42, 0.22, 0.16)
		"dusk":
			_configure_light(_key, Color(0.42, 0.52, 0.95), 0.55, Vector3(-40, -28, 10))
			_configure_light(_fill, Color(0.32, 0.18, 0.48), 0.18, Vector3(55, -6, -24))
			_configure_light(_rim, Color(0.45, 0.92, 1.0), 0.95, Vector3(155, 6, 18))
			_configure_shaft(Color(0.45, 0.72, 1.0), 2.4)
			_configure_dais(Color(0.4, 0.85, 1.0), 0.85)
			env.ambient_light_color = Color(0.14, 0.16, 0.32)
			env.ambient_light_energy = 0.24
			env.background_color = Color(0.03, 0.04, 0.09)
			env.fog_light_color = Color(0.08, 0.12, 0.28)
		_:
			_configure_light(_key, Color(0.94, 0.96, 1.0), 1.05, Vector3(-28, -48, 12))
			_configure_light(_fill, Color(0.55, 0.72, 0.92), 0.32, Vector3(48, -18, -16))
			_configure_light(_rim, Color(0.7, 0.9, 1.0), 0.7, Vector3(150, 4, 20))
			_configure_shaft(Color(0.7, 0.86, 1.0), 2.0)
			_configure_dais(Color(0.85, 0.95, 1.0), 0.9)
			env.ambient_light_color = Color(0.32, 0.38, 0.5)
			env.ambient_light_energy = 0.42
			env.background_color = Color(0.04, 0.05, 0.09)
			env.fog_light_color = Color(0.12, 0.16, 0.28)
	lighting_changed.emit(lighting_preset)


func cycle_lighting() -> String:
	var idx := PRESETS.find(lighting_preset)
	var next := PRESETS[(idx + 1) % PRESETS.size()]
	apply_lighting(next)
	return lighting_preset


func set_jiggle_from_muscle_fat(amount: float) -> void:
	var amplitude := clampf(amount, 0.0, 1.0)
	set_meta("jiggle_amplitude", amplitude)


func jiggle_amplitude() -> float:
	if has_meta("jiggle_amplitude"):
		return float(get_meta("jiggle_amplitude"))
	return 0.5


func _ensure_stage() -> void:
	if _built:
		return
	_built = true

	_world_env = WorldEnvironment.new()
	_world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.fog_enabled = true
	env.fog_density = 0.018
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.4
	_world_env.environment = env
	add_child(_world_env)

	_key = _make_light("KeyLight")
	_fill = _make_light("FillLight")
	_rim = _make_light("RimLight")
	_fill.shadow_enabled = false
	_rim.shadow_enabled = false

	_place_room()
	_place_preview_body()

	_shaft = SpotLight3D.new()
	_shaft.name = "WindowShaft"
	_shaft.shadow_enabled = true
	_shaft.spot_range = 16.0
	_shaft.spot_attenuation = 0.6
	_shaft.spot_angle = 32.0
	_shaft.position = Vector3(0.15, 5.4, -3.6)
	_shaft.rotation_degrees = Vector3(-42.0, 8.0, 0.0)
	add_child(_shaft)

	_dais_glow = OmniLight3D.new()
	_dais_glow.name = "DaisGlow"
	_dais_glow.shadow_enabled = false
	_dais_glow.omni_range = 4.2
	_dais_glow.position = Vector3(0, 0.42, 0.15)
	add_child(_dais_glow)

	_frame_outside_set()

	_add_motes()

	var preview := get_node_or_null("Preview") as Node3D
	if preview == null:
		preview = Node3D.new()
		preview.name = "Preview"
		add_child(preview)

	if _mannequin == null:
		_mannequin = MeshInstance3D.new()
		_mannequin.name = "Mannequin"
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.32
		capsule.height = 1.7
		_mannequin.mesh = capsule
		_mannequin.position = Vector3(0, _dais_surface_y() + 0.87, 0.12)
		_mannequin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		preview.add_child(_mannequin)

	if preview.get_node_or_null("BodyKit") and _mannequin:
		_mannequin.visible = false

	for socket_name in ["Head", "Ears", "Horns", "Tail"]:
		var socket := Marker3D.new()
		socket.name = socket_name
		preview.add_child(socket)
	preview.get_node("Head").position = Vector3(0, 1.69, 0.12)
	preview.get_node("Ears").position = Vector3(0, 1.62, 0.12)
	preview.get_node("Horns").position = Vector3(0, 1.77, 0.12)
	preview.get_node("Tail").position = Vector3(0, 0.92, -0.1)

	_pivot = Node3D.new()
	_pivot.name = "CameraPivot"
	add_child(_pivot)
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.current = true
	_camera.fov = 38.0
	_camera.near = 0.08
	_camera.far = 80.0
	_pivot.add_child(_camera)
	_refresh_camera()
	_disable_stage_picking()


func _place_preview_body() -> void:
	var preview := get_node_or_null("Preview") as Node3D
	if preview == null:
		preview = Node3D.new()
		preview.name = "Preview"
		add_child(preview)
	var kit := AppearanceApplierScript.ensure_body_kit(self, "male")
	if kit:
		if _mannequin:
			_mannequin.visible = false
		return
	if _mannequin == null:
		_mannequin = MeshInstance3D.new()
		_mannequin.name = "Mannequin"
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.32
		capsule.height = 1.7
		_mannequin.mesh = capsule
		_mannequin.position = Vector3(0, _dais_surface_y() + 0.87, 0.12)
		_mannequin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		preview.add_child(_mannequin)


func _fit_preview_body(kit: Node3D) -> void:
	var aabb := _visual_aabb(kit)
	if aabb.size.length() < 0.01:
		kit.position = Vector3(0, _dais_surface_y() + 0.02, 0.12)
		kit.set_meta("base_scale", kit.scale)
		return
	var target_height := 1.7
	var kit_scale := target_height / maxf(aabb.size.y, 0.01)
	kit.scale = Vector3.ONE * kit_scale
	aabb = _visual_aabb(kit)
	kit.position -= Vector3(aabb.get_center().x, aabb.position.y, aabb.get_center().z - 0.12)
	kit.set_meta("base_scale", kit.scale)
	_plant_preview_on_dais()


func _plant_preview_on_dais() -> void:
	var kit := get_node_or_null("Preview/BodyKit") as Node3D
	var dais_y := _dais_surface_y() + 0.02
	if kit:
		var aabb := _visual_aabb(kit)
		if aabb.size.length() < 0.01:
			kit.position.y = dais_y
			return
		kit.position.y += dais_y - aabb.position.y
		return
	if _mannequin:
		_mannequin.position.y = dais_y + 0.85


func _dais_surface_y() -> float:
	if _cached_dais_y > 0.0:
		return _cached_dais_y
	var room := get_node_or_null("Room")
	if room == null:
		_cached_dais_y = 0.62
		return _cached_dais_y
	var best := 0.0
	var stack: Array[Node] = [room]
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
		var surface_count := mesh.get_surface_count()
		for surface_i in surface_count:
			var arrays: Array = []
			if mesh.has_method("surface_get_arrays"):
				arrays = mesh.surface_get_arrays(surface_i)
			elif mesh.has_method("get_surface_arrays"):
				arrays = mesh.get_surface_arrays(surface_i)
			if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
				continue
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex in verts:
				var world := mi.global_transform * vertex
				if Vector2(world.x, world.z - 0.12).length() > 0.62:
					continue
				if world.y < 0.18 or world.y > 1.25:
					continue
				best = maxf(best, world.y)
	_cached_dais_y = best if best >= 0.2 else 0.62
	return _cached_dais_y


func _hide_kit_helpers(kit: Node3D) -> void:
	var stack: Array[Node] = [kit]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is VisualInstance3D):
			continue
		var vi := node as VisualInstance3D
		var box := vi.get_aabb()
		if box.size.y < 0.2 and box.size.x > 2.0 and box.size.z > 2.0:
			vi.visible = false


func _disable_stage_picking() -> void:
	var stack: Array[Node] = [self]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is CollisionObject3D:
			var body := node as CollisionObject3D
			body.input_ray_pickable = false
			body.collision_layer = 0
			body.collision_mask = 0
		if node is CollisionShape3D:
			(node as CollisionShape3D).disabled = true


func _place_room() -> void:
	var room := get_node_or_null("Room") as Node3D
	if room == null:
		room = Node3D.new()
		room.name = "Room"
		add_child(room)
	var chamber := room.get_node_or_null("Chamber") as Node3D
	if chamber == null:
		if not ResourceLoader.exists(ROOM_MESH):
			return
		var packed := load(ROOM_MESH) as PackedScene
		if packed == null:
			return
		chamber = packed.instantiate() as Node3D
		if chamber == null:
			return
		chamber.name = "Chamber"
		room.add_child(chamber)
	_fit_room(chamber)
	_prepare_room_meshes(chamber)


func _fit_room(room: Node3D) -> void:
	var aabb := _visual_aabb(room)
	if aabb.size.length() < 0.01:
		return
	var longest := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var room_scale := TARGET_ROOM_SIZE / maxf(longest, 0.01)
	room.scale = Vector3.ONE * room_scale
	aabb = _visual_aabb(room)
	var center := aabb.get_center()
	room.position -= Vector3(center.x, aabb.position.y, center.z)


func _prepare_room_meshes(root: Node) -> void:
	var stack: Array[Node] = [root]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is GeometryInstance3D:
			var gi := node as GeometryInstance3D
			gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			gi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED


func _visual_aabb(root: Node) -> AABB:
	var acc := AABB()
	var started := false
	var stack: Array[Node] = [root]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is VisualInstance3D):
			continue
		var vi := node as VisualInstance3D
		var box := vi.global_transform * vi.get_aabb()
		if box.size.length() < 0.0001:
			continue
		if not started:
			acc = box
			started = true
		else:
			acc = acc.merge(box)
	return acc


func _frame_outside_set() -> void:
	var room := get_node_or_null("Room")
	if room == null:
		return
	var aabb := _visual_aabb(room)
	if aabb.size.length() < 0.01:
		return
	var front_z := aabb.position.z + aabb.size.z
	_zoom = clampf(front_z + 1.7, MIN_ZOOM, MAX_ZOOM)
	if _shaft:
		_shaft.position = Vector3(aabb.get_center().x * 0.15, aabb.size.y * 0.72, aabb.position.z + 0.35)
		_shaft.look_at(Vector3(0, 1.1, 0.1), Vector3.UP)


func _add_motes() -> void:
	var motes := GPUParticles3D.new()
	motes.name = "Motes"
	motes.amount = 42
	motes.lifetime = 7.5
	motes.preprocess = 3.0
	motes.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 6, 8))
	motes.position = Vector3(0, 1.7, -0.6)
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(2.1, 1.5, 2.0)
	process.gravity = Vector3(0, 0.03, 0)
	process.initial_velocity_min = 0.02
	process.initial_velocity_max = 0.08
	process.angular_velocity_min = -0.4
	process.angular_velocity_max = 0.4
	process.scale_min = 0.35
	process.scale_max = 1.0
	process.color = Color(0.62, 0.92, 1.0, 0.7)
	motes.process_material = process
	var draw := SphereMesh.new()
	draw.radius = 0.028
	draw.height = 0.056
	draw.radial_segments = 8
	draw.rings = 4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.72, 0.94, 1.0, 0.42)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.85, 1.0)
	mat.emission_energy_multiplier = 2.4
	draw.material = mat
	motes.draw_pass_1 = draw
	add_child(motes)


func _make_light(light_name: String) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = light_name
	light.shadow_enabled = true
	add_child(light)
	return light


func _configure_light(light: DirectionalLight3D, color: Color, energy: float, degrees: Vector3) -> void:
	light.light_color = color
	light.light_energy = energy
	light.rotation_degrees = degrees


func _configure_shaft(color: Color, energy: float) -> void:
	if _shaft == null:
		return
	_shaft.light_color = color
	_shaft.light_energy = energy


func _configure_dais(color: Color, energy: float) -> void:
	if _dais_glow == null:
		return
	_dais_glow.light_color = color
	_dais_glow.light_energy = energy


func _refresh_camera() -> void:
	if _pivot == null or _camera == null:
		return
	_pivot.position = Vector3(0, 1.12, 0.12)
	_pivot.rotation = Vector3(_pitch, _yaw, 0.0)
	_camera.position = Vector3(0, 0.1, _zoom)
	_camera.rotation = Vector3.ZERO
