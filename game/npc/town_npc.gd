extends StaticBody3D

signal proximity_changed(interactable: Node, near: bool)

@export var npc_id := ""
@export var interact_id := ""

@onready var _label: Label3D = $NameLabel


func _ready() -> void:
	add_to_group("interactable")
	if interact_id.is_empty():
		interact_id = npc_id
	if _label and not npc_id.is_empty():
		_label.text = npc_id.capitalize()


func set_display_name(p_name: String) -> void:
	if _label:
		_label.text = p_name


func _on_talk_range_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		proximity_changed.emit(self, true)


func _on_talk_range_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		proximity_changed.emit(self, false)
