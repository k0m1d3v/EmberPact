extends Node2D

var npc_name: String = "NPC"
var dialogues: Array = []
var action_label: String = ""
var action_cb: Callable = Callable()
var pre_interact_cb: Callable = Callable()
var sprite_color: Color = Color("#6B4F3A")

var _in_range: bool = false
var _dial_idx: int = 0
var _is_open: bool = false
var _player_ref: Node = null

var _canvas: CanvasLayer = null
var _text_lbl: Label = null
var _name_lbl: Label = null
var _next_btn: Button = null
var _action_btn: Button = null

const RANGE := 28.0

func _ready():
	var cr = ColorRect.new()
	cr.color = sprite_color
	cr.offset_left = -8.0
	cr.offset_top = -8.0
	cr.offset_right = 8.0
	cr.offset_bottom = 8.0
	add_child(cr)

	var head_lbl = Label.new()
	head_lbl.text = npc_name
	head_lbl.add_theme_font_size_override("font_size", 7)
	head_lbl.add_theme_color_override("font_color", Color("#F5E6C8"))
	head_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head_lbl.position = Vector2(-24, -22)
	head_lbl.custom_minimum_size = Vector2(48, 10)
	add_child(head_lbl)

	_build_dialogue_ui()
	call_deferred("_init_area")

func _init_area():
	var sc = get_tree().current_scene
	if not sc:
		return
	_player_ref = sc.get_node_or_null("Player")
	if not _player_ref:
		return

	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = RANGE
	col.shape = circle
	area.add_child(col)
	area.monitoring = true
	area.monitorable = false
	add_child(area)
	area.body_entered.connect(_on_body_in)
	area.body_exited.connect(_on_body_out)

func _on_body_in(body: Node):
	if body == _player_ref:
		_in_range = true
		if "npc_near" in body:
			body.npc_near = self

func _on_body_out(body: Node):
	if body == _player_ref:
		_in_range = false
		if "npc_near" in body and body.npc_near == self:
			body.npc_near = null

func _build_dialogue_ui():
	_canvas = CanvasLayer.new()
	_canvas.layer = 6
	add_child(_canvas)

	var panel = NinePatchRect.new()
	panel.texture = load("res://assets/ui/panel_inventory_9p.png")
	panel.patch_margin_left = 6
	panel.patch_margin_right = 6
	panel.patch_margin_top = 6
	panel.patch_margin_bottom = 6
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -90
	panel.offset_bottom = -4
	panel.offset_left = 8
	panel.offset_right = -8
	_canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 10)
	_name_lbl.add_theme_color_override("font_color", Color("#C8A96E"))
	vbox.add_child(_name_lbl)

	_text_lbl = Label.new()
	_text_lbl.add_theme_font_size_override("font_size", 9)
	_text_lbl.add_theme_color_override("font_color", Color("#F5E6C8"))
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text_lbl)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 4)
	vbox.add_child(btn_row)

	_action_btn = Button.new()
	_action_btn.add_theme_font_size_override("font_size", 9)
	_action_btn.pressed.connect(_on_action)
	_action_btn.visible = false
	btn_row.add_child(_action_btn)

	_next_btn = Button.new()
	_next_btn.add_theme_font_size_override("font_size", 9)
	_next_btn.pressed.connect(_on_next)
	btn_row.add_child(_next_btn)

	_canvas.hide()

func interact():
	if _is_open:
		_on_next()
		return
	if pre_interact_cb.is_valid():
		pre_interact_cb.call()
	if dialogues.is_empty():
		return
	_is_open = true
	if _player_ref and "is_in_dialogue" in _player_ref:
		_player_ref.is_in_dialogue = true
	_dial_idx = 0
	_name_lbl.text = npc_name
	_text_lbl.text = dialogues[0]
	_next_btn.text = "Chiudi" if dialogues.size() <= 1 else "Avanti"
	if action_label != "" and action_cb.is_valid():
		_action_btn.text = action_label
		_action_btn.visible = true
	else:
		_action_btn.visible = false
	_canvas.show()

func _on_next():
	_dial_idx += 1
	if _dial_idx >= dialogues.size():
		_close()
		return
	_text_lbl.text = dialogues[_dial_idx]
	if _dial_idx >= dialogues.size() - 1:
		_next_btn.text = "Chiudi"

func _on_action():
	if action_cb.is_valid():
		action_cb.call()

func _close():
	_is_open = false
	_canvas.hide()
	if _player_ref and "is_in_dialogue" in _player_ref:
		_player_ref.is_in_dialogue = false

func set_action(label: String, cb: Callable):
	action_label = label
	action_cb = cb
	if _action_btn:
		_action_btn.text = label
		_action_btn.visible = true
