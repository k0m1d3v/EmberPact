extends CanvasLayer

const ITEM_ICON_MAP = {
	"Frammento di ferro": "res://assets/icons/inv_iron_ore.png",
	"Moneta di rame":     "res://assets/icons/inv_coin.png",
	"Pelle grezza":       "res://assets/icons/inv_fur.png",
	"Osso":               "res://assets/icons/inv_bone.png",
	"Pelliccia":          "res://assets/icons/inv_fur.png",
	"Spada di ferro":     "res://assets/icons/inv_sword_iron.png",
	"Armatura di pelle":  "res://assets/icons/inv_armor_leather.png",
	"Frecce":             "res://assets/icons/inv_feather.png",
	"Carbone":            "res://assets/icons/inv_carbone.png",
	"Martello":           "res://assets/icons/inv_hammer.png",
}

var player_ref: Node = null
var slot_nodes: Array = []
var weapon_icon: TextureRect
var armor_icon: TextureRect
var weapon_label: Label
var armor_label: Label
var materials_label: Label

func _ready():
	layer = 5

	var bg = NinePatchRect.new()
	bg.texture = load("res://assets/ui/panel_inventory_9p.png")
	bg.patch_margin_left = 6
	bg.patch_margin_right = 6
	bg.patch_margin_top = 6
	bg.patch_margin_bottom = 6
	bg.anchor_left = 0.5
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 6
	scroll.offset_top = 6
	scroll.offset_right = -6
	scroll.offset_bottom = -6
	bg.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "Inventario"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("#F5E6C8"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var hint = Label.new()
	hint.text = "[E] Chiudi"
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color("#A88A50"))
	header.add_child(hint)
	vbox.add_child(header)
	vbox.add_child(HSeparator.new())

	# Equipment
	var eq_title = Label.new()
	eq_title.text = "EQUIPAGGIAMENTO"
	eq_title.add_theme_font_size_override("font_size", 9)
	eq_title.add_theme_color_override("font_color", Color("#C8A96E"))
	vbox.add_child(eq_title)

	var eq_row = HBoxContainer.new()
	eq_row.add_theme_constant_override("separation", 6)
	var wpn_data = _make_equip_panel("ARMA")
	weapon_icon = wpn_data["icon"]
	weapon_label = wpn_data["label"]
	eq_row.add_child(wpn_data["panel"])
	var arm_data = _make_equip_panel("ARMATURA")
	armor_icon = arm_data["icon"]
	armor_label = arm_data["label"]
	eq_row.add_child(arm_data["panel"])
	vbox.add_child(eq_row)
	vbox.add_child(HSeparator.new())

	# Items grid
	var obj_title = Label.new()
	obj_title.text = "OGGETTI"
	obj_title.add_theme_font_size_override("font_size", 9)
	obj_title.add_theme_color_override("font_color", Color("#C8A96E"))
	vbox.add_child(obj_title)

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	for _i in range(20):
		var slot = _make_item_slot()
		grid.add_child(slot)
		slot_nodes.append(slot)
	vbox.add_child(grid)
	vbox.add_child(HSeparator.new())

	# Materials text
	var mat_title = Label.new()
	mat_title.text = "MATERIALI"
	mat_title.add_theme_font_size_override("font_size", 9)
	mat_title.add_theme_color_override("font_color", Color("#C8A96E"))
	vbox.add_child(mat_title)

	materials_label = Label.new()
	materials_label.add_theme_font_size_override("font_size", 9)
	materials_label.add_theme_color_override("font_color", Color("#F5E6C8"))
	materials_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(materials_label)

	hide()

func _process(_delta):
	if visible and Input.is_action_just_pressed("ui_cancel"):
		hide()

func _make_equip_panel(slot_type: String) -> Dictionary:
	var panel = NinePatchRect.new()
	panel.texture = load("res://assets/ui/panel_inventory_9p.png")
	panel.patch_margin_left = 4
	panel.patch_margin_right = 4
	panel.patch_margin_top = 4
	panel.patch_margin_bottom = 4
	panel.custom_minimum_size = Vector2(80, 52)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vb = VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var type_lbl = Label.new()
	type_lbl.text = slot_type
	type_lbl.add_theme_font_size_override("font_size", 8)
	type_lbl.add_theme_color_override("font_color", Color("#C8A96E"))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(type_lbl)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbox.add_child(icon)

	var lbl = Label.new()
	lbl.text = "— vuoto —"
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color("#F5E6C8"))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	return {"panel": panel, "icon": icon, "label": lbl}

