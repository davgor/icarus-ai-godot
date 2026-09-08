extends CanvasLayer

## Boot splash → title owner. Millbrook stays parked until New/Load (or debug skip).
## Final boot/title audio: DEF-001.
## Settings persistence / rebind: DEF-002 / DEF-003.
## Load slot browser / Millbrook migration: DEF-004 / DEF-005.
## Creator stub art retirement: DEF-006. Draft save: DEF-007.
## OS-6 pad path: glyphs + focus ring; full rebind stays DEF-003.

const SettingsShellScript := preload("res://game/flow/settings_shell.gd")
const LoadShellScript := preload("res://game/flow/load_shell.gd")
const CreatorStubScript := preload("res://game/flow/creator_stub.gd")
const PromptBarScript := preload("res://game/flow/prompt_bar.gd")

signal world_requested
signal quit_requested

enum Screen { NONE, BOOT, TITLE, CREATOR, SETTINGS, LOAD }

const ACTION_LABELS: PackedStringArray = ["New", "Load", "Settings", "Quit"]
const UI_MENU_ACTIONS: PackedStringArray = [
	"ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"
]
const BOOT_SECONDS := 1.35
const DEBUG_SKIP_KEY := KEY_F10
const FOCUS_RING_PAD := 10.0

const BOOT_SPLASH := "res://game/art/ui/boot_splash.png"
const TITLE_BG := "res://game/art/ui/title_bg.png"
const LOGO := "res://game/art/ui/logo_icarus.png"
const SPINNER := "res://game/art/ui/loading_spinner.png"
const BTN_CHROME := "res://game/art/ui/btn_primary.png"
const FOCUS_RING := "res://game/art/ui/focus_ring.png"

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
var _prompt_bar: Control
var _focus_ring: TextureRect
var _focus_connected := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_ui_input_map()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	if DisplayServer.get_name() == "headless":
		visible = false
		current_screen = Screen.NONE
		return
	ensure_ui()
	show_boot()


func _process(delta: float) -> void:
	if _spinner and _spinner.visible:
		_spinner.rotation += delta * 2.4
	_update_focus_ring()
	if _gamepad_connected():
		_restore_flow_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == DEBUG_SKIP_KEY:
			if DisplayServer.get_name() != "headless":
				request_debug_world()
				get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		if try_cancel():
			get_viewport().set_input_as_handled()
			return
	if _is_menu_nav(event):
		_restore_flow_focus()


func ensure_ui() -> void:
	if _built:
		return
	_built = true
	_ensure_ui_input_map()
	_build_styles()
	_build_boot()
	_build_title()
	_build_settings()
	_build_load()
	_build_creator()
	_build_focus_ring()
	_build_prompt_bar()
	_connect_focus_signal()
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
	_sync_chrome(false)
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
	_sync_chrome(false)
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
	_sync_chrome(true)


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
	_sync_chrome(true)


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
	_sync_chrome(true)


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
	_sync_chrome(false)


func try_cancel() -> bool:
	if current_screen in [Screen.CREATOR, Screen.SETTINGS, Screen.LOAD]:
		show_title()
		return true
	return false


func ui_menu_actions() -> PackedStringArray:
	_ensure_ui_input_map()
	return UI_MENU_ACTIONS


func action_has_keyboard(action: String) -> bool:
	_ensure_ui_input_map()
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return true
	return false


func action_has_joypad(action: String) -> bool:
	_ensure_ui_input_map()
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func title_focus_loop_ok() -> bool:
	ensure_ui()
	if _action_buttons.size() != ACTION_LABELS.size():
		return false
	for button in _action_buttons:
		if str(button.focus_neighbor_top).is_empty() or str(button.focus_neighbor_bottom).is_empty():
			return false
		if button.focus_mode == Control.FOCUS_NONE:
			return false
	return true


func prompt_hint_labels() -> PackedStringArray:
	ensure_ui()
	if _prompt_bar and _prompt_bar.has_method("hint_labels"):
		return _prompt_bar.hint_labels()
	return PackedStringArray()


func prompt_bar_visible() -> bool:
	return _prompt_bar != null and _prompt_bar.visible


func glyph_paths_exist() -> bool:
	return (
		ResourceLoader.exists("res://game/art/ui/glyph_a.png")
		and ResourceLoader.exists("res://game/art/ui/glyph_b.png")
		and ResourceLoader.exists("res://game/art/ui/glyph_dpad.png")
		and ResourceLoader.exists("res://game/art/ui/glyph_stick.png")
		and ResourceLoader.exists(FOCUS_RING)
	)


func focus_ring_visible() -> bool:
	return _focus_ring != null and _focus_ring.visible


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
	var ring := _load_knockout(FOCUS_RING)
	if ring:
		var ring_style := _make_texture_style(ring, Color(1, 1, 1, 1))
		ring_style.set_texture_margin_all(48)
		ring_style.set_content_margin_all(16)
		_btn_focus = ring_style


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
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
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


