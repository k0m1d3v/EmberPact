extends CanvasLayer

func _ready():
	var overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.75)
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Sei stato sconfitto..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	var btn = Button.new()
	btn.text = "Riprova"
	btn.pressed.connect(func():
		PlayerData.current_scene = "res://scenes/world/town.tscn"
		PlayerData.spawn_point = "default"
		hide()
		SceneManager.change_scene("res://scenes/world/town.tscn", "default"))
	vbox.add_child(btn)

	var new_game_btn = Button.new()
	new_game_btn.text = "Nuova Partita"
	new_game_btn.pressed.connect(func():
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("save.json")
		PlayerData.reset()
		QuestManager.reset()
		hide()
		SceneManager.change_scene("res://scenes/world/town.tscn", "default"))
	vbox.add_child(new_game_btn)

	hide()

func show_game_over():
	show()
