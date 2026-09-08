extends SceneTree

const GameStateScript := preload("res://game/sim/game_state.gd")
const SettingsShellScript := preload("res://game/flow/settings_shell.gd")

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
	failed += _ok("boot_skips_in_headless", _test_boot_skips_in_headless())
	failed += _ok("boot_reaches_title", _test_boot_reaches_title())
	failed += _ok("title_menu_actions", _test_title_menu_actions())
	failed += _ok("new_opens_creator", _test_new_opens_creator())
	failed += _ok("creator_back_to_title", _test_creator_back_to_title())
	failed += _ok("creator_atelier_shell", await _test_creator_atelier_shell())
	failed += _ok("creator_lighting_presets", _test_creator_lighting_presets())
	failed += _ok("creator_reset_randomize", _test_creator_reset_randomize())
	failed += _ok("creator_race_select", _test_creator_race_select())
	failed += _ok("creator_sex_select", _test_creator_sex_select())
	failed += _ok("character_record_schema_v1", _test_character_record_schema_v1())
	failed += _ok("debug_skip_not_a_title_button", _test_debug_skip_not_a_title_button())
	failed += _ok("quit_path_callable", _test_quit_path_callable())
	failed += _ok("settings_open_and_back", _test_settings_open_and_back())
	failed += _ok("settings_sections", _test_settings_sections())
	failed += _ok("settings_panel_centered", await _test_settings_panel_centered())
	failed += _ok("load_open_and_back", _test_load_open_and_back())
	failed += _ok("load_empty_state", _test_load_empty_state())
	failed += _ok("load_unsupported_save", _test_load_unsupported_save())
	failed += _ok("create_overlay_hidden_on_boot", await _test_create_overlay_hidden_on_boot())
	failed += _ok("ui_menu_actions_bound", _test_ui_menu_actions_bound())
	failed += _ok("title_focus_loop", _test_title_focus_loop())
	failed += _ok("prompt_glyphs_and_cancel", _test_prompt_glyphs_and_cancel())
	failed += _ok("millbrook_hud_cannot_steal_focus", await _test_millbrook_hud_cannot_steal_focus())
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


func _flow() -> Node:
	return root.get_node_or_null("AppFlow")


func _test_boot_skips_in_headless() -> bool:
	var flow := _flow()
	if flow == null:
		push_error("AppFlow autoload missing")
		return false
	if flow.visible:
		push_error("AppFlow should stay hidden in headless")
		return false
	return str(flow.screen_name()) == "none"


func _test_boot_reaches_title() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_title()
	var ok := str(flow.screen_name()) == "title"
	flow.hide_flow()
	return ok


func _test_title_menu_actions() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_title()
	var texts: PackedStringArray = flow.title_button_texts()
	var ok := texts == PackedStringArray(["New", "Load", "Settings", "Quit"])
	if not ok:
		push_error("Title actions were %s" % str(texts))
	flow.hide_flow()
	return ok


func _test_new_opens_creator() -> bool:
	var flow := _flow()
	if flow == null:
		push_error("AppFlow autoload missing")
		return false
	flow.show_title()
	var new_button := flow.get_node_or_null("TitleScreen/Menu/NewButton") as BaseButton
	if new_button == null:
		push_error("Title New button missing")
		flow.hide_flow()
		return false
	new_button.pressed.emit()
	var headline := str(flow.creator_headline()).to_lower()
	var body := str(flow.creator_body()).to_lower()
	var ok: bool = (
		str(flow.screen_name()) == "creator"
		and headline.find("character") >= 0
		and body.find("creator") >= 0
		and body.find("town") >= 0
		and flow.creator_atelier_ready()
		and not flow.creator_uses_stub()
		and ResourceLoader.exists("res://game/art/characters/creator_atelier_chamber.glb")
		and ResourceLoader.exists("res://game/art/characters/creator_atelier_bg.png")
		and ResourceLoader.exists("res://game/art/vfx/title_to_creator_wipe.png")
	)
	if not ok:
		push_error(
			"New should land on atelier creator; screen=%s headline=%s"
			% [flow.screen_name(), flow.creator_headline()]
		)
	var creator := flow.get_node_or_null("CreatorScreen") as Control
	var millbrook := root.get_node_or_null("HUD/Create") as Control
	if creator == null or not creator.visible:
		push_error("CreatorScreen should be visible after New")
		ok = false
	if millbrook and millbrook.visible:
		push_error("Millbrook create overlay must stay hidden on the New path")
		ok = false
	if creator and creator.get_node_or_null("StageHost/StageView/Atelier") == null:
		push_error("Creator atelier 3D stage missing")
		ok = false
	flow.hide_flow()
	return ok


