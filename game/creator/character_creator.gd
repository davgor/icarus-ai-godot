extends Control

## Dedicated character atelier (CC-1 + CC-2 race + CC-10 male/female kits). Replaces the OS-5 stub body.

signal back_pressed

const CharacterRecordScript := preload("res://game/character/character_record.gd")
const AtelierPacked := preload("res://game/creator/atelier_stage.tscn")

const WIPE := "res://game/art/vfx/title_to_creator_wipe.png"
const ICON_BACK := "res://game/art/ui/icon_back.png"
const TAB_CHROME := "res://game/art/ui/creator_tab.png"
const LIGHT_ICONS := {
	"full": "res://game/art/ui/creator_light_full.png",
	"dawn": "res://game/art/ui/creator_light_dawn.png",
	"dusk": "res://game/art/ui/creator_light_dusk.png",
}
const ICON_RESET := "res://game/art/ui/creator_reset.png"
const ICON_RANDOM := "res://game/art/ui/creator_random.png"
const SLIDER_TRACK := "res://game/art/ui/widget_slider.png"
const SLIDER_FILL := "res://game/art/ui/creator_slider_fill.png"
const SLIDER_THUMB := "res://game/art/ui/creator_slider_thumb.png"
const BTN_CHROME := "res://game/art/ui/btn_primary.png"

const RacePresetsScript := preload("res://game/character/race_presets.gd")

const HEADLINE := "Character Creation"
const BODY_COPY := "Atelier creator — race, body, face, and outfit. Not the town. Confirm writes a character later."
const CATEGORY_COPY := {
	"race": "Race is a preset and a story tag. Pick a card to snap proportions; every morph stays overrideable.",
	"body": "Male or Female underwear base, then height, weight, muscle ↔ fat, and skin. Sex does not lock cosmetics. Weight is frame mass, not fatness.",
	"face": "Named face morphs, hair, eyes, scars, and markings land here.",
	"features": "Optional ears, horns, and tails — including a lizard tail. Unlocked from the start.",
	"outfit": "Starting clothes are cosmetics only. Loadout (weapons/armor) is not required here.",
}

var btn_normal: StyleBox
var btn_hover: StyleBox
var btn_focus: StyleBox

var draft = CharacterRecordScript.new()
var _rng := RandomNumberGenerator.new()
var _built := false
var _atelier: Node3D
var _viewport: SubViewport
var _stage_host: SubViewportContainer
var _back_button: Button
var _confirm_button: Button
var _name_edit: LineEdit
var _wipe: TextureRect
var _wipe_tween: Tween
var _category := "race"
var _tab_buttons: Dictionary = {}
var _light_buttons: Dictionary = {}
var _race_buttons: Dictionary = {}
var _race_grid: GridContainer
var _sex_row: HBoxContainer
var _sex_label: Label
var _sex_buttons: Dictionary = {}
var _panel_body: Label
var _reset_all: Button
var _reset_cat: Button
var _random_all: Button
var _random_cat: Button
var _focusables: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var played_directly := get_tree() != null and get_tree().current_scene == self
	visible = played_directly
	_rng.randomize()
	fill_parent()
	_ensure_input_map()
	_build()
	refresh_preview()
	if played_directly:
		play_enter()
	_sync_stage_active()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_sync_stage_active()


func fill_parent() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for child_name in ["StageHost", "Chrome", "Wipe"]:
		var child := get_node_or_null(child_name) as Control
		if child:
			child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func headline() -> String:
	return HEADLINE


func body_copy() -> String:
	return BODY_COPY


func lighting_preset() -> String:
	if _atelier and _atelier.has_method("apply_lighting"):
		return str(_atelier.lighting_preset)
	return "full"


func current_category() -> String:
	return _category


func category_ids() -> PackedStringArray:
	return CharacterRecordScript.CATEGORIES


func lighting_ids() -> PackedStringArray:
	return PackedStringArray(["full", "dawn", "dusk"])


func uses_stub_backdrop() -> bool:
	return false


