extends HBoxContainer

## On-screen Accept / Cancel / Navigate glyphs. Labels live in code, not in the art.

const GLYPH_A := "res://game/art/ui/glyph_a.png"
const GLYPH_B := "res://game/art/ui/glyph_b.png"
const GLYPH_DPAD := "res://game/art/ui/glyph_dpad.png"
const GLYPH_STICK := "res://game/art/ui/glyph_stick.png"
const ICON_SIZE := Vector2(28, 28)

var _cancel_slot: HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 18)
	alignment = BoxContainer.ALIGNMENT_END
	_build()


func configure(show_cancel: bool) -> void:
	if _cancel_slot:
		_cancel_slot.visible = show_cancel


func hint_labels() -> PackedStringArray:
	var labels := PackedStringArray(["Navigate", "Confirm"])
	if _cancel_slot and _cancel_slot.visible:
		labels.append("Back")
	return labels


func _build() -> void:
	add_child(_make_slot("Navigate", [GLYPH_DPAD, GLYPH_STICK]))
	add_child(_make_slot("Confirm", [GLYPH_A]))
	_cancel_slot = _make_slot("Back", [GLYPH_B])
	_cancel_slot.name = "CancelSlot"
	add_child(_cancel_slot)


func _make_slot(label_text: String, paths: PackedStringArray) -> HBoxContainer:
	var slot := HBoxContainer.new()
	slot.name = "%sSlot" % label_text
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_constant_override("separation", 6)
	for path in paths:
		var icon := TextureRect.new()
		icon.texture = _load_knockout(path)
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
	var label := Label.new()
	label.name = "Label"
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96, 0.92))
	slot.add_child(label)
	return slot


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