func _test_creator_back_to_title() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_creator()
	if str(flow.screen_name()) != "creator":
		push_error("Creator did not open")
		flow.hide_flow()
		return false
	var back := flow.get_node_or_null("CreatorScreen/Chrome/Copy/BackButton") as BaseButton
	if back == null:
		push_error("Creator Back button missing")
		flow.hide_flow()
		return false
	back.pressed.emit()
	var ok := str(flow.screen_name()) == "title"
	if not ok:
		push_error("Creator Back did not return to title")
	flow.hide_flow()
	return ok


func _test_creator_atelier_shell() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_creator()
	await process_frame
	var creator := flow.get_node_or_null("CreatorScreen")
	var ids: PackedStringArray = flow.creator_category_ids()
	var expected := PackedStringArray(["race", "body", "face", "features", "outfit"])
	var ok: bool = (
		ids == expected
		and str(flow.creator_current_category()) == "race"
		and str(flow.creator_lighting_preset()) == "full"
		and flow.creator_has_reset_randomize()
		and creator != null
		and creator.find_child("NameEdit", true, false) != null
		and creator.find_child("Mannequin", true, false) != null
		and creator.find_child("RaceGrid", true, false) != null
		and creator.find_child("HumanRace", true, false) != null
		and creator.find_child("KeyLight", true, false) != null
		and creator.find_child("Room", true, false) != null
		and creator.find_child("Chamber", true, false) != null
	)
	if not ok:
		push_error(
			"Atelier shell incomplete; cats=%s light=%s name=%s mannequin=%s key=%s reset=%s"
			% [
				str(ids),
				flow.creator_lighting_preset(),
				str(creator.find_child("NameEdit", true, false) != null if creator else false),
				str(creator.find_child("Mannequin", true, false) != null if creator else false),
				str(creator.find_child("KeyLight", true, false) != null if creator else false),
				str(flow.creator_has_reset_randomize()),
			]
		)
	flow.creator_set_category("body")
	if str(flow.creator_current_category()) != "body":
		push_error("Category switch failed")
		ok = false
	flow.hide_flow()
	return ok


func _test_creator_lighting_presets() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_creator()
	var ok := str(flow.creator_lighting_preset()) == "full"
	flow.creator_set_lighting("dawn")
	ok = ok and str(flow.creator_lighting_preset()) == "dawn"
	flow.creator_set_lighting("dusk")
	ok = ok and str(flow.creator_lighting_preset()) == "dusk"
	var cycled: String = str(flow.creator_cycle_lighting())
	ok = ok and cycled != "dusk"
	flow.creator_set_lighting("full")
	ok = ok and str(flow.creator_lighting_preset()) == "full"
	if not ok:
		push_error("Lighting presets did not cycle; now=%s" % flow.creator_lighting_preset())
	flow.hide_flow()
	return ok


func _test_creator_reset_randomize() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_creator()
	var creator := flow.get_node_or_null("CreatorScreen")
	if creator == null or not creator.has_method("randomize_all"):
		push_error("Creator reset/randomize missing")
		flow.hide_flow()
		return false
	creator.randomize_all()
	var randomized: Dictionary = creator.draft.to_dict()
	var kept_race := str(randomized.get("race", "human"))
	creator.reset_all()
	var reset: Dictionary = creator.draft.to_dict()
	var PresetsScript := load("res://game/character/race_presets.gd")
	var expected_height := float((PresetsScript.PRESETS[kept_race] as Dictionary).get("height", 0.5))
	var ok: bool = (
		str(reset["race"]) == kept_race
		and is_equal_approx(float(reset["body"]["height"]), expected_height)
		and str(reset["outfit"]["id"]) == "outfit_starter_01"
		and (reset as Dictionary).has("loadout")
		and randomized != reset
	)
	if not ok:
		push_error("Reset/randomize did not mutate then restore the draft")
	flow.hide_flow()
	return ok