func _build_focus_ring() -> void:
	_focus_ring = TextureRect.new()
	_focus_ring.name = "FocusRing"
	_focus_ring.visible = false
	_focus_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_ring.texture = _load_knockout(FOCUS_RING)
	_focus_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_focus_ring.stretch_mode = TextureRect.STRETCH_SCALE
	_focus_ring.z_index = 20
	add_child(_focus_ring)


func _build_prompt_bar() -> void:
	_prompt_bar = PromptBarScript.new()
	_prompt_bar.name = "PromptBar"
	_prompt_bar.visible = false
	_prompt_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_prompt_bar.offset_left = -560
	_prompt_bar.offset_top = -56
	_prompt_bar.offset_right = -28
	_prompt_bar.offset_bottom = -16
	_prompt_bar.z_index = 21
	add_child(_prompt_bar)


func _sync_chrome(show_cancel: bool) -> void:
	if _prompt_bar:
		var show_bar := current_screen in [Screen.TITLE, Screen.CREATOR, Screen.SETTINGS, Screen.LOAD]
		_prompt_bar.visible = show_bar
		if _prompt_bar.has_method("configure"):
			_prompt_bar.configure(show_cancel)
	if _focus_ring and not show_cancel and current_screen in [Screen.NONE, Screen.BOOT]:
		_focus_ring.visible = false
	_update_focus_ring()


func _connect_focus_signal() -> void:
	if _focus_connected:
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	if not viewport.gui_focus_changed.is_connected(_on_gui_focus_changed):
		viewport.gui_focus_changed.connect(_on_gui_focus_changed)
	_focus_connected = true


func _on_gui_focus_changed(_control: Control) -> void:
	_update_focus_ring()


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if connected:
		_restore_flow_focus()


func _gamepad_connected() -> bool:
	return not Input.get_connected_joypads().is_empty()


func _is_menu_nav(event: InputEvent) -> bool:
	return (
		event.is_action_pressed("ui_up")
		or event.is_action_pressed("ui_down")
		or event.is_action_pressed("ui_left")
		or event.is_action_pressed("ui_right")
		or event.is_action_pressed("ui_accept")
		or event.is_action_pressed("ui_focus_next")
		or event.is_action_pressed("ui_focus_prev")
	)


func _restore_flow_focus() -> void:
	if current_screen in [Screen.NONE, Screen.BOOT]:
		return
	var focused := get_viewport().gui_get_focus_owner() if get_viewport() else null
	if focused and _is_flow_control(focused):
		return
	match current_screen:
		Screen.TITLE:
			if _new_button:
				_new_button.grab_focus()
		Screen.SETTINGS:
			if _settings and _settings.has_method("grab_default_focus"):
				_settings.grab_default_focus()
		Screen.LOAD:
			if _load and _load.has_method("grab_default_focus"):
				_load.grab_default_focus()
		Screen.CREATOR:
			if _creator and _creator.has_method("grab_default_focus"):
				_creator.grab_default_focus()


func _is_flow_control(control: Control) -> bool:
	var node: Node = control
	while node:
		if node == self:
			return true
		node = node.get_parent()
	return false


func _update_focus_ring() -> void:
	if _focus_ring == null:
		return
	if current_screen in [Screen.NONE, Screen.BOOT] or not visible:
		_focus_ring.visible = false
		return
	var viewport := get_viewport()
	var focused := viewport.gui_get_focus_owner() if viewport else null
	if focused == null or not focused.visible or not _is_flow_control(focused):
		_focus_ring.visible = false
		return
	var rect := focused.get_global_rect()
	_focus_ring.visible = true
	_focus_ring.global_position = rect.position - Vector2(FOCUS_RING_PAD, FOCUS_RING_PAD)
	_focus_ring.size = rect.size + Vector2(FOCUS_RING_PAD, FOCUS_RING_PAD) * 2.0


func _ensure_ui_input_map() -> void:
	_ensure_key("ui_accept", KEY_ENTER)
	_ensure_key("ui_accept", KEY_KP_ENTER)
	_ensure_key("ui_accept", KEY_SPACE)
	_ensure_joy_button("ui_accept", JOY_BUTTON_A)
	_ensure_key("ui_cancel", KEY_ESCAPE)
	_ensure_joy_button("ui_cancel", JOY_BUTTON_B)
	_ensure_key("ui_up", KEY_UP)
	_ensure_key("ui_down", KEY_DOWN)
	_ensure_key("ui_left", KEY_LEFT)
	_ensure_key("ui_right", KEY_RIGHT)
	_ensure_joy_button("ui_up", JOY_BUTTON_DPAD_UP)
	_ensure_joy_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	_ensure_joy_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_ensure_joy_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_ensure_joy_axis("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_joy_axis("ui_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_joy_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_joy_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0)


func _ensure_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)


func _ensure_joy_button(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
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
