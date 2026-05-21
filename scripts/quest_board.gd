extends Node2D

var _player_ref: Node = null
var _canvas: CanvasLayer = null
var _quest_container: VBoxContainer = null
var _is_open: bool = false

const RANGE := 28.0

func _ready():
	var spr = Sprite2D.new()
	spr.texture = load("res://assets/sprites/prop_quest_board.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)

	var lbl = Label.new()
	lbl.text = "Bacheca"
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.add_theme_color_override("font_color", Color("#F5E6C8"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-24, -22)
	lbl.custom_minimum_size = Vector2(48, 10)
	add_child(lbl)

	_build_panel()
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
		if "npc_near" in body:
			body.npc_near = self

func _on_body_out(body: Node):
	if body == _player_ref:
		if "npc_near" in body and body.npc_near == self:
			body.npc_near = null

func _build_panel():
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
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = 8
	panel.offset_bottom = -8
	_canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title = Label.new()
	title.text = "Bacheca delle Quest"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("#C8A96E"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "[E] Chiudi"
	close_btn.add_theme_font_size_override("font_size", 9)
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_quest_container = VBoxContainer.new()
	_quest_container.add_theme_constant_override("separation", 6)
	_quest_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_quest_container)

	_canvas.hide()

func interact():
	_refresh()
	_canvas.show()
	_is_open = true
	if _player_ref and "is_in_dialogue" in _player_ref:
		_player_ref.is_in_dialogue = true

func _refresh():
	for ch in _quest_container.get_children():
		ch.queue_free()

	var any = false
	for quest_id in QuestManager.available:
		_add_row(QuestManager.get_def(quest_id), "available")
		any = true
	for q in QuestManager.active:
		_add_row(q, "active")
		any = true
	for quest_id in QuestManager.completed:
		_add_row(QuestManager.get_def(quest_id), "done")
		any = true
	if not any:
		var lbl = Label.new()
		lbl.text = "Nessuna quest disponibile."
		lbl.add_theme_font_size_override("font_size", 9)
		_quest_container.add_child(lbl)

func _add_row(quest: Dictionary, status: String):
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 40)
	_quest_container.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var info = Label.new()
	info.add_theme_font_size_override("font_size", 9)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var title = quest.get("title", "?")
	var target = quest.get("objective_target", "?")
	var count = quest.get("objective_count", 0)
	var current = quest.get("objective_current", 0)
	var reward_gold = quest.get("reward_gold", 0)
	var reward_item = quest.get("reward_item", "")

	var reward_str = ""
	if reward_gold > 0:
		reward_str = "Ricompensa: %d monete" % reward_gold
	elif reward_item == "riposo_gratuito":
		reward_str = "Ricompensa: riposo gratuito"
	elif reward_item == "ricetta_martello":
		reward_str = "Ricompensa: ricetta Martello"

	var icon_tex = TextureRect.new()
	icon_tex.custom_minimum_size = Vector2(12, 12)
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	match status:
		"available":
			icon_tex.texture = load("res://assets/ui/icon_quest_new.png")
			info.text = "%s\n%s x%d  |  %s" % [title, target, count, reward_str]
			info.add_theme_color_override("font_color", Color("#F5E6C8"))
			var btn = Button.new()
			btn.text = "Accetta"
			btn.add_theme_font_size_override("font_size", 9)
			var qid = quest["id"]
			btn.pressed.connect(func(): QuestManager.accept_quest(qid); _refresh())
			hbox.add_child(icon_tex)
			hbox.add_child(info)
			hbox.add_child(btn)
		"active":
			icon_tex.texture = load("res://assets/ui/icon_quest_new.png")
			info.text = "%s\n%s %d/%d" % [title, target, current, count]
			info.add_theme_color_override("font_color", Color("#F4A261"))
			hbox.add_child(icon_tex)
			hbox.add_child(info)
		"done":
			icon_tex.texture = load("res://assets/ui/icon_quest_done.png")
			info.text = title
			info.add_theme_color_override("font_color", Color("#5BBA6F"))
			hbox.add_child(icon_tex)
			hbox.add_child(info)

func _close():
	_is_open = false
	_canvas.hide()
	if _player_ref and "is_in_dialogue" in _player_ref:
		_player_ref.is_in_dialogue = false