func _test_creator_race_select() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_creator()
	var creator := flow.get_node_or_null("CreatorScreen")
	if creator == null or not creator.has_method("select_race"):
		push_error("Creator race select missing")
		flow.hide_flow()
		return false
	if not flow.creator_race_art_ready():
		push_error("Race cards / underwear body missing")
		flow.hide_flow()
		return false
	if not ResourceLoader.exists("res://game/art/characters/body_base_underwear.glb"):
		push_error("Underwear base mesh missing")
		flow.hide_flow()
		return false
	var RecordScript := load("res://game/character/character_record.gd")
	var PresetsScript := load("res://game/character/race_presets.gd")
	var mannequin := creator.find_child("Mannequin", true, false) as MeshInstance3D
	var heights := {}
	for race_id in RecordScript.RACES:
		creator.select_race(race_id)
		if str(creator.draft.race) != race_id:
			push_error("Race tag not stored for %s" % race_id)
			flow.hide_flow()
			return false
		if creator.find_child("%sRace" % race_id.capitalize(), true, false) == null:
			push_error("Race card button missing for %s" % race_id)
			flow.hide_flow()
			return false
		var preset: Dictionary = PresetsScript.PRESETS[race_id]
		var height := float(creator.draft.body.get("height", -1.0))
		heights[race_id] = height
		if not is_equal_approx(height, float(preset.get("height", -2.0))):
			push_error("Preset height not applied for %s" % race_id)
			flow.hide_flow()
			return false
	if is_equal_approx(float(heights["human"]), float(heights["dwarf"])):
		push_error("Race presets must change a measurable morph")
		flow.hide_flow()
		return false
	if mannequin:
		creator.select_race("human")
		var human_scale: Vector3 = mannequin.scale
		creator.select_race("dwarf")
		if mannequin.scale.is_equal_approx(human_scale):
			push_error("Preview scale should change with race preset")
			flow.hide_flow()
			return false
	creator.select_race("dwarf")
	creator.override_body_field("height", 0.92)
	if str(creator.draft.race) != "dwarf" or not is_equal_approx(float(creator.draft.body.height), 0.92):
		push_error("Override after preset should stick")
		flow.hide_flow()
		return false
	creator.select_race("elf")
	if str(creator.draft.race) != "elf":
		push_error("Re-selecting race should retag")
		flow.hide_flow()
		return false
	if not is_equal_approx(float(creator.draft.body.height), float(PresetsScript.PRESETS["elf"]["height"])):
		push_error("Re-selecting race should reapply preset")
		flow.hide_flow()
		return false
	flow.hide_flow()
	return true


func _test_creator_sex_select() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_creator()
	var creator := flow.get_node_or_null("CreatorScreen")
	if creator == null or not creator.has_method("select_sex"):
		push_error("Creator sex select missing")
		flow.hide_flow()
		return false
	if not creator.body_kit_art_ready():
		push_error("Male/Female underwear kits missing")
		flow.hide_flow()
		return false
	if creator.find_child("MaleSex", true, false) == null or creator.find_child("FemaleSex", true, false) == null:
		push_error("Male/Female buttons missing")
		flow.hide_flow()
		return false
	flow.creator_set_category("body")
	if str(flow.creator_current_category()) != "body":
		push_error("Body category should show sex controls")
		flow.hide_flow()
		return false
	var sex_row := creator.find_child("SexRow", true, false) as Control
	if sex_row == null or not sex_row.visible:
		push_error("Sex row should be visible on Body")
		flow.hide_flow()
		return false
	creator.select_race("dwarf")
	creator.override_body_field("height", 0.92)
	var outfit_id := str(creator.draft.outfit.get("id", ""))
	if str(creator.draft.body.get("sex", "")) != "male":
		push_error("Default sex should be male")
		flow.hide_flow()
		return false
	if str(creator.preview_kit_id()) != "male":
		push_error("Preview kit should start male; got %s" % creator.preview_kit_id())
		flow.hide_flow()
		return false
	creator.select_sex("female")
	if str(creator.draft.body.get("sex", "")) != "female":
		push_error("body.sex should serialize female")
		flow.hide_flow()
		return false
	if str(creator.preview_kit_id()) != "female":
		push_error("Preview kit should swap to female; got %s" % creator.preview_kit_id())
		flow.hide_flow()
		return false
	if str(creator.draft.race) != "dwarf" or not is_equal_approx(float(creator.draft.body.height), 0.92):
		push_error("Sex swap should keep race and morph overrides")
		flow.hide_flow()
		return false
	if str(creator.draft.outfit.get("id", "")) != outfit_id:
		push_error("Sex swap should not clear outfit")
		flow.hide_flow()
		return false
	creator.reset_category()
	if str(creator.draft.body.get("sex", "")) != "female":
		push_error("Reset category should keep current sex")
		flow.hide_flow()
		return false
	creator.reset_all()
	if str(creator.draft.body.get("sex", "")) != "female":
		push_error("Reset all should keep current sex")
		flow.hide_flow()
		return false
	creator.select_sex("male")
	if str(creator.preview_kit_id()) != "male":
		push_error("Preview kit should swap back to male")
		flow.hide_flow()
		return false
	flow.hide_flow()
	return true


