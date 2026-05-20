extends CanvasLayer

var items_label: Label

func _ready():
	var panel = Panel.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -188
	panel.offset_top = -128
	panel.offset_right = -8
	panel.offset_bottom = -8
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "[ Inventario ]"
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	items_label = Label.new()
	items_label.text = "(vuoto)"
	items_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(items_label)

func update_display(inventory: Array):
	if inventory.is_empty():
		items_label.text = "(vuoto)"
		return
	var counts: Dictionary = {}
	for item in inventory:
		counts[item] = counts.get(item, 0) + 1
	var lines: PackedStringArray = []
	for item_name in counts:
		lines.append("%s x%d" % [item_name, counts[item_name]])
	items_label.text = "\n".join(lines)
