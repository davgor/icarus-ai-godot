extends Control

## Title Settings overlay. Placeholders are not persisted (DEF-002 / DEF-003).

signal back_pressed

const SECTION_IDS: PackedStringArray = ["audio", "graphics", "controls"]
const SECTION_LABELS := {
	"audio": "Audio",
	"graphics": "Graphics",
	"controls": "Controls",
}
const SECTION_ICONS := {
	"audio": "res://game/art/ui/icon_audio.png",
	"graphics": "res://game/art/ui/icon_graphics.png",
	"controls": "res://game/art/ui/icon_controls.png",
}
const PANEL := "res://game/art/ui/settings_panel.png"
const ICON_BACK := "res://game/art/ui/icon_back.png"
const WIDGET_SLIDER := "res://game/art/ui/widget_slider.png"
const WIDGET_TOGGLE := "res://game/art/ui/widget_toggle.png"
const PLACEHOLDER_NOTICE := "Placeholders — changes are not saved yet."
const CONTROLS_BLURB := "Keyboard, mouse, and gamepad are supported.\nFull rebind is coming later.\n\nMove — WASD / Left stick\nConfirm — Enter / South face button\nCancel — Esc / East face button"
const SHEET_SIZE := Vector2(920, 580)
const FRAME_INSET_LEFT := 112
const FRAME_INSET_RIGHT := 196
const FRAME_INSET_TOP := 118
const FRAME_INSET_BOTTOM := 108
const SLIDER_END_PAD := 18

var btn_normal: StyleBox
var btn_hover: StyleBox
var btn_focus: StyleBox

var _current := "audio"
var _tabs: Dictionary = {}
var _pages: Dictionary = {}
var _back_button: Button
var _slider_style: StyleBox
var _grabber: Texture2D
var _toggle_on: Texture2D
var _toggle_off: Texture2D
var _built := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	fill_parent()
	_build()


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


func section_ids() -> PackedStringArray:
	return SECTION_IDS


func current_section() -> String:
	return _current


func placeholder_notice() -> String:
	return PLACEHOLDER_NOTICE


func controls_blurb() -> String:
	return CONTROLS_BLURB


func grab_default_focus() -> void:
	var tab: Button = _tabs.get(_current, _back_button)
	if tab:
		tab.call_deferred("grab_focus")


func show_section(id: String) -> void:
	if not SECTION_IDS.has(id):
		id = "audio"
	_current = id
	for key in _pages.keys():
		var page: Control = _pages[key]
		page.visible = str(key) == id
	for key in _tabs.keys():
		var tab: Button = _tabs[key]
		tab.button_pressed = str(key) == id
	_wire_page_focus()


func _build() -> void:
	if _built:
		return
	_built = true
	_grabber = _make_grabber()
	_slider_style = _make_slider_style()
	_toggle_on = _load_knockout_scaled(WIDGET_TOGGLE, 96, 40)
	_toggle_off = _dim_texture(_toggle_on)

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

	var panel := Control.new()
	panel.name = "Panel"
	panel.custom_minimum_size = SHEET_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(panel)

	var bg := TextureRect.new()
	bg.name = "Backdrop"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var frame_tex := _load_frame_backdrop(PANEL)
	if frame_tex:
		bg.texture = frame_tex
		var aspect := float(frame_tex.get_width()) / float(maxi(frame_tex.get_height(), 1))
		panel.custom_minimum_size = Vector2(SHEET_SIZE.x, SHEET_SIZE.x / aspect)
	panel.clip_contents = false
	panel.add_child(bg)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", FRAME_INSET_LEFT)
	margin.add_theme_constant_override("margin_top", FRAME_INSET_TOP)
	margin.add_theme_constant_override("margin_right", FRAME_INSET_RIGHT)
	margin.add_theme_constant_override("margin_bottom", FRAME_INSET_BOTTOM)
	margin.clip_contents = true
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	root.add_child(_make_header())

	var notice := Label.new()
	notice.name = "PlaceholderNotice"
	notice.text = PLACEHOLDER_NOTICE
	notice.add_theme_font_size_override("font_size", 14)
	notice.add_theme_color_override("font_color", Color(0.78, 0.86, 0.95, 0.85))
	root.add_child(notice)

	root.add_child(_make_tabs())

	var body := Control.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, 280)
	root.add_child(body)

	_pages["audio"] = _make_audio_page()
	_pages["graphics"] = _make_graphics_page()
	_pages["controls"] = _make_controls_page()
	for key in _pages.keys():
		var page: Control = _pages[key]
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		body.add_child(page)

	_wire_chrome_focus()
	show_section("audio")


func _make_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.name = "Title"
	title.text = "Settings"
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
	return header