func _test_character_record_schema_v1() -> bool:
	var RecordScript := load("res://game/character/character_record.gd")
	var record = RecordScript.new()
	var data: Dictionary = record.to_dict()
	var errors: PackedStringArray = RecordScript.validate_dict(data)
	if not errors.is_empty():
		push_error("Default record invalid: %s" % str(errors))
		return false
	if int(data.get("schema_version", 0)) != 1:
		push_error("schema_version must be 1")
		return false
	if not data["loadout"]["hands"].has("main"):
		push_error("loadout must stay distinct from outfit")
		return false
	if str(data["body"].get("sex", "")) != "male":
		push_error("Default body.sex should be male")
		return false
	var morphs: Dictionary = data["face"]["morphs"]
	for key in ["brow", "eye_shape", "nose", "cheek", "jaw", "mouth", "chin"]:
		if not morphs.has(key):
			push_error("Missing face morph %s" % key)
			return false
	var bad := data.duplicate(true)
	bad["race"] = "dragon"
	if RecordScript.validate_dict(bad).is_empty():
		push_error("Illegal race should fail validation")
		return false
	var bad_sex := data.duplicate(true)
	bad_sex["body"] = (bad_sex["body"] as Dictionary).duplicate(true)
	bad_sex["body"]["sex"] = "other"
	if RecordScript.validate_dict(bad_sex).is_empty():
		push_error("Illegal body.sex should fail validation")
		return false
	return true


func _test_debug_skip_not_a_title_button() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_title()
	var texts: PackedStringArray = flow.title_button_texts()
	var joined := ",".join(texts).to_lower()
	var ok := (
		texts == PackedStringArray(["New", "Load", "Settings", "Quit"])
		and joined.find("skip") < 0
		and joined.find("debug") < 0
		and flow.has_method("request_debug_world")
		and int(flow.DEBUG_SKIP_KEY) == KEY_F10
	)
	if not ok:
		push_error("Debug skip must stay off the title; actions=%s" % str(texts))
	flow.hide_flow()
	return ok


func _test_quit_path_callable() -> bool:
	var flow := _flow()
	return flow != null and flow.has_method("request_quit")


func _test_settings_open_and_back() -> bool:
	var flow := _flow()
	if flow == null:
		push_error("AppFlow autoload missing")
		return false
	flow.show_title()
	flow.show_settings()
	if str(flow.screen_name()) != "settings":
		push_error("Settings did not open from title")
		flow.hide_flow()
		return false
	flow.show_title()
	if str(flow.screen_name()) != "title":
		push_error("Settings did not return to title")
		flow.hide_flow()
		return false
	flow.hide_flow()
	return true


