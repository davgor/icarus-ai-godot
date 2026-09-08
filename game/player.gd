extends CharacterBody3D

const SPEED := 6.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002
const CAMERA_MIN_PITCH := deg_to_rad(-50.0)
const CAMERA_MAX_PITCH := deg_to_rad(30.0)

const AppearanceApplierScript := preload("res://game/character/appearance_applier.gd")
const CapsuleBuilderScript := preload("res://game/character/capsule_builder.gd")

## Horizontal input used by headless tests. Gameplay uses WASD when this is Vector2.ZERO.
var forced_move_input := Vector2.ZERO
var ui_open := false

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _body_mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("player")
	_refresh_mouse()


func apply_character_record(record) -> void:
	if record == null:
		return
	AppearanceApplierScript.apply(record, self)
	_apply_capsule(record.body)
	if _body_mesh:
		_body_mesh.visible = get_node_or_null("Preview/BodyKit") == null


func _apply_capsule(body: Dictionary) -> void:
	if _collision == null:
		return
	var shape := _collision.shape as CapsuleShape3D
	if shape == null:
		shape = CapsuleShape3D.new()
		_collision.shape = shape
	shape.height = CapsuleBuilderScript.capsule_height(body)
	shape.radius = CapsuleBuilderScript.capsule_radius(body)
	_collision.position.y = shape.height * 0.5
	if _body_mesh:
		_body_mesh.position.y = shape.height * 0.5
	if _camera_pivot:
		_camera_pivot.position.y = CapsuleBuilderScript.camera_pivot_height(body)


func capsule_height() -> float:
	if _collision and _collision.shape is CapsuleShape3D:
		return (_collision.shape as CapsuleShape3D).height
	return 1.8


func camera_pivot_height() -> float:
	if _camera_pivot:
		return _camera_pivot.position.y
	return 1.4


func set_ui_open(open: bool) -> void:
	ui_open = open
	_refresh_mouse()


func _refresh_mouse() -> void:
	if not DisplayServer.window_can_draw():
		return
	if ui_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if ui_open:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		_camera_pivot.rotation.x = clampf(
			_camera_pivot.rotation.x, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH
		)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	AppearanceApplierScript.tick_jiggle(self, delta)
	if not is_on_floor():
		velocity += get_gravity() * delta

	if ui_open:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := _read_move_input()
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()


func _read_move_input() -> Vector2:
	if forced_move_input != Vector2.ZERO:
		return forced_move_input
	return Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