func _make_tabs() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Sections"
	row.add_theme_constant_override("separation", 8)
	for id in SECTION_IDS:
		var tab := Button.new()
		tab.name = "%sTab" % str(SECTION_LABELS[id]).replace(" ", "")
		tab.text = str(SECTION_LABELS[id])
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_ALL
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size = Vector2(0, 44)
		tab.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var icon := _load_knockout_scaled(str(SECTION_ICONS[id]), 24, 24)
		if icon:
			tab.icon = icon
			tab.expand_icon = false
			tab.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			tab.add_theme_constant_override("icon_max_width", 24)
			tab.add_theme_constant_override("h_separation", 8)
		_apply_button_theme(tab)
		tab.pressed.connect(_on_tab_pressed.bind(id))
		row.add_child(tab)
		_tabs[id] = tab
	return row


func _make_audio_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "AudioPage"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 32)
	page.add_child(_make_slider_row("Master", 0.8))
	page.add_child(_make_slider_row("Music", 0.8))
	page.add_child(_make_slider_row("SFX", 0.8))
	return page


func _make_graphics_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "GraphicsPage"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 18)
	var hint := Label.new()
	hint.text = "Graphics presets are placeholders and do not change the editor or export."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96, 0.9))
	page.add_child(hint)
	page.add_child(_make_toggle_row("Fullscreen"))
	page.add_child(_make_toggle_row("VSync"))
	return page


func _make_controls_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "ControlsPage"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	var body := Label.new()
	body.name = "ControlsBlurb"
	body.text = CONTROLS_BLURB
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	page.add_child(body)
	return page


func _make_slider_row(label_text: String, value: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(96, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	row.add_child(label)
	var slider_host := MarginContainer.new()
	slider_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_host.add_theme_constant_override("margin_left", SLIDER_END_PAD)
	slider_host.add_theme_constant_override("margin_right", SLIDER_END_PAD)
	var slider := HSlider.new()
	slider.name = "%sSlider" % label_text
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(0, 22)
	slider.focus_mode = Control.FOCUS_ALL
	if _slider_style:
		slider.add_theme_stylebox_override("slider", _slider_style)
	if _grabber:
		slider.add_theme_icon_override("grabber", _grabber)
		slider.add_theme_icon_override("grabber_highlight", _grabber)
	slider_host.add_child(slider)
	row.add_child(slider_host)
	return row


func _make_toggle_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var button := CheckButton.new()
	button.name = "%sToggle" % label_text.replace(" ", "")
	button.text = label_text
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.72))
	button.add_theme_color_override("font_focus_color", Color(0.78, 0.94, 1.0))
	if _toggle_on:
		button.add_theme_icon_override("checked", _toggle_on)
		button.add_theme_icon_override("checked_mirrored", _toggle_on)
	if _toggle_off:
		button.add_theme_icon_override("unchecked", _toggle_off)
		button.add_theme_icon_override("unchecked_mirrored", _toggle_off)
	row.add_child(button)
	return row


func _on_tab_pressed(id: String) -> void:
	show_section(id)
	grab_default_focus()


func _wire_chrome_focus() -> void:
	if _back_button == null:
		return
	for i in SECTION_IDS.size():
		var tab: Button = _tabs[SECTION_IDS[i]]
		var prev: Button = _tabs[SECTION_IDS[i - 1 if i > 0 else SECTION_IDS.size() - 1]]
		var next: Button = _tabs[SECTION_IDS[i + 1 if i + 1 < SECTION_IDS.size() else 0]]
		tab.focus_neighbor_left = tab.get_path_to(prev)
		tab.focus_neighbor_right = tab.get_path_to(next)
		tab.focus_previous = tab.get_path_to(prev)
		tab.focus_next = tab.get_path_to(next)
		tab.focus_neighbor_top = tab.get_path_to(_back_button)
	_back_button.focus_neighbor_bottom = _back_button.get_path_to(_tabs["audio"])
	_back_button.focus_neighbor_left = _back_button.get_path_to(_tabs["controls"])


func _wire_page_focus() -> void:
	var tab: Button = _tabs.get(_current)
	var page: Control = _pages.get(_current)
	if tab == null or page == null:
		return
	var first := _first_focusable(page)
	if first:
		tab.focus_neighbor_bottom = tab.get_path_to(first)
		first.focus_neighbor_top = first.get_path_to(tab)
		_back_button.focus_neighbor_bottom = _back_button.get_path_to(tab)
	var focusables := _focusables(page)
	for i in focusables.size():
		var control := focusables[i]
		var prev_i := i - 1 if i > 0 else focusables.size() - 1
		var next_i := i + 1 if i + 1 < focusables.size() else 0
		var prev: Control = focusables[prev_i]
		var next: Control = focusables[next_i]
		control.focus_neighbor_top = control.get_path_to(tab if i == 0 else prev)
		control.focus_neighbor_bottom = control.get_path_to(next)
		control.focus_previous = control.get_path_to(prev)
		control.focus_next = control.get_path_to(next)


func _first_focusable(root: Node) -> Control:
	var found := _focusables(root)
	return found[0] if not found.is_empty() else null


func _focusables(root: Node) -> Array[Control]:
	var found: Array[Control] = []
	_collect_focusables(root, found)
	return found