func _test_settings_sections() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_settings()
	var ids: PackedStringArray = flow.settings_section_ids()
	if ids != PackedStringArray(["audio", "graphics", "controls"]):
		push_error("Settings sections were %s" % str(ids))
		flow.hide_flow()
		return false
	var notice := str(flow.settings_placeholder_notice())
	if notice.find("not saved") < 0:
		push_error("Settings missing placeholder persistence notice")
		flow.hide_flow()
		return false
	flow.show_settings_section("controls")
	if str(flow.settings_current_section()) != "controls":
		push_error("Controls section did not become current")
		flow.hide_flow()
		return false
	var blurb := str(flow.settings_controls_blurb()).to_lower()
	if blurb.find("keyboard") < 0 or blurb.find("gamepad") < 0:
		push_error("Controls section does not acknowledge KBM + gamepad")
		flow.hide_flow()
		return false
	flow.show_title()
	flow.hide_flow()
	return true


func _test_settings_panel_centered() -> bool:
	var host := Control.new()
	host.name = "SettingsLayoutHost"
	host.size = Vector2(1280, 720)
	root.add_child(host)
	await process_frame
	var shell: Control = SettingsShellScript.new()
	host.add_child(shell)
	if shell.has_method("fill_parent"):
		shell.fill_parent()
	shell.visible = true
	await process_frame
	await process_frame
	var panel := shell.get_node_or_null("Center/Panel") as Control
	if panel == null:
		push_error("Settings panel missing at Center/Panel")
		host.queue_free()
		await process_frame
		return false
	var host_center := host.global_position + host.size * 0.5
	var panel_center := panel.global_position + panel.size * 0.5
	var distance := panel_center.distance_to(host_center)
	var margin := shell.get_node_or_null("Center/Panel/Margin") as Control
	var content := shell.get_node_or_null("Center/Panel/Margin/Root") as Control
	var inset_left := 0.0
	var inset_top := 0.0
	var inset_right := 0.0
	if margin:
		inset_left = float(margin.get_theme_constant("margin_left"))
		inset_top = float(margin.get_theme_constant("margin_top"))
		inset_right = float(margin.get_theme_constant("margin_right"))
	if content:
		inset_left = maxf(inset_left, content.global_position.x - panel.global_position.x)
		inset_top = maxf(inset_top, content.global_position.y - panel.global_position.y)
	var landscape := panel.size.x > panel.size.y * 1.2
	var ok := (
		distance < 48.0
		and panel.size.x >= 800.0
		and landscape
		and inset_left >= 80.0
		and inset_top >= 72.0
		and inset_right >= 180.0
	)
	if not ok:
		push_error(
			"Settings panel layout off; host=%s panel=%s size=%s dist=%s inset=(%s,%s,%s) landscape=%s"
			% [host_center, panel_center, panel.size, distance, inset_left, inset_top, inset_right, landscape]
		)
	host.queue_free()
	await process_frame
	return ok


func _test_load_open_and_back() -> bool:
	var flow := _flow()
	if flow == null:
		push_error("AppFlow autoload missing")
		return false
	flow.set_load_probe_path("user://os4_load_probe_missing.json")
	flow.show_title()
	flow.show_load()
	if str(flow.screen_name()) != "load":
		push_error("Load did not open from title")
		flow.hide_flow()
		return false
	flow.show_title()
	if str(flow.screen_name()) != "title":
		push_error("Load did not return to title")
		flow.hide_flow()
		return false
	flow.hide_flow()
	return true


func _test_load_empty_state() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	var path := "user://os4_load_probe_empty.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	flow.set_load_probe_path(path)
	flow.show_load()
	var state := str(flow.load_state())
	var message := str(flow.load_message()).to_lower()
	var ok := state == "empty" and message.find("no saves") >= 0
	if not ok:
		push_error("Expected empty load state, got %s / %s" % [state, flow.load_message()])
	if not ResourceLoader.exists("res://game/art/ui/load_empty.png"):
		push_error("Missing load_empty.png")
		ok = false
	if not ResourceLoader.exists("res://game/art/ui/save_slot_frame.png"):
		push_error("Missing save_slot_frame.png")
		ok = false
	flow.hide_flow()
	return ok


