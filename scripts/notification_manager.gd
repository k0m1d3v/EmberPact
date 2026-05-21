extends CanvasLayer

var _lbl: Label
var _tween: Tween = null

func _ready():
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS
	_lbl = Label.new()
	_lbl.add_theme_font_size_override("font_size", 11)
	_lbl.add_theme_color_override("font_color", Color("#F5E6C8"))
	_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl.anchor_left = 0.0
	_lbl.anchor_right = 1.0
	_lbl.anchor_top = 0.0
	_lbl.anchor_bottom = 0.0
	_lbl.offset_top = 36
	_lbl.offset_bottom = 56
	_lbl.modulate.a = 0.0
	add_child(_lbl)

func notify(text: String):
	_lbl.text = text
	if _tween:
		_tween.kill()
	_lbl.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(1.8)
	_tween.tween_property(_lbl, "modulate:a", 0.0, 0.4)
