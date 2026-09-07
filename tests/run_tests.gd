extends SceneTree

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