func _test_load_unsupported_save() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	var path := "user://os4_load_probe_unsupported.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write probe save")
		return false
	file.store_string('{"save_version":1,"note":"millbrook-probe"}')
	file.close()
	flow.set_load_probe_path(path)
	flow.show_load()
	var state := str(flow.load_state())
	var message := str(flow.load_message()).to_lower()
	var detail := str(flow.load_detail()).to_lower()
	var ok := (
		state == "unsupported"
		and message.find("supported") >= 0
		and (detail.find("town") >= 0 or detail.find("prototype") >= 0)
		and str(flow.screen_name()) == "load"
	)
	if not ok:
		push_error(
			"Unsupported save should stay on load with a message; state=%s screen=%s msg=%s"
			% [state, flow.screen_name(), flow.load_message()]
		)
	flow.show_title()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	flow.hide_flow()
	return ok


func _test_create_overlay_hidden_on_boot() -> bool:
	var packed := load("res://game/main.tscn")
	if packed == null:
		return false
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var create := scene.get_node_or_null("HUD/Create") as Control
	var ok := create != null and not create.visible
	if not ok:
		push_error("Millbrook create overlay should stay hidden on boot")
	scene.queue_free()
	await process_frame
	return ok


func _test_ui_menu_actions_bound() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	var actions: PackedStringArray = flow.ui_menu_actions()
	if actions != PackedStringArray(["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]):
		push_error("Unexpected UI menu actions: %s" % str(actions))
		return false
	for action in actions:
		if not InputMap.has_action(action):
			push_error("Missing action %s" % action)
			return false
		if not flow.action_has_keyboard(action):
			push_error("%s missing keyboard binding" % action)
			return false
		if not flow.action_has_joypad(action):
			push_error("%s missing joypad binding" % action)
			return false
	return true


func _test_title_focus_loop() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	flow.show_title()
	var ok := bool(flow.title_focus_loop_ok())
	if not ok:
		push_error("Title buttons must have a vertical focus loop")
	flow.hide_flow()
	return ok


func _test_prompt_glyphs_and_cancel() -> bool:
	var flow := _flow()
	if flow == null:
		return false
	if not flow.glyph_paths_exist():
		push_error("Missing OS-6 glyph or focus ring art")
		return false
	flow.show_title()
	var title_hints: PackedStringArray = flow.prompt_hint_labels()
	var title_ok: bool = (
		flow.prompt_bar_visible()
		and title_hints.has("Navigate")
		and title_hints.has("Confirm")
		and not title_hints.has("Back")
	)
	if not title_ok:
		push_error("Title prompt should show Navigate/Confirm without Back; hints=%s" % str(title_hints))
		flow.hide_flow()
		return false
	flow.show_settings()
	var settings_hints: PackedStringArray = flow.prompt_hint_labels()
	if not settings_hints.has("Back"):
		push_error("Settings prompt should show Back")
		flow.hide_flow()
		return false
	if not flow.try_cancel() or str(flow.screen_name()) != "title":
		push_error("ui_cancel / try_cancel should return from settings to title")
		flow.hide_flow()
		return false
	flow.show_load()
	if not flow.try_cancel() or str(flow.screen_name()) != "title":
		push_error("Cancel from load should return to title")
		flow.hide_flow()
		return false
	flow.show_creator()
	if not flow.try_cancel() or str(flow.screen_name()) != "title":
		push_error("Cancel from creator should return to title")
		flow.hide_flow()
		return false
	flow.hide_flow()
	return true


func _test_millbrook_hud_cannot_steal_focus() -> bool:
	var packed := load("res://game/main.tscn")
	if packed == null:
		return false
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var name_edit := scene.get_node_or_null("HUD/Create/Panel/VBox/NameEdit") as Control
	var start := scene.get_node_or_null("HUD/Create/Panel/VBox/StartButton") as Control
	var cont := scene.get_node_or_null("HUD/Create/Panel/VBox/ContinueButton") as Control
	var ok := (
		name_edit != null
		and start != null
		and cont != null
		and name_edit.focus_mode == Control.FOCUS_NONE
		and start.focus_mode == Control.FOCUS_NONE
		and cont.focus_mode == Control.FOCUS_NONE
	)
	if not ok:
		push_error("Millbrook create HUD must not be focusable during title flow")
	scene.queue_free()
	await process_frame
	return ok
