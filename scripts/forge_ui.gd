extends CanvasLayer

const BASE_RECIPES = [
	{
		"name": "Spada di ferro",
		"type": "weapon",
		"damage": 18,
		"defense": 0,
		"materials": {"Frammento di ferro": 3},
	},
	{
		"name": "Armatura di pelle",
		"type": "armor",
		"damage": 0,
		"defense": 5,
		"materials": {"Pelle grezza": 2},
	},
	{
		"name": "Frecce",
		"type": "weapon",
		"damage": 10,
		"defense": 0,
		"materials": {"Osso": 2},
	},
]

const RECIPE_MARTELLO = {
	"name": "Martello",
	"type": "weapon",
	"damage": 22,
	"defense": 0,
	"materials": {"Frammento di ferro": 2, "Carbone": 1},
}

func _get_recipes() -> Array:
	var list = BASE_RECIPES.duplicate()
	if PlayerData.hammer_recipe_unlocked:
		list.append(RECIPE_MARTELLO)
	return list

const RECIPE_ICONS = {
	"Spada di ferro":    "res://assets/forge/recipe_sword_iron.png",
	"Armatura di pelle": "res://assets/forge/recipe_armor_leather.png",
	"Frecce":            "res://assets/forge/recipe_arrows.png",
	"Martello":          "res://assets/forge/recipe_hammer.png",
}

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

	# Header with icons
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 6)

	var anvil = TextureRect.new()
	anvil.texture = load("res://assets/forge/anvil.png")
	anvil.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anvil.custom_minimum_size = Vector2(16, 16)
	anvil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(anvil)

	var title = Label.new()
	title.text = "Forgeria"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var flame = TextureRect.new()
	flame.texture = load("res://assets/forge/flame.png")
	flame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flame.custom_minimum_size = Vector2(16, 16)
	flame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(flame)

	vbox.add_child(header)
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
	for recipe in _get_recipes():
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
	hbox.add_theme_constant_override("separation", 6)
	recipe_container.add_child(hbox)

	var icon_path = RECIPE_ICONS.get(recipe["name"], "")
	if icon_path != "":
		var icon = TextureRect.new()
		icon.texture = load(icon_path)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)

	var info = Label.new()
	var mats: PackedStringArray = []
	for mat in recipe["materials"]:
		mats.append("%s x%d" % [mat, recipe["materials"][mat]])
	var stat = ""
	if recipe["damage"] > 0:
		stat = " [ATK %d]" % recipe["damage"]
	elif recipe.get("defense", 0) > 0:
		stat = " [DEF +%d]" % recipe["defense"]
	var slot_str = ""
	if recipe["type"] == "weapon":
		var slot_count = 2 if player_ref != null and player_ref.role == "fabbro" else 1
		slot_str = "\nSlot: %s" % "○".repeat(slot_count)
	info.text = "%s%s\n%s%s" % [recipe["name"], stat, ", ".join(mats), slot_str]
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
			if item is String and item == mat_name:
				count += 1
		if count < materials[mat_name]:
			return false
	return true

func _on_forge(recipe: Dictionary):
	if player_ref == null:
		return
	for mat_name in recipe["materials"]:
		for _i in range(recipe["materials"][mat_name]):
			var idx = -1
			for i in range(player_ref.inventory.size()):
				if player_ref.inventory[i] is String and player_ref.inventory[i] == mat_name:
					idx = i
					break
			if idx >= 0:
				player_ref.inventory.remove_at(idx)
	var slot_count = 0
	if recipe["type"] == "weapon":
		slot_count = 2 if player_ref.role == "fabbro" else 1
	var item = {
		"name": recipe["name"],
		"type": recipe["type"],
		"damage": recipe["damage"],
		"defense": recipe.get("defense", 0),
		"essence_slots": [],
	}
	for _i in range(slot_count):
		item["essence_slots"].append(null)
	player_ref.inventory.append(item)
	if item["type"] == "weapon":
		if player_ref.equipped_weapon.is_empty() or item["damage"] > player_ref.equipped_weapon.get("damage", 0):
			player_ref.equipped_weapon = item
			print("Arma equipaggiata: %s (ATK: %d)" % [item["name"], item["damage"]])
	elif item["type"] == "armor":
		if player_ref.equipped_armor.is_empty() or item["defense"] > player_ref.equipped_armor.get("defense", 0):
			player_ref.equipped_armor = item
			print("Armatura equipaggiata: %s (DEF +%d)" % [item["name"], item["defense"]])
	player_ref.inventory_changed.emit(player_ref.inventory)
	print("Forgiato: %s" % item["name"])
	_refresh_recipes()

func _process(_delta):
	if visible and Input.is_action_just_pressed("ui_cancel"):
		hide()
