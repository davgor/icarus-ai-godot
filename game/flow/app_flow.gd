extends CanvasLayer

## Boot splash → title owner. Millbrook stays parked until New/Load (or debug skip).
## Final boot/title audio: DEF-001.
## Settings persistence / rebind: DEF-002 / DEF-003.
## Load slot browser / Millbrook migration: DEF-004 / DEF-005.
## Creator stub art retirement: DEF-006. Draft save: DEF-007.

const SettingsShellScript := preload("res://game/flow/settings_shell.gd")
const LoadShellScript := preload("res://game/flow/load_shell.gd")
const CreatorStubScript := preload("res://game/flow/creator_stub.gd")

signal world_requested
signal quit_requested

enum Screen { NONE, BOOT, TITLE, CREATOR, SETTINGS, LOAD }

const ACTION_LABELS: PackedStringArray = ["New", "Load", "Settings", "Quit"]
const BOOT_SECONDS := 1.35
const DEBUG_SKIP_KEY := KEY_F10

const BOOT_SPLASH := "res://game/art/ui/boot_splash.png"
const TITLE_BG := "res://game/art/ui/title_bg.png"
const LOGO := "res://game/art/ui/logo_icarus.png"
const SPINNER := "res://game/art/ui/loading_spinner.png"
const BTN_CHROME := "res://game/art/ui/btn_primary.png"

var current_screen: Screen = Screen.NONE

var _built := false
var _boot: Control
var _title: Control
var _creator: Control
var _settings: Control
var _load: Control
var _spinner: TextureRect
var _action_buttons: Array[Button] = []
var _new_button: Button
var _load_button: Button
var _settings_button: Button
var _btn_normal: StyleBox
var _btn_hover: StyleBox
var _btn_focus: StyleBox


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		visible = false
		current_screen = Screen.NONE
		return
	ensure_ui()
	show_boot()


func _process(delta: float) -> void:
	if _spinner and _spinner.visible:
		_spinner.rotation += delta * 2.4


func _unhandled_input(event: InputEvent) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == DEBUG_SKIP_KEY:
			request_debug_world()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel") and current_screen in [Screen.CREATOR, Screen.SETTINGS, Screen.LOAD]:
		show_title()
		get_viewport().set_input_as_handled()


func ensure_ui() -> void:
	if _built:
		return
	_built = true
	_build_styles()
	_build_boot()
	_build_title()
	_build_settings()
	_build_load()
	_build_creator()
	visible = true


func screen_name() -> String:
	match current_screen:
		Screen.BOOT:
			return "boot"
		Screen.TITLE:
			return "title"
		Screen.CREATOR:
			return "creator"
		Screen.SETTINGS:
			return "settings"
		Screen.LOAD:
			return "load"
		_:
			return "none"


func title_button_texts() -> PackedStringArray:
	ensure_ui()
	var texts := PackedStringArray()
	for button in _action_buttons:
		texts.append(button.text)
	return texts


func show_boot() -> void:
	ensure_ui()
	current_screen = Screen.BOOT
	visible = true
	_boot.visible = true
	_title.visible = false
	if _creator:
		_creator.visible = false
	if _settings:
		_settings.visible = false
	if _load:
		_load.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tree := get_tree()
	if tree:
		var timer := tree.create_timer(BOOT_SECONDS)
		timer.timeout.connect(_on_boot_finished)


func show_title() -> void:
	ensure_ui()
	var restore_settings := current_screen == Screen.SETTINGS
	var restore_load := current_screen == Screen.LOAD
	var restore_creator := current_screen == Screen.CREATOR
	current_screen = Screen.TITLE
	visible = true
	_boot.visible = false
	_title.visible = true
	if _creator:
		_creator.visible = false
	if _settings:
		_settings.visible = false
	if _load:
		_load.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_menu_enabled(true)
	var focus_btn := _new_button
	if restore_settings and _settings_button:
		focus_btn = _settings_button
	elif restore_load and _load_button:
		focus_btn = _load_button
	elif restore_creator and _new_button:
		focus_btn = _new_button
	if focus_btn:
		focus_btn.call_deferred("grab_focus")


func show_creator() -> void:
	ensure_ui()
	current_screen = Screen.CREATOR
	visible = true
	_boot.visible = false
	_title.visible = false
	if _settings:
		_settings.visible = false
	if _load:
		_load.visible = false
	_creator.visible = true
	if _creator.has_method("fill_parent"):
		_creator.fill_parent()
	_set_menu_enabled(false)
	if _creator.has_method("play_enter"):
		_creator.play_enter()
	if _creator.has_method("grab_default_focus"):
		_creator.grab_default_focus()


func creator_headline() -> String:
	ensure_ui()
	if _creator and _creator.has_method("headline"):
		return str(_creator.headline())
	return ""