func atelier_art_ready() -> bool:
	if not (
		ResourceLoader.exists("res://game/art/characters/creator_atelier_chamber.glb")
		and ResourceLoader.exists("res://game/art/characters/creator_atelier_bg.png")
		and ResourceLoader.exists("res://game/art/ui/creator_light_full.png")
		and ResourceLoader.exists("res://game/art/ui/creator_reset.png")
		and ResourceLoader.exists("res://game/art/ui/creator_random.png")
		and ResourceLoader.exists("res://game/art/ui/creator_tab.png")
	):
		return false
	return race_art_ready()


func race_art_ready() -> bool:
	for race_id in CharacterRecordScript.RACES:
		if not ResourceLoader.exists(RacePresetsScript.card_path(race_id)):
			return false
	return (
		ResourceLoader.exists("res://game/art/characters/body_base_underwear.png")
		and ResourceLoader.exists("res://game/art/characters/body_base_underwear.glb")
	)


func body_kit_art_ready() -> bool:
	return (
		ResourceLoader.exists("res://game/art/characters/body_base_male.png")
		and ResourceLoader.exists("res://game/art/characters/body_base_female.png")
		and ResourceLoader.exists("res://game/art/characters/body_base_male.glb")
		and ResourceLoader.exists("res://game/art/characters/body_base_female.glb")
	)


func selected_race() -> String:
	return str(draft.race)


func select_race(race_id: String) -> void:
	draft.apply_race_preset(race_id)
	refresh_preview()
	_sync_race_buttons()
	_sync_sex_buttons()


func selected_sex() -> String:
	return str(draft.body.get("sex", "male"))


func select_sex(sex_id: String) -> void:
	if CharacterRecordScript.SEXES.find(sex_id) < 0:
		return
	draft.body["sex"] = sex_id
	refresh_preview()
	_sync_sex_buttons()


func preview_kit_id() -> String:
	if _atelier and _atelier.has_method("current_kit_id"):
		return str(_atelier.current_kit_id())
	return ""


func override_body_field(key: String, value: float) -> void:
	draft.body[key] = clampf(value, 0.0, 1.0)
	refresh_preview()


func grab_default_focus() -> void:
	var tab := _tab_buttons.get("race") as Control
	if tab:
		tab.call_deferred("grab_focus")
	elif _back_button:
		_back_button.call_deferred("grab_focus")


func play_enter() -> void:
	draft = CharacterRecordScript.new()
	_category = "race"
	if _name_edit:
		_name_edit.text = ""
	set_category("race")
	set_lighting("full")
	refresh_preview()
	if DisplayServer.get_name() == "headless":
		if _wipe:
			_wipe.visible = false
		return
	if _wipe == null:
		return
	if _wipe_tween:
		_wipe_tween.kill()
	_wipe.visible = true
	_wipe.modulate = Color(1, 1, 1, 1)
	_wipe_tween = create_tween()
	_wipe_tween.tween_property(_wipe, "modulate:a", 0.0, 0.55)
	_wipe_tween.finished.connect(func() -> void:
		if _wipe:
			_wipe.visible = false
	)


func set_lighting(preset: String) -> void:
	if _atelier and _atelier.has_method("apply_lighting"):
		_atelier.apply_lighting(preset)
	_sync_light_buttons()


func cycle_lighting() -> String:
	if _atelier and _atelier.has_method("cycle_lighting"):
		_atelier.cycle_lighting()
	_sync_light_buttons()
	return lighting_preset()


func set_category(category: String) -> void:
	if CharacterRecordScript.CATEGORIES.find(category) < 0:
		category = "race"
	_category = category
	if _panel_body:
		_panel_body.text = str(CATEGORY_COPY.get(category, ""))
	if _race_grid:
		_race_grid.visible = category == "race"
	if _sex_row:
		_sex_row.visible = category == "body"
	if _sex_label:
		_sex_label.visible = category == "body"
	for id in _tab_buttons:
		var button := _tab_buttons[id] as Button
		button.button_pressed = id == category
	_sync_action_labels()
	_sync_race_buttons()
	_sync_sex_buttons()


