extends CanvasLayer

const RECIPES = [
	{
		"name": "Spada di ferro",
		"type": "weapon",
		"damage": 20,
		"materials": {"Frammento di ferro": 3},
	},
	{
		"name": "Armatura di pelle",
		"type": "armor",
		"damage": 0,
		"materials": {"Pelle grezza": 2},
	},
	{
		"name": "Frecce",
		"type": "weapon",
		"damage": 15,
		"materials": {"Osso": 2},
	},
]

var player_ref: Node
var recipe_container: VBoxContainer

func _ready():
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -160
	panel.offset_top = -120
	panel.offset_right = 160
	panel.offset_bottom = 120
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Forgeria"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	recipe_container = VBoxContainer.new()
	recipe_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(recipe_container)

	vbox.add_child(HSeparator.new())

	var close_btn = Button.new()
	close_btn.text = "Chiudi [ESC]"
	close_btn.pressed.connect(hide)
	vbox.add_child(close_btn)

	hide()

func show_forge(player: Node):
	player_ref = player
	_refresh_recipes()
	show()

func _refresh_recipes():
	for child in recipe_container.get_children():
		child.queue_free()

	if player_ref == null:
		return

	var any_available = false
	for recipe in RECIPES:
		if _can_craft(recipe["materials"]):
			any_available = true
			_add_recipe_row(recipe)

	if not any_available:
		var label = Label.new()
		label.text = "Nessuna ricetta disponibile.\nRaccogli più materiali!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recipe_container.add_child(label)

func _add_recipe_row(recipe: Dictionary):
	var hbox = HBoxContainer.new()
	recipe_container.add_child(hbox)

	var info = Label.new()
	var mats: PackedStringArray = []
	for mat in recipe["materials"]:
		mats.append("%s x%d" % [mat, recipe["materials"][mat]])
	var stat = " [ATK %d]" % recipe["damage"] if recipe["damage"] > 0 else ""
	info.text = "%s%s\n%s" % [recipe["name"], stat, ", ".join(mats)]
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var btn = Button.new()
	btn.text = "Forgia"
	btn.pressed.connect(_on_forge.bind(recipe))
	hbox.add_child(btn)

func _can_craft(materials: Dictionary) -> bool:
	for mat_name in materials:
		var count = 0
		for item in player_ref.inventory:
			if item == mat_name:
				count += 1
		if count < materials[mat_name]:
			return false
	return true

func _on_forge(recipe: Dictionary):
	if player_ref == null:
		return
	for mat_name in recipe["materials"]:
		for _i in range(recipe["materials"][mat_name]):
			var idx = player_ref.inventory.find(mat_name)
			if idx >= 0:
				player_ref.inventory.remove_at(idx)
	var item = {
		"name": recipe["name"],
		"type": recipe["type"],
		"damage": recipe["damage"],
		"essence_slots": [],
	}
	player_ref.inventory.append(item)
	if item["type"] == "weapon":
		if player_ref.equipped_weapon.is_empty() or item["damage"] > player_ref.equipped_weapon.get("damage", 0):
			player_ref.equipped_weapon = item
			print("Arma equipaggiata: %s (ATK: %d)" % [item["name"], item["damage"]])
	player_ref.inventory_changed.emit(player_ref.inventory)
	print("Forgiato: %s" % item["name"])
	_refresh_recipes()

func _process(_delta):
	if visible and Input.is_action_just_pressed("ui_cancel"):
		hide()