func _make_item_slot() -> NinePatchRect:
	var slot = NinePatchRect.new()
	slot.texture = load("res://assets/ui/slot_inventory_9p.png")
	slot.patch_margin_left = 3
	slot.patch_margin_right = 3
	slot.patch_margin_top = 3
	slot.patch_margin_bottom = 3
	slot.custom_minimum_size = Vector2(22, 22)

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.visible = false
	slot.add_child(icon)

	var qty = Label.new()
	qty.name = "Qty"
	qty.add_theme_font_size_override("font_size", 7)
	qty.add_theme_color_override("font_color", Color.WHITE)
	qty.anchor_left = 1.0
	qty.anchor_right = 1.0
	qty.anchor_top = 1.0
	qty.anchor_bottom = 1.0
	qty.offset_left = -14
	qty.offset_top = -10
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.visible = false
	slot.add_child(qty)

	return slot

func show_panel():
	if player_ref != null:
		update_display(player_ref.inventory)
	show()

func update_display(inventory: Array):
	if player_ref == null:
		return

	# Equipment slots
	_update_equip_slot(weapon_icon, weapon_label, player_ref.equipped_weapon, false)
	_update_equip_slot(armor_icon, armor_label, player_ref.equipped_armor, true)

	# Separate dicts and strings
	var mat_counts: Dictionary = {}
	var dict_items: Array = []
	for item in inventory:
		if item is String:
			mat_counts[item] = mat_counts.get(item, 0) + 1
		elif item is Dictionary:
			dict_items.append(item)

	# Fill slots: crafted items first, then grouped materials
	var idx = 0
	for item in dict_items:
		if idx >= slot_nodes.size():
			break
		_fill_slot(slot_nodes[idx], item.get("name", "?"), 0)
		idx += 1
	for mat_name in mat_counts:
		if idx >= slot_nodes.size():
			break
		_fill_slot(slot_nodes[idx], mat_name, mat_counts[mat_name])
		idx += 1
	for i in range(idx, slot_nodes.size()):
		_clear_slot(slot_nodes[i])

	# Materials text list
	if mat_counts.is_empty():
		materials_label.text = "(nessuno)"
	else:
		var lines: PackedStringArray = []
		for mat in mat_counts:
			lines.append("%s x%d" % [mat, mat_counts[mat]])
		materials_label.text = "\n".join(lines)

func _update_equip_slot(icon: TextureRect, lbl: Label, item: Dictionary, is_armor: bool):
	if item.is_empty():
		icon.texture = null
		lbl.text = "— vuoto —"
		lbl.add_theme_color_override("font_color", Color("#A88A50"))
		return
	var item_name = item.get("name", "?")
	var icon_path = ITEM_ICON_MAP.get(item_name, "res://assets/icons/inv_gem.png")
	icon.texture = load(icon_path)
	var stat_val = item.get("defense", 0) if is_armor else item.get("damage", 0)
	var stat_str = "[DEF +%d]" % stat_val if is_armor else "[ATK %d]" % stat_val
	lbl.text = "%s\n%s" % [item_name, stat_str]
	lbl.add_theme_color_override("font_color", Color("#5BBA6F") if is_armor else Color("#F4A261"))

func _fill_slot(slot: NinePatchRect, item_name: String, qty: int):
	var icon = slot.get_node_or_null("Icon") as TextureRect
	var qty_lbl = slot.get_node_or_null("Qty") as Label
	if icon:
		var path = ITEM_ICON_MAP.get(item_name, "res://assets/icons/inv_gem.png")
		icon.texture = load(path)
		icon.visible = true
	if qty_lbl:
		qty_lbl.visible = qty > 1
		if qty > 1:
			qty_lbl.text = str(qty)

func _clear_slot(slot: NinePatchRect):
	var icon = slot.get_node_or_null("Icon") as TextureRect
	var qty_lbl = slot.get_node_or_null("Qty") as Label
	if icon:
		icon.texture = null
		icon.visible = false
	if qty_lbl:
		qty_lbl.visible = false
