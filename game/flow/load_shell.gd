extends Control

## Title Load overlay. Empty state now; slot browser is DEF-004.
## Millbrook town saves are detected and refused (DEF-005).

signal back_pressed

const GameStateScript := preload("res://game/sim/game_state.gd")

const EMPTY_ART := "res://game/art/ui/load_empty.png"
const SLOT_FRAME := "res://game/art/ui/save_slot_frame.png"
const ICON_BACK := "res://game/art/ui/icon_back.png"
const EMPTY_TITLE := "No saves yet."
const EMPTY_DETAIL := "Begin with New when you are ready."
const UNSUPPORTED_TITLE := "This save isn't supported yet."
const UNSUPPORTED_DETAIL := "Living Town prototype saves cannot be continued here."
const UNSUPPORTED_SLOT := "Millbrook town save"
const SHEET_SIZE := Vector2(920, 560)

var btn_normal: StyleBox
var btn_hover: StyleBox
var btn_focus: StyleBox
var probe_path: String = GameStateScript.SAVE_PATH

var _built := false
var _back_button: Button
var _status: Label
var _detail: Label
var _empty_art: TextureRect
var _slot_row: Control
var _slot_label: Label
var _state := "empty"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	fill_parent()
	_build()
	refresh()


func fill_parent() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var dim := get_node_or_null("Dim") as Control
	if dim:
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var host := get_node_or_null("Center") as Control
	if host:
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func grab_default_focus() -> void:
	if _back_button:
		_back_button.call_deferred("grab_focus")


func probe_state() -> String:
	return _state


func status_text() -> String:
	return _status.text if _status else ""


func detail_text() -> String:
	return _detail.text if _detail else ""


func refresh() -> void:
	if not _built:
		_build()
	_state = "unsupported" if FileAccess.file_exists(probe_path) else "empty"
	if _state == "unsupported":
		print("Load: unsupported save at %s -- refused (DEF-005)." % probe_path)
		_status.text = UNSUPPORTED_TITLE
		_detail.text = UNSUPPORTED_DETAIL
		_empty_art.visible = false
		_slot_row.visible = true
		if _slot_label:
			_slot_label.text = UNSUPPORTED_SLOT
	else:
		_status.text = EMPTY_TITLE
		_detail.text = EMPTY_DETAIL
		_empty_art.visible = true
		_slot_row.visible = false
	var list := get_node_or_null("Center/Panel/Margin/Root/SlotList") as Control
	if list:
		list.visible = _state == "unsupported"


func _build() -> void:
	if _built:
		return
	_built = true

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.01, 0.02, 0.05, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var host := CenterContainer.new()
	host.name = "Center"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = SHEET_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.06, 0.11, 0.96)
	panel_style.border_color = Color(0.72, 0.86, 1.0, 0.75)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", panel_style)
	host.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	root.add_child(_make_header())

	_status = Label.new()
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 22)
	_status.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	root.add_child(_status)

	_detail = Label.new()
	_detail.name = "Detail"
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 15)
	_detail.add_theme_color_override("font_color", Color(0.78, 0.86, 0.95, 0.9))
	root.add_child(_detail)

	_empty_art = TextureRect.new()
	_empty_art.name = "EmptyArt"
	_empty_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_art.custom_minimum_size = Vector2(0, 280)
	_empty_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_empty_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_empty_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(EMPTY_ART):
		_empty_art.texture = load(EMPTY_ART)
	root.add_child(_empty_art)

	var list := VBoxContainer.new()
	list.name = "SlotList"
	list.visible = false
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	root.add_child(list)
	list.add_child(_make_slot_row())


func _make_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.name = "Title"
	title.text = "Load"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	header.add_child(title)

	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "Back"
	_back_button.focus_mode = Control.FOCUS_ALL
	_back_button.custom_minimum_size = Vector2(140, 44)
	var back_icon := _load_knockout_scaled(ICON_BACK, 22, 22)
	if back_icon:
		_back_button.icon = back_icon
		_back_button.expand_icon = false
		_back_button.add_theme_constant_override("icon_max_width", 28)
	_apply_button_theme(_back_button)
	_back_button.pressed.connect(func() -> void: back_pressed.emit())
	header.add_child(_back_button)
	_back_button.focus_neighbor_top = _back_button.get_path_to(_back_button)
	_back_button.focus_neighbor_bottom = _back_button.get_path_to(_back_button)
	_back_button.focus_neighbor_left = _back_button.get_path_to(_back_button)
	_back_button.focus_neighbor_right = _back_button.get_path_to(_back_button)
	return header


func _make_slot_row() -> Control:
	_slot_row = Control.new()
	_slot_row.name = "UnsupportedSlot"
	_slot_row.custom_minimum_size = Vector2(0, 120)
	_slot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(SLOT_FRAME):
		frame.texture = load(SLOT_FRAME)
	_slot_row.add_child(frame)

	_slot_label = Label.new()
	_slot_label.name = "SlotLabel"
	_slot_label.text = UNSUPPORTED_SLOT
	_slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slot_label.offset_left = 150
	_slot_label.offset_right = -28
	_slot_label.add_theme_font_size_override("font_size", 18)
	_slot_label.add_theme_color_override("font_color", Color(0.86, 0.9, 0.96, 0.85))
	_slot_row.add_child(_slot_label)
	return _slot_row


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