func creator_body() -> String:
	ensure_ui()
	if _creator and _creator.has_method("body_copy"):
		return str(_creator.body_copy())
	return ""


func show_settings() -> void:
	ensure_ui()
	current_screen = Screen.SETTINGS
	visible = true
	_boot.visible = false
	_title.visible = true
	if _creator:
		_creator.visible = false
	if _load:
		_load.visible = false
	_settings.visible = true
	if _settings.has_method("fill_parent"):
		_settings.fill_parent()
	_set_menu_enabled(false)
	if _settings.has_method("show_section"):
		_settings.show_section("audio")
	if _settings.has_method("grab_default_focus"):
		_settings.grab_default_focus()


func settings_section_ids() -> PackedStringArray:
	ensure_ui()
	if _settings and _settings.has_method("section_ids"):
		return _settings.section_ids()
	return PackedStringArray()


func settings_current_section() -> String:
	if _settings and _settings.has_method("current_section"):
		return str(_settings.current_section())
	return ""


func show_settings_section(id: String) -> void:
	ensure_ui()
	show_settings()
	if _settings and _settings.has_method("show_section"):
		_settings.show_section(id)


func settings_placeholder_notice() -> String:
	ensure_ui()
	if _settings and _settings.has_method("placeholder_notice"):
		return str(_settings.placeholder_notice())
	return ""


func settings_controls_blurb() -> String:
	ensure_ui()
	if _settings and _settings.has_method("controls_blurb"):
		return str(_settings.controls_blurb())
	return ""


func show_load() -> void:
	ensure_ui()
	current_screen = Screen.LOAD
	visible = true
	_boot.visible = false
	_title.visible = true
	if _creator:
		_creator.visible = false
	if _settings:
		_settings.visible = false
	_load.visible = true
	if _load.has_method("fill_parent"):
		_load.fill_parent()
	if _load.has_method("refresh"):
		_load.refresh()
	_set_menu_enabled(false)
	if _load.has_method("grab_default_focus"):
		_load.grab_default_focus()


func load_state() -> String:
	ensure_ui()
	if _load and _load.has_method("probe_state"):
		return str(_load.probe_state())
	return ""


func load_message() -> String:
	ensure_ui()
	if _load and _load.has_method("status_text"):
		return str(_load.status_text())
	return ""


func load_detail() -> String:
	ensure_ui()
	if _load and _load.has_method("detail_text"):
		return str(_load.detail_text())
	return ""


func set_load_probe_path(path: String) -> void:
	ensure_ui()
	if _load:
		_load.probe_path = path
		if _load.has_method("refresh"):
			_load.refresh()


func hide_flow() -> void:
	current_screen = Screen.NONE
	visible = false
	if _boot:
		_boot.visible = false
	if _title:
		_title.visible = false
	if _creator:
		_creator.visible = false
	if _settings:
		_settings.visible = false
	if _load:
		_load.visible = false


func request_quit() -> void:
	quit_requested.emit()
	var tree := get_tree()
	if tree:
		tree.quit()


func request_debug_world() -> void:
	hide_flow()
	world_requested.emit()


func _set_menu_enabled(enabled: bool) -> void:
	for button in _action_buttons:
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _on_boot_finished() -> void:
	if current_screen != Screen.BOOT:
		return
	show_title()


func _build_styles() -> void:
	_btn_normal = _make_button_style(Color(0.05, 0.07, 0.12, 0.88), Color(0.35, 0.62, 0.78, 0.55))
	_btn_hover = _make_button_style(Color(0.08, 0.12, 0.2, 0.94), Color(0.72, 0.86, 1.0, 0.9))
	_btn_focus = _make_button_style(Color(0.07, 0.1, 0.18, 0.95), Color(0.95, 0.82, 0.42, 1.0))
	var chrome := _load_knockout(BTN_CHROME)
	if chrome:
		_btn_normal = _make_texture_style(chrome, Color(0.92, 0.95, 1.0, 0.92))
		_btn_hover = _make_texture_style(chrome, Color(1, 1, 1, 1))


