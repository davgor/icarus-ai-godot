extends SceneTree

const GameStateScript := preload("res://game/sim/game_state.gd")

## Headless validation suite.
## Entry: engine --headless --path . -s res://tests/run_tests.gd
## `_init()` is the -s entry point. Always call quit(code) or the process hangs.

func _init() -> void:
	call_deferred("_start")


func _start() -> void:
	var exit_code := await _run_suite()
	if exit_code == 0:
		print("TEST_RESULT: PASS")
	else:
		print("TEST_RESULT: FAIL")
	quit(exit_code)


func _run_suite() -> int:
	var failed := 0
	failed += _ok("main_scene_configured", _test_main_scene_configured())
	failed += _ok("main_scene_loads", await _test_main_scene_loads())
	failed += _ok("player_exists", await _test_player_exists())
	failed += _ok("player_moves", await _test_player_moves())
	failed += _ok("create_character", _test_create_character())
	failed += _ok("return_doll_and_gift", _test_return_doll_and_gift())
	failed += _ok("leave_without_help", _test_leave_without_help())
	failed += _ok("save_and_load", _test_save_and_load())
	return failed


func _ok(test_name: String, passed: bool) -> int:
	if passed:
		print("TEST ok ", test_name)
		return 0
	print("TEST fail ", test_name)
	push_error("TEST fail " + test_name)
	return 1


func _test_main_scene_configured() -> bool:
	var main_scene := str(ProjectSettings.get_setting("application/run/main_scene"))
	return main_scene == "res://game/main.tscn"


func _test_main_scene_loads() -> bool:
	var packed := load("res://game/main.tscn")
	if packed == null:
		push_error("Could not load res://game/main.tscn")
		return false
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var ok := scene.is_inside_tree()
	scene.queue_free()
	await process_frame
	return ok


func _test_player_exists() -> bool:
	var packed := load("res://game/main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var player := scene.get_node_or_null("Player")
	var ok := player is CharacterBody3D
	scene.queue_free()
	await process_frame
	return ok


func _test_player_moves() -> bool:
	var packed := load("res://game/main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var player := scene.get_node("Player") as CharacterBody3D
	var start := player.global_position
	player.set("forced_move_input", Vector2(0, -1))
	for i in 30:
		await physics_frame
	var distance := player.global_position.distance_to(start)
	var ok := distance > 0.5
	if not ok:
		push_error("Player did not move; distance=%s" % distance)
	scene.queue_free()
	await process_frame
	return ok


func _test_create_character() -> bool:
	var gs := GameStateScript.new()
	gs.create_character("Ash")
	return (
		gs.player_name == "Ash"
		and gs.npcs.has("elara")
		and gs.npcs.has("tomas")
		and gs.npcs.has("brann")
		and gs.day == 1
	)


func _test_return_doll_and_gift() -> bool:
	var gs := GameStateScript.new()
	gs.create_character("Ash")
	gs.talk("tomas")
	gs.choose("tomas", "take_doll")
	if not gs.player_inventory.has("mira_doll"):
		push_error("Player did not receive mira_doll")
		return false
	gs.choose("elara", "return_doll")
	if not gs.flags.get("returned_doll", false):
		push_error("returned_doll flag missing")
		return false
	var rel := float(gs.npcs["elara"]["relationships"].get("player", 0.0))
	if rel < 0.3:
		push_error("Elara relationship too low: %s" % rel)
		return false
	gs.leave_town()
	if not gs.flags.get("inn_gift_ready", false):
		push_error("Leaving after helping did not prepare inn gift")
		return false
	if gs.day < 2:
		push_error("Time did not advance")
		return false
	return true


func _test_leave_without_help() -> bool:
	var gs := GameStateScript.new()
	gs.create_character("Ash")
	gs.leave_town()
	if not gs.flags.get("doll_sold", false):
		push_error("Tomas did not sell the doll while the player was away")
		return false
	var text := str(gs.talk("elara").get("text", ""))
	if text.find("Tomas sold") < 0 and text.find("cried") < 0:
		push_error("Elara did not react to the sold doll: %s" % text)
		return false
	return true


func _test_save_and_load() -> bool:
	var path := "user://living_town_test.json"
	var gs := GameStateScript.new()
	gs.create_character("Ash")
	gs.choose("tomas", "take_doll")
	gs.choose("elara", "return_doll")
	gs.leave_town()
	if not gs.save_to_path(path):
		return false
	var loaded := GameStateScript.new()
	if not loaded.load_from_path(path):
		push_error("Failed to load test save")
		return false
	var ok: bool = (
		loaded.player_name == "Ash"
		and bool(loaded.flags.get("returned_doll", false))
		and bool(loaded.flags.get("inn_gift_ready", false))
		and loaded.day == gs.day
		and loaded.hour == gs.hour
	)
	if not ok:
		push_error("Loaded state did not match")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return ok