func reset_all() -> void:
	var kept_name: String = str(draft.display_name)
	var kept_race: String = str(draft.race)
	var kept_sex: String = str(draft.body.get("sex", "male"))
	draft.reset_to_defaults()
	draft.apply_race_preset(kept_race)
	draft.body["sex"] = kept_sex
	draft.display_name = kept_name
	refresh_preview()
	_sync_race_buttons()
	_sync_sex_buttons()


func reset_category() -> void:
	draft.reset_category(_category)
	refresh_preview()
	_sync_race_buttons()
	_sync_sex_buttons()


func randomize_all() -> void:
	var kept_name: String = str(draft.display_name)
	draft.randomize_all(_rng)
	draft.display_name = kept_name
	refresh_preview()
	_sync_race_buttons()
	_sync_sex_buttons()


func randomize_category() -> void:
	draft.randomize_category(_category, _rng)
	refresh_preview()
	_sync_race_buttons()
	_sync_sex_buttons()


func refresh_preview() -> void:
	if _atelier and _atelier.has_method("apply_record"):
		_atelier.apply_record(draft)


func discard_draft() -> void:
	draft = CharacterRecordScript.new()
	if _name_edit:
		_name_edit.text = ""
	_sync_race_buttons()
	_sync_sex_buttons()


func _sync_stage_active() -> void:
	if _atelier:
		_atelier.set_process(visible)
	if _viewport:
		_viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
		)


func _build() -> void:
	if _built:
		return
	_built = true
	_ensure_styles()
	_build_stage()
	_build_chrome()
	_build_wipe()
	_wire_focus()
	set_category("race")
	set_lighting("full")


func _build_stage() -> void:
	_stage_host = SubViewportContainer.new()
	_stage_host.name = "StageHost"
	_stage_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_host.stretch = true
	_stage_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage_host.focus_mode = Control.FOCUS_NONE
	_stage_host.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_stage_host.gui_input.connect(_on_stage_gui_input)
	add_child(_stage_host)

	_viewport = SubViewport.new()
	_viewport.name = "StageView"
	_viewport.own_world_3d = true
	_viewport.handle_input_locally = false
	_viewport.physics_object_picking = false
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.size = Vector2i(1280, 720)
	_stage_host.add_child(_viewport)

	_atelier = AtelierPacked.instantiate()
	_atelier.name = "Atelier"
	_viewport.add_child(_atelier)