func _collect_focusables(node: Node, found: Array[Control]) -> void:
	if node is Control:
		var control := node as Control
		if control.focus_mode != Control.FOCUS_NONE and (control is BaseButton or control is Range):
			found.append(control)
	for child in node.get_children():
		_collect_focusables(child, found)


func _make_slider_style() -> StyleBox:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.07, 0.1, 0.16, 0.95)
	track.border_color = Color(0.55, 0.78, 0.92, 0.75)
	track.set_border_width_all(1)
	track.set_corner_radius_all(8)
	track.content_margin_left = 14
	track.content_margin_right = 14
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	return track


func _make_grabber() -> ImageTexture:
	var img := Image.create(18, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 18:
		for x in 18:
			var diamond := absf(x - 8.5) + absf(y - 8.5)
			if diamond < 7.2:
				img.set_pixel(x, y, Color(0.95, 0.82, 0.42, 1.0))
			elif diamond < 8.6:
				img.set_pixel(x, y, Color(0.45, 0.86, 0.96, 0.95))
	return ImageTexture.create_from_image(img)


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


func _dim_texture(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return tex
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var color := img.get_pixel(x, y)
			color.r *= 0.45
			color.g *= 0.45
			color.b *= 0.45
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


func _load_frame_backdrop(path: String) -> Texture2D:
	var img: Image = null
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		img = Image.load_from_file(abs_path)
	if img == null and ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			img = tex.get_image()
	if img == null:
		return null
	img.convert(Image.FORMAT_RGBA8)
	_knockout_exterior_void(img)
	_erode_dark_fringe(img)
	_erode_dark_fringe(img)
	img = _crop_opaque(img, 0)
	return ImageTexture.create_from_image(img)


func _knockout_exterior_void(img: Image) -> void:
	var width := img.get_width()
	var height := img.get_height()
	if width <= 0 or height <= 0:
		return
	var metal := PackedByteArray()
	metal.resize(width * height)
	for y in height:
		for x in width:
			var sample: Color = img.get_pixel(x, y)
			if sample.a < 0.5:
				continue
			var luma: float = sample.r * 0.3 + sample.g * 0.4 + sample.b * 0.3
			if luma > 0.16:
				metal[y * width + x] = 1
	metal = _dilate_mask(metal, width, height, 3)
	var seen := PackedByteArray()
	seen.resize(width * height)
	var stack: Array[Vector2i] = []
	for x in width:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, height - 1))
	for y in height:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(width - 1, y))
	while not stack.is_empty():
		var point: Vector2i = stack.pop_back()
		if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height:
			continue
		var index := point.y * width + point.x
		if seen[index] == 1:
			continue
		seen[index] = 1
		if metal[index] == 1:
			continue
		img.set_pixel(point.x, point.y, Color(0, 0, 0, 0))
		stack.append(Vector2i(point.x + 1, point.y))
		stack.append(Vector2i(point.x - 1, point.y))
		stack.append(Vector2i(point.x, point.y + 1))
		stack.append(Vector2i(point.x, point.y - 1))


func _dilate_mask(src: PackedByteArray, width: int, height: int, steps: int) -> PackedByteArray:
	var cur := src
	for _step in steps:
		var nxt := PackedByteArray()
		nxt.resize(width * height)
		for y in height:
			for x in width:
				var index := y * width + x
				var hit := cur[index] == 1
				if not hit:
					for oy in range(-1, 2):
						for ox in range(-1, 2):
							var nx := x + ox
							var ny := y + oy
							if nx < 0 or ny < 0 or nx >= width or ny >= height:
								continue
							if cur[ny * width + nx] == 1:
								hit = true
								break
						if hit:
							break
				if hit:
					nxt[index] = 1
		cur = nxt
	return cur


func _erode_dark_fringe(img: Image) -> void:
	var width := img.get_width()
	var height := img.get_height()
	var copy := Image.new()
	copy.copy_from(img)
	for y in height:
		for x in width:
			var color: Color = copy.get_pixel(x, y)
			if color.a < 0.02:
				continue
			var luma: float = color.r * 0.3 + color.g * 0.4 + color.b * 0.3
			if luma > 0.12:
				continue
			if (
				_is_clear(copy, x - 1, y, width, height)
				or _is_clear(copy, x + 1, y, width, height)
				or _is_clear(copy, x, y - 1, width, height)
				or _is_clear(copy, x, y + 1, width, height)
			):
				color.a = 0.0
				img.set_pixel(x, y, color)


func _is_clear(img: Image, x: int, y: int, width: int, height: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return true
	return img.get_pixel(x, y).a < 0.02


func _crop_opaque(img: Image, pad: int) -> Image:
	var width := img.get_width()
	var height := img.get_height()
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1
	for y in height:
		for x in width:
			if img.get_pixel(x, y).a < 0.04:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x:
		return img
	min_x = maxi(min_x - pad, 0)
	min_y = maxi(min_y - pad, 0)
	max_x = mini(max_x + pad, width - 1)
	max_y = mini(max_y + pad, height - 1)
	return img.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))


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