func _make_button_style(fill: Color, rim: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = rim
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.set_content_margin_all(12)
	box.shadow_color = Color(0.2, 0.7, 1.0, 0.12)
	box.shadow_size = 6
	return box


func _make_texture_style(tex: Texture2D, modulate: Color) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.modulate_color = modulate
	box.set_texture_margin_all(32)
	box.set_content_margin_all(14)
	return box


func _build_boot() -> void:
	_boot = Control.new()
	_boot.name = "BootScreen"
	_boot.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boot.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_boot)

	_boot.add_child(_make_backdrop(BOOT_SPLASH, Color(0.03, 0.04, 0.08, 1.0)))

	var logo := _make_logo(Vector2(520, 180))
	logo.set_anchors_preset(Control.PRESET_CENTER)
	logo.offset_left = -260
	logo.offset_top = -160
	logo.offset_right = 260
	logo.offset_bottom = 20
	_boot.add_child(logo)

	_spinner = TextureRect.new()
	_spinner.name = "Spinner"
	_spinner.texture = _load_knockout(SPINNER)
	_spinner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_spinner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_spinner.pivot_offset = Vector2(36, 36)
	_spinner.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_spinner.offset_left = -36
	_spinner.offset_top = -120
	_spinner.offset_right = 36
	_spinner.offset_bottom = -48
	_boot.add_child(_spinner)

	var status := Label.new()
	status.name = "Status"
	status.text = "Loading"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	status.offset_left = -120
	status.offset_top = -44
	status.offset_right = 120
	status.offset_bottom = -16
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", Color(0.78, 0.86, 0.95, 0.9))
	_boot.add_child(status)


func _build_title() -> void:
	_title = Control.new()
	_title.name = "TitleScreen"
	_title.visible = false
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_title)

	_title.add_child(_make_backdrop(TITLE_BG, Color(0.02, 0.03, 0.07, 1.0)))

	var logo := _make_logo(Vector2(640, 220))
	logo.set_anchors_preset(Control.PRESET_TOP_LEFT)
	logo.offset_left = 48
	logo.offset_top = 36
	logo.offset_right = 688
	logo.offset_bottom = 256
	_title.add_child(logo)

	var menu := VBoxContainer.new()
	menu.name = "Menu"
	menu.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	menu.offset_left = 64
	menu.offset_top = -320
	menu.offset_right = 360
	menu.offset_bottom = -72
	menu.add_theme_constant_override("separation", 10)
	_title.add_child(menu)

	_action_buttons.clear()
	for label in ACTION_LABELS:
		var button := Button.new()
		button.name = "%sButton" % label
		button.text = label
		button.custom_minimum_size = Vector2(280, 48)
		button.focus_mode = Control.FOCUS_ALL
		_apply_button_theme(button)
		button.pressed.connect(_on_action_pressed.bind(label))
		menu.add_child(button)
		_action_buttons.append(button)
		if label == "New":
			_new_button = button
		elif label == "Load":
			_load_button = button
		elif label == "Settings":
			_settings_button = button

	for i in _action_buttons.size():
		var button := _action_buttons[i]
		var prev := _action_buttons[i - 1 if i > 0 else _action_buttons.size() - 1]
		var next := _action_buttons[i + 1 if i + 1 < _action_buttons.size() else 0]
		button.focus_neighbor_top = button.get_path_to(prev)
		button.focus_neighbor_bottom = button.get_path_to(next)
		button.focus_previous = button.get_path_to(prev)
		button.focus_next = button.get_path_to(next)


func _build_settings() -> void:
	_settings = SettingsShellScript.new()
	_settings.name = "SettingsOverlay"
	_settings.btn_normal = _btn_normal
	_settings.btn_hover = _btn_hover
	_settings.btn_focus = _btn_focus
	_title.add_child(_settings)
	if _settings.has_method("fill_parent"):
		_settings.fill_parent()
	_settings.back_pressed.connect(show_title)


func _build_load() -> void:
	_load = LoadShellScript.new()
	_load.name = "LoadOverlay"
	_load.btn_normal = _btn_normal
	_load.btn_hover = _btn_hover
	_load.btn_focus = _btn_focus
	_title.add_child(_load)
	if _load.has_method("fill_parent"):
		_load.fill_parent()
	_load.back_pressed.connect(show_title)


func _build_creator() -> void:
	_creator = CreatorStubScript.new()
	_creator.name = "CreatorScreen"
	_creator.btn_normal = _btn_normal
	_creator.btn_hover = _btn_hover
	_creator.btn_focus = _btn_focus
	add_child(_creator)
	if _creator.has_method("fill_parent"):
		_creator.fill_parent()
	_creator.back_pressed.connect(show_title)


func _on_action_pressed(action: String) -> void:
	match action:
		"Quit":
			request_quit()
		"Settings":
			show_settings()
		"Load":
			show_load()
		"New":
			show_creator()


func _apply_button_theme(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _btn_normal)
	button.add_theme_stylebox_override("hover", _btn_hover)
	button.add_theme_stylebox_override("pressed", _btn_hover)
	button.add_theme_stylebox_override("focus", _btn_focus)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.72))
	button.add_theme_color_override("font_focus_color", Color(0.78, 0.94, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.78, 0.94, 1.0))


func _make_backdrop(path: String, fallback: Color) -> TextureRect:
	var backdrop := TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(path):
		backdrop.texture = load(path)
	else:
		backdrop.modulate = fallback
	return backdrop


func _make_logo(size: Vector2) -> TextureRect:
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = _load_knockout(LOGO)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = size
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return logo


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