func _build_chrome() -> void:
	var chrome := Control.new()
	chrome.name = "Chrome"
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chrome)

	var title := Label.new()
	title.name = "Headline"
	title.text = HEADLINE
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.offset_left = 36
	title.offset_top = 22
	title.offset_right = 520
	title.offset_bottom = 64
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	chrome.add_child(title)

	var rail := VBoxContainer.new()
	rail.name = "CategoryRail"
	rail.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	rail.offset_left = 28
	rail.offset_top = -140
	rail.offset_right = 210
	rail.offset_bottom = 180
	rail.add_theme_constant_override("separation", 8)
	chrome.add_child(rail)

	for category in CharacterRecordScript.CATEGORIES:
		var tab := Button.new()
		tab.name = "%sTab" % category.capitalize()
		tab.text = category.capitalize()
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_ALL
		tab.custom_minimum_size = Vector2(176, 40)
		_apply_tab_theme(tab)
		tab.pressed.connect(set_category.bind(category))
		rail.add_child(tab)
		_tab_buttons[category] = tab
		_focusables.append(tab)

	var panel := PanelContainer.new()
	panel.name = "CategoryPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -468
	panel.offset_top = -268
	panel.offset_right = -20
	panel.offset_bottom = 132
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.04, 0.08, 0.72)
	panel_style.border_color = Color(0.4, 0.72, 0.86, 0.45)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", panel_style)
	chrome.add_child(panel)

	var panel_col := VBoxContainer.new()
	panel_col.name = "Column"
	panel_col.add_theme_constant_override("separation", 10)
	panel.add_child(panel_col)

	_panel_body = Label.new()
	_panel_body.name = "Body"
	_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_body.add_theme_font_size_override("font_size", 15)
	_panel_body.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96, 0.95))
	panel_col.add_child(_panel_body)

	_race_grid = GridContainer.new()
	_race_grid.name = "RaceGrid"
	_race_grid.columns = 2
	_race_grid.add_theme_constant_override("h_separation", 8)
	_race_grid.add_theme_constant_override("v_separation", 8)
	var race_group := ButtonGroup.new()
	race_group.allow_unpress = false
	panel_col.add_child(_race_grid)
	for race_id in CharacterRecordScript.RACES:
		var card := Button.new()
		card.name = "%sRace" % race_id.capitalize()
		card.text = RacePresetsScript.label_for(race_id)
		card.toggle_mode = true
		card.button_group = race_group
		card.focus_mode = Control.FOCUS_ALL
		card.custom_minimum_size = Vector2(188, 88)
		card.clip_text = false
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var portrait := load(RacePresetsScript.card_path(race_id)) as Texture2D
		if portrait:
			card.icon = portrait
			card.expand_icon = true
			card.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			card.add_theme_constant_override("icon_max_width", 56)
		_apply_button_theme(card)
		card.add_theme_font_size_override("font_size", 13)
		card.pressed.connect(select_race.bind(race_id))
		_race_grid.add_child(card)
		_race_buttons[race_id] = card
		_focusables.append(card)

	_sex_label = Label.new()
	_sex_label.name = "SexLabel"
	_sex_label.text = "Underwear base"
	_sex_label.add_theme_font_size_override("font_size", 13)
	_sex_label.add_theme_color_override("font_color", Color(0.72, 0.8, 0.9, 0.9))
	panel_col.add_child(_sex_label)
	_sex_row = HBoxContainer.new()
	_sex_row.name = "SexRow"
	_sex_row.add_theme_constant_override("separation", 8)
	panel_col.add_child(_sex_row)
	var sex_group := ButtonGroup.new()
	sex_group.allow_unpress = false
	for sex_id in CharacterRecordScript.SEXES:
		var button := Button.new()
		button.name = "%sSex" % sex_id.capitalize()
		button.text = sex_id.capitalize()
		button.toggle_mode = true
		button.button_group = sex_group
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(188, 44)
		_apply_button_theme(button)
		button.pressed.connect(select_sex.bind(sex_id))
		_sex_row.add_child(button)
		_sex_buttons[sex_id] = button
		_focusables.append(button)

	var light_row := HBoxContainer.new()
	light_row.name = "Lighting"
	light_row.add_theme_constant_override("separation", 8)
	panel_col.add_child(light_row)
	var light_label := Label.new()
	light_label.text = "Preview light"
	light_label.add_theme_font_size_override("font_size", 13)
	light_label.add_theme_color_override("font_color", Color(0.72, 0.8, 0.9, 0.9))
	panel_col.add_child(light_label)
	panel_col.move_child(light_label, light_row.get_index())

	for preset in ["full", "dawn", "dusk"]:
		var button := Button.new()
		button.name = "%sLight" % preset.capitalize()
		button.text = preset.capitalize()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(108, 40)
		var icon := _load_knockout_scaled(str(LIGHT_ICONS[preset]), 22, 22)
		if icon:
			button.icon = icon
			button.expand_icon = false
		_apply_button_theme(button)
		button.pressed.connect(set_lighting.bind(preset))
		light_row.add_child(button)
		_light_buttons[preset] = button
		_focusables.append(button)

	var tools := VBoxContainer.new()
	tools.name = "Tools"
	tools.add_theme_constant_override("separation", 6)
	panel_col.add_child(tools)

	var reset_row := HBoxContainer.new()
	reset_row.name = "ResetRow"
	reset_row.add_theme_constant_override("separation", 8)
	tools.add_child(reset_row)
	_reset_all = _make_tool_button("ResetAll", "Reset All", ICON_RESET)
	_reset_all.pressed.connect(reset_all)
	reset_row.add_child(_reset_all)
	_reset_cat = _make_tool_button("ResetCategory", "Reset Category", ICON_RESET)
	_reset_cat.pressed.connect(reset_category)
	reset_row.add_child(_reset_cat)

	var random_row := HBoxContainer.new()
	random_row.name = "RandomRow"
	random_row.add_theme_constant_override("separation", 8)
	tools.add_child(random_row)
	_random_all = _make_tool_button("RandomizeAll", "Randomize All", ICON_RANDOM)
	_random_all.pressed.connect(randomize_all)
	random_row.add_child(_random_all)
	_random_cat = _make_tool_button("RandomizeCategory", "Randomize Category", ICON_RANDOM)
	_random_cat.pressed.connect(randomize_category)
	random_row.add_child(_random_cat)

	var footer := Control.new()
	footer.name = "Copy"
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 28
	footer.offset_top = -92
	footer.offset_right = -28
	footer.offset_bottom = -20
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(footer)

	var name_box := VBoxContainer.new()
	name_box.name = "NameBox"
	name_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	name_box.offset_left = 8
	name_box.offset_top = -64
	name_box.offset_right = 280
	name_box.offset_bottom = 0
	name_box.add_theme_constant_override("separation", 4)
	footer.add_child(name_box)
	var name_label := Label.new()
	name_label.text = "Name"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.72, 0.8, 0.9, 0.9))
	name_box.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.name = "NameEdit"
	_name_edit.placeholder_text = "Your name"
	_name_edit.custom_minimum_size = Vector2(240, 36)
	_name_edit.focus_mode = Control.FOCUS_ALL
	_name_edit.text_changed.connect(func(value: String) -> void:
		draft.display_name = value.strip_edges()
	)
	name_box.add_child(_name_edit)
	_focusables.append(_name_edit)

	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "Back"
	_back_button.focus_mode = Control.FOCUS_ALL
	_back_button.custom_minimum_size = Vector2(160, 44)
	_back_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_back_button.offset_left = 300
	_back_button.offset_top = -44
	_back_button.offset_right = 460
	_back_button.offset_bottom = 0
	var back_icon := _load_knockout_scaled(ICON_BACK, 22, 22)
	if back_icon:
		_back_button.icon = back_icon
	_apply_button_theme(_back_button)
	_back_button.pressed.connect(func() -> void:
		discard_draft()
		back_pressed.emit()
	)
	footer.add_child(_back_button)
	_focusables.append(_back_button)

	_confirm_button = Button.new()
	_confirm_button.name = "ConfirmButton"
	_confirm_button.text = "Confirm"
	_confirm_button.disabled = true
	_confirm_button.focus_mode = Control.FOCUS_ALL
	_confirm_button.custom_minimum_size = Vector2(180, 44)
	_confirm_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_confirm_button.offset_left = -200
	_confirm_button.offset_top = -44
	_confirm_button.offset_right = 0
	_confirm_button.offset_bottom = 0
	_confirm_button.tooltip_text = "Confirm writes the character in a later creator step."
	_apply_button_theme(_confirm_button)
	footer.add_child(_confirm_button)
	_focusables.append(_confirm_button)


