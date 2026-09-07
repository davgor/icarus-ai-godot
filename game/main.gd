extends Node3D

const GameStateScript := preload("res://game/sim/game_state.gd")

const SPOTS := {
	"square": Vector3(0.0, 0.0, 4.0),
	"inn": Vector3(-11.0, 0.0, 2.0),
	"shop": Vector3(11.0, 0.0, 2.0),
	"gate": Vector3(0.0, 0.0, -16.0),
}

var state = GameStateScript.new()
var nearby: Node = null
var dialogue: Dictionary = {}
var debug_visible := false

var _player: CharacterBody3D
var _clock: Label
var _help: Label
var _prompt: Label
var _debug: Label
var _create: Control
var _name_edit: LineEdit
var _dialogue: Control
var _speaker: Label
var _body: Label
var _options: VBoxContainer
var _elara: Node3D
var _tomas: Node3D
var _brann: Node3D
var _gate: Node3D


func _ready() -> void:
	print("Icarus AI Millbrook ready")
	_bind_nodes()
	if _elara:
		_elara.proximity_changed.connect(_on_proximity)
	if _tomas:
		_tomas.proximity_changed.connect(_on_proximity)
	if _brann:
		_brann.proximity_changed.connect(_on_proximity)
	if _gate:
		_gate.proximity_changed.connect(_on_proximity)
	var flow := get_node_or_null("/root/AppFlow")
	if flow and flow.has_signal("world_requested"):
		if not flow.world_requested.is_connected(_on_flow_world_requested):
			flow.world_requested.connect(_on_flow_world_requested)
	if DisplayServer.get_name() == "headless":
		state.create_character("Tester")
		_enter_world()
		return
	_park_world()


func _bind_nodes() -> void:
	_player = get_node_or_null("Player") as CharacterBody3D
	_clock = get_node_or_null("HUD/Clock") as Label
	_help = get_node_or_null("HUD/Help") as Label
	_prompt = get_node_or_null("HUD/Prompt") as Label
	_debug = get_node_or_null("HUD/Debug") as Label
	_create = get_node_or_null("HUD/Create") as Control
	_name_edit = get_node_or_null("HUD/Create/Panel/VBox/NameEdit") as LineEdit
	_dialogue = get_node_or_null("HUD/Dialogue") as Control
	_speaker = get_node_or_null("HUD/Dialogue/Panel/VBox/Speaker") as Label
	_body = get_node_or_null("HUD/Dialogue/Panel/VBox/Body") as Label
	_options = get_node_or_null("HUD/Dialogue/Panel/VBox/Options") as VBoxContainer
	_elara = get_node_or_null("Elara") as Node3D
	_tomas = get_node_or_null("Tomas") as Node3D
	_brann = get_node_or_null("Brann") as Node3D
	_gate = get_node_or_null("Gate") as Node3D
	if _player == null:
		push_error("Millbrook missing Player node")


func _unhandled_input(event: InputEvent) -> void:
	if _create and _create.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				_try_interact()
			KEY_F3:
				debug_visible = not debug_visible
				_refresh_hud()
			KEY_F5:
				_save()
			KEY_F9:
				_load()


func _process(_delta: float) -> void:
	if _create and _create.visible:
		return
	_place_npcs()
	_refresh_hud()


func _on_start_pressed() -> void:
	var chosen := "Ash"
	if _name_edit and not _name_edit.text.strip_edges().is_empty():
		chosen = _name_edit.text.strip_edges()
	state.create_character(chosen)
	_enter_world()


func _on_name_submitted(_text: String) -> void:
	_on_start_pressed()


func _on_continue_pressed() -> void:
	if not state.load_from_path():
		return
	_enter_world()


func _on_flow_world_requested() -> void:
	if state.player_name.is_empty():
		state.create_character("Ash")
	_enter_world()


func _park_world() -> void:
	if _create:
		_create.visible = false
	if _dialogue:
		_dialogue.visible = false
	if _player:
		_player.set_ui_open(true)
	_set_world_hud_visible(false)
	var tree := get_tree()
	if tree:
		tree.paused = true


func _enter_world() -> void:
	var tree := get_tree()
	if tree:
		tree.paused = false
	if _create:
		_create.visible = false
	if _dialogue:
		_dialogue.visible = false
	_set_world_hud_visible(true)
	if _player:
		_player.set_ui_open(false)
		_player.global_position = SPOTS[state.player_location] if SPOTS.has(state.player_location) else SPOTS["square"]
		_player.global_position.y = 0.1
	if _elara:
		_elara.set_display_name("Elara")
	if _tomas:
		_tomas.set_display_name("Tomas")
	if _brann:
		_brann.set_display_name("Brann")
	if _gate:
		_gate.set_display_name("Town Gate")
	_tint(_elara, Color(0.35, 0.62, 0.42))
	_tint(_tomas, Color(0.62, 0.42, 0.28))
	_tint(_brann, Color(0.45, 0.48, 0.55))
	_tint(_gate, Color(0.32, 0.3, 0.28))
	_place_npcs()
	_refresh_hud()


