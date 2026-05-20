extends CanvasLayer

signal role_chosen(role_id: String)

const ROLES = [
	{
		"id": "esploratore",
		"name": "Esploratore",
		"desc": "Esplora il mondo,\ncombatti e raccogli\nrisorse rare.",
		"hp": 50, "attack": 12, "defense": 3,
		"bonus": "Bonus loot dai\nnemici sconfitti",
	},
	{
		"id": "fabbro",
		"name": "Fabbro",
		"desc": "Forgia le armi\npiù potenti\ndel regno.",
		"hp": 40, "attack": 15, "defense": 2,
		"bonus": "+1 slot essenza\nsulle armi forgiate",
	},
	{
		"id": "locandiere",
		"name": "Locandiere",
		"desc": "Gestisci la locanda,\ncrea pozioni e\ncura gli alleati.",
		"hp": 65, "attack": 8, "defense": 5,
		"bonus": "Pozioni più\nefficaci in battaglia",
	},
]

func _ready():
	var overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.05, 0.05, 0.12, 0.97)
	add_child(overlay)

	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	overlay.add_child(root)

	root.add_child(_spacer())

	var title = Label.new()
	title.text = "EMBER PACT"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var sub = Label.new()
	sub.text = "Scegli il tuo ruolo — la scelta è permanente."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	var cards = HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 20)
	root.add_child(cards)

	for role in ROLES:
		cards.add_child(_make_card(role))

	root.add_child(_spacer())

	hide()

func _spacer() -> Control:
	var s = Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return s

func _make_card(role: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(170, 230)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = role["name"]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	vbox.add_child(HSeparator.new())

	var desc_lbl = Label.new()
	desc_lbl.text = role["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var stats_lbl = Label.new()
	stats_lbl.text = "HP %d  ATK %d  DEF %d" % [role["hp"], role["attack"], role["defense"]]
	stats_lbl.add_theme_font_size_override("font_size", 10)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_lbl)

	vbox.add_child(HSeparator.new())

	var bonus_lbl = Label.new()
	bonus_lbl.text = role["bonus"]
	bonus_lbl.add_theme_font_size_override("font_size", 10)
	bonus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(bonus_lbl)

	vbox.add_child(_spacer())

	var btn = Button.new()
	btn.text = "Scegli"
	btn.pressed.connect(_on_choose.bind(role))
	vbox.add_child(btn)

	return panel

func show_select():
	show()

func _on_choose(role: Dictionary):
	role_chosen.emit(role["id"])
	hide()