func _build_wipe() -> void:
	_wipe = TextureRect.new()
	_wipe.name = "Wipe"
	_wipe.visible = false
	_wipe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wipe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wipe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(WIPE):
		_wipe.texture = load(WIPE)
	add_child(_wipe)


func _make_tool_button(node_name: String, label: String, icon_path: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(176, 40)
	var icon := _load_knockout_scaled(icon_path, 20, 20)
	if icon:
		button.icon = icon
		button.expand_icon = false
	_apply_button_theme(button)
	_focusables.append(button)
	return button


func _sync_light_buttons() -> void:
	var current := lighting_preset()
	for id in _light_buttons:
		var button := _light_buttons[id] as Button
		button.button_pressed = id == current


func _sync_action_labels() -> void:
	if _reset_cat:
		_reset_cat.text = "Reset %s" % _category.capitalize()
	if _random_cat:
		_random_cat.text = "Randomize %s" % _category.capitalize()


func _sync_race_buttons() -> void:
	var current := selected_race()
	for id in _race_buttons:
		var button := _race_buttons[id] as Button
		button.button_pressed = id == current


func _sync_sex_buttons() -> void:
	var current := selected_sex()
	for id in _sex_buttons:
		var button := _sex_buttons[id] as Button
		button.button_pressed = id == current


func _on_stage_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_stage_host.accept_event()
			return
	if _atelier and _atelier.has_method("handle_stage_input"):
		_atelier.handle_stage_input(event)


func _wire_focus() -> void:
	if _focusables.is_empty():
		return
	for i in _focusables.size():
		var control := _focusables[i]
		var prev := _focusables[i - 1 if i > 0 else _focusables.size() - 1]
		var next := _focusables[i + 1 if i + 1 < _focusables.size() else 0]
		control.focus_neighbor_top = control.get_path_to(prev)
		control.focus_neighbor_bottom = control.get_path_to(next)
		control.focus_previous = control.get_path_to(prev)
		control.focus_next = control.get_path_to(next)
		control.focus_neighbor_left = control.get_path_to(control)
		control.focus_neighbor_right = control.get_path_to(control)


func _ensure_styles() -> void:
	if btn_normal == null:
		btn_normal = _make_flat(Color(0.05, 0.07, 0.12, 0.88), Color(0.35, 0.62, 0.78, 0.55))
	if btn_hover == null:
		btn_hover = _make_flat(Color(0.08, 0.12, 0.2, 0.94), Color(0.72, 0.86, 1.0, 0.9))
	if btn_focus == null:
		btn_focus = _make_flat(Color(0.07, 0.1, 0.18, 0.95), Color(0.95, 0.82, 0.42, 1.0))
	var chrome := _load_knockout(BTN_CHROME)
	if chrome and btn_normal is StyleBoxFlat:
		btn_normal = _make_texture_style(chrome, Color(0.92, 0.95, 1.0, 0.92))
		btn_hover = _make_texture_style(chrome, Color(1, 1, 1, 1))


func _apply_button_theme(button: Button) -> void:
	if btn_normal:
		button.add_theme_stylebox_override("normal", btn_normal)
	if btn_hover:
		button.add_theme_stylebox_override("hover", btn_hover)
		button.add_theme_stylebox_override("pressed", btn_hover)
	if btn_focus:
		button.add_theme_stylebox_override("focus", btn_focus)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.72))
	button.add_theme_color_override("font_focus_color", Color(0.78, 0.94, 1.0))