func _set_world_hud_visible(show_hud: bool) -> void:
	if _clock:
		_clock.visible = show_hud
	if _help:
		_help.visible = show_hud
	if _prompt:
		_prompt.visible = show_hud
	if _debug and not show_hud:
		_debug.visible = false


func _on_proximity(interactable: Node, near: bool) -> void:
	if near:
		nearby = interactable
	elif nearby == interactable:
		nearby = null


func _try_interact() -> void:
	if _dialogue and _dialogue.visible:
		return
	if nearby == null:
		return
	var interact_id := str(nearby.get("interact_id"))
	if interact_id == "gate":
		_leave_town()
		return
	var npc_id := str(nearby.get("npc_id"))
	if npc_id.is_empty():
		return
	dialogue = state.talk(npc_id)
	_show_dialogue(npc_id)


func _show_dialogue(npc_id: String) -> void:
	if _dialogue:
		_dialogue.visible = true
	if _player:
		_player.set_ui_open(true)
	if _speaker:
		_speaker.text = str(state.npcs[npc_id]["name"])
	if _body:
		_body.text = str(dialogue.get("text", ""))
	if _options == null:
		return
	for child in _options.get_children():
		child.queue_free()
	var options: Array = dialogue.get("options", [])
	for option in options:
		var button := Button.new()
		button.text = str(option["label"])
		var option_id := str(option["id"])
		button.pressed.connect(_on_option_pressed.bind(npc_id, option_id))
		_options.add_child(button)


func _on_option_pressed(npc_id: String, option_id: String) -> void:
	if option_id == "leave":
		_close_dialogue()
		return
	dialogue = state.choose(npc_id, option_id)
	_show_dialogue(npc_id)


func _close_dialogue() -> void:
	if _dialogue:
		_dialogue.visible = false
	if _player:
		_player.set_ui_open(false)


func _leave_town() -> void:
	state.leave_town()
	if _player:
		_player.global_position = SPOTS["gate"]
		_player.global_position.y = 0.1
	_place_npcs()
	_refresh_hud()
	print("Returned to Millbrook. %s" % state.time_label())


func _save() -> void:
	if state.save_to_path():
		print("Saved Millbrook (%s)" % state.time_label())


func _load() -> void:
	if state.load_from_path():
		_close_dialogue()
		_enter_world()
		print("Loaded Millbrook (%s)" % state.time_label())


func _place_npcs() -> void:
	_move_npc(_elara, "elara")
	_move_npc(_tomas, "tomas")
	_move_npc(_brann, "brann")


func _move_npc(node: Node3D, npc_id: String) -> void:
	if node == null:
		return
	var npc: Dictionary = state.npcs.get(npc_id, {})
	var loc := str(npc.get("location", "square"))
	var pos: Vector3 = SPOTS.get(loc, SPOTS["square"])
	var offsets := {
		"elara": Vector3(1.8, 0.0, 1.6),
		"tomas": Vector3(-1.8, 0.0, 1.6),
		"brann": Vector3(2.4, 0.0, 0.0),
	}
	var offset: Vector3 = offsets.get(npc_id, Vector3.ZERO)
	node.global_position = Vector3(pos.x + offset.x, 0.0, pos.z + offset.z)


func _tint(node: Node, color: Color) -> void:
	if node == null:
		return
	var mesh := node.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat


func _refresh_hud() -> void:
	if _clock == null:
		return
	_clock.text = "%s\n%s · %s" % [state.player_name, state.time_label(), state.period()]
	_help.text = "Millbrook\nWASD move · mouse look · E talk/leave · F5 save · F9 load · F3 debug"
	if _dialogue and _dialogue.visible:
		_prompt.text = ""
	elif nearby != null:
		var interact_id := str(nearby.get("interact_id"))
		if interact_id == "gate":
			_prompt.text = "E — Leave town for a day"
		else:
			_prompt.text = "E — Talk to %s" % str(nearby.get("npc_id")).capitalize()
	else:
		_prompt.text = ""
	if _debug:
		_debug.visible = debug_visible
		if debug_visible:
			var dump := PackedStringArray()
			dump.append(state.time_label())
			dump.append("Player inventory: %s" % ", ".join(state.player_inventory))
			dump.append("Flags: %s" % str(state.flags))
			for id in state.npc_ids():
				dump.append("")
				dump.append(state.debug_npc(id))
			_debug.text = "\n".join(dump)
