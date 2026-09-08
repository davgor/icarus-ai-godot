extends Control

## Dedicated New destination until pack 02 replaces the body (DEF-006).
## Back discards; no draft save (DEF-007). Debug skip stays F10 on AppFlow.

signal back_pressed

const BACKDROP := "res://game/art/ui/creator_stub_bg.png"
const WIPE := "res://game/art/vfx/title_to_creator_wipe.png"
const ICON_BACK := "res://game/art/ui/icon_back.png"
const HEADLINE := "Character Creation"
const BODY_COPY := "This is the creator. Race, body, face, and outfit land here next — not a name field and not the town."
const HINT_COPY := "Back returns to title. Customization is required before the hub."

var btn_normal: StyleBox
var btn_hover: StyleBox
var btn_focus: StyleBox

var _built := false
var _back_button: Button
var _wipe: TextureRect
var _wipe_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	fill_parent()
	_build()


func fill_parent() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for child_name in ["Backdrop", "Scrim", "Chrome", "Wipe"]:
		var child := get_node_or_null(child_name) as Control
		if child:
			child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func headline() -> String:
	return HEADLINE


func body_copy() -> String:
	return BODY_COPY


func grab_default_focus() -> void:
	if _back_button:
		_back_button.call_deferred("grab_focus")


func play_enter() -> void:
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
	_wipe_tween.finished.connect(_on_wipe_finished)


func _on_wipe_finished() -> void:
	if _wipe:
		_wipe.visible = false


func _build() -> void:
	if _built:
		return
	_built = true

	var backdrop := TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(BACKDROP):
		backdrop.texture = load(BACKDROP)
	else:
		backdrop.modulate = Color(0.04, 0.05, 0.09, 1.0)
	add_child(backdrop)

	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = Color(0.01, 0.02, 0.05, 0.28)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	var chrome := Control.new()
	chrome.name = "Chrome"
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chrome)

	var column := VBoxContainer.new()
	column.name = "Copy"
	column.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	column.offset_left = 64
	column.offset_top = -280
	column.offset_right = 560
	column.offset_bottom = -72
	column.add_theme_constant_override("separation", 14)
	chrome.add_child(column)

	var title := Label.new()
	title.name = "Headline"
	title.text = HEADLINE
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	column.add_child(title)

	var body := Label.new()
	body.name = "Body"
	body.text = BODY_COPY
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96, 0.95))
	column.add_child(body)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = HINT_COPY
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.72, 0.8, 0.9, 0.85))
	column.add_child(hint)

	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "Back"
	_back_button.focus_mode = Control.FOCUS_ALL
	_back_button.custom_minimum_size = Vector2(180, 48)
	var back_icon := _load_knockout_scaled(ICON_BACK, 22, 22)
	if back_icon:
		_back_button.icon = back_icon
		_back_button.expand_icon = false
		_back_button.add_theme_constant_override("icon_max_width", 28)
	_apply_button_theme(_back_button)
	_back_button.pressed.connect(func() -> void: back_pressed.emit())
	column.add_child(_back_button)
	_back_button.focus_neighbor_top = _back_button.get_path_to(_back_button)
	_back_button.focus_neighbor_bottom = _back_button.get_path_to(_back_button)
	_back_button.focus_neighbor_left = _back_button.get_path_to(_back_button)
	_back_button.focus_neighbor_right = _back_button.get_path_to(_back_button)

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


func _apply_button_theme(button: Button) -> void:
	if btn_normal:
		button.add_theme_stylebox_override("normal", btn_normal)
	if btn_hover:
		button.add_theme_stylebox_override("hover", btn_hover)
		button.add_theme_stylebox_override("pressed", btn_hover)
	if btn_focus:
		button.add_theme_stylebox_override("focus", btn_focus)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.72))
	button.add_theme_color_override("font_focus_color", Color(0.78, 0.94, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.78, 0.94, 1.0))


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
	var img: Image = null
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			img = tex.get_image()
	if img == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			img = Image.load_from_file(abs_path)
	if img == null:
		return null
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var color := img.get_pixel(x, y)
			var luma := color.r * 0.3 + color.g * 0.4 + color.b * 0.3
			if luma < 0.07:
				color.a = 0.0
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