func _apply_tab_theme(button: Button) -> void:
	_apply_button_theme(button)
	var tab := _load_knockout(TAB_CHROME)
	if tab:
		var normal := _make_texture_style(tab, Color(0.85, 0.9, 1.0, 0.9))
		var active := _make_texture_style(tab, Color(1, 1, 1, 1))
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", active)
		button.add_theme_stylebox_override("pressed", active)
		button.add_theme_stylebox_override("focus", active)


func _make_flat(fill: Color, rim: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = rim
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.set_content_margin_all(10)
	return box


func _make_texture_style(tex: Texture2D, tint: Color) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.modulate_color = tint
	box.set_texture_margin_all(36)
	box.set_content_margin_all(12)
	return box


func _ensure_input_map() -> void:
	_ensure_joy_axis("creator_orbit_left", JOY_AXIS_RIGHT_X, -1.0)
	_ensure_joy_axis("creator_orbit_right", JOY_AXIS_RIGHT_X, 1.0)
	_ensure_joy_axis("creator_orbit_up", JOY_AXIS_RIGHT_Y, -1.0)
	_ensure_joy_axis("creator_orbit_down", JOY_AXIS_RIGHT_Y, 1.0)
	_ensure_key("creator_orbit_left", KEY_Q)
	_ensure_key("creator_orbit_right", KEY_E)


func _ensure_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)


func _ensure_joy_axis(action: String, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			if motion.axis == axis and signf(motion.axis_value) == signf(axis_value):
				return
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	InputMap.action_add_event(action, ev)


func _load_knockout_scaled(path: String, max_w: int, max_h: int) -> Texture2D:
	var tex := _load_knockout(path)
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return tex
	if img.get_width() > max_w or img.get_height() > max_h:
		img.resize(max_w, max_h, Image.INTERPOLATE_LANCZOS)
		return ImageTexture.create_from_image(img)
	return tex


func _load_knockout(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return tex
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var color := img.get_pixel(x, y)
			var luma := color.r * 0.3 + color.g * 0.4 + color.b * 0.3
			if luma < 0.07:
				color.a = 0.0
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
