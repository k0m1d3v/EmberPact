extends "res://scripts/zone_base.gd"

const TILE_GRASS := Vector2i(0, 0)
const TILE_PATH  := Vector2i(1, 0)
const TILE_WATER := Vector2i(2, 0)
const TILE_ROCK  := Vector2i(3, 0)
const TILE_DUNG  := Vector2i(4, 0)

func get_zone_name() -> String:
	return "Città"

func get_scene_path() -> String:
	return "res://scenes/world/town.tscn"

func get_spawn_pos(spawn_id: String) -> Vector2:
	match spawn_id:
		"from_forest": return Vector2(0, -192)
		"from_inn":    return Vector2(0, 192)
		"from_mine":   return Vector2(272, 0)
		_:             return Vector2(0, 0)

func _on_first_run():
	player.set_process(false)
	_show_role_select()

# ── Tilemap ──────────────────────────────────────────────────────────

func _setup_tilemap():
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	var src = TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/tileset_atlas.png")
	src.texture_region_size = Vector2i(16, 16)
	for col in range(6):
		src.create_tile(Vector2i(col, 0))
	tileset.add_source(src, 0)
	tilemap.tile_set = tileset

	# Fill grass base
	for x in range(-20, 21):
		for y in range(-15, 16):
			tilemap.set_cell(Vector2i(x, y), 0, TILE_GRASS)

	# Main E-W path at y = 0
	for x in range(-20, 21):
		tilemap.set_cell(Vector2i(x, 0), 0, TILE_PATH)

	# N-S path at x = 0
	for y in range(-15, 16):
		tilemap.set_cell(Vector2i(0, y), 0, TILE_PATH)

	# Fountain (water) near center, offset from paths
	for dx in range(-2, 1):
		for dy in range(-4, -1):
			tilemap.set_cell(Vector2i(dx, dy), 0, TILE_WATER)

	# House outlines NW
	for x in range(-18, -12):
		tilemap.set_cell(Vector2i(x, -13), 0, TILE_ROCK)
		tilemap.set_cell(Vector2i(x, -9),  0, TILE_ROCK)
	for y in range(-13, -8):
		tilemap.set_cell(Vector2i(-18, y), 0, TILE_ROCK)
		tilemap.set_cell(Vector2i(-12, y), 0, TILE_ROCK)

	# House outlines NE
	for x in range(12, 19):
		tilemap.set_cell(Vector2i(x, -13), 0, TILE_ROCK)
		tilemap.set_cell(Vector2i(x, -9),  0, TILE_ROCK)
	for y in range(-13, -8):
		tilemap.set_cell(Vector2i(12, y), 0, TILE_ROCK)
		tilemap.set_cell(Vector2i(18, y), 0, TILE_ROCK)

	# House outlines SW
	for x in range(-18, -12):
		tilemap.set_cell(Vector2i(x, 6),  0, TILE_ROCK)
		tilemap.set_cell(Vector2i(x, 12), 0, TILE_ROCK)
	for y in range(6, 13):
		tilemap.set_cell(Vector2i(-18, y), 0, TILE_ROCK)
		tilemap.set_cell(Vector2i(-12, y), 0, TILE_ROCK)

	# Dungeon entrance marker at east border
	for y in range(-1, 2):
		tilemap.set_cell(Vector2i(19, y), 0, TILE_DUNG)
		tilemap.set_cell(Vector2i(20, y), 0, TILE_DUNG)

# ── Zone ─────────────────────────────────────────────────────────────

func _setup_zone():
	set_camera_limits(-320, -240, 336, 256)
	_add_forge()
	_add_npcs()
	_add_exits()

func _add_forge():
	forge_node = Node2D.new()
	forge_node.set_script(ForgeScript)
	forge_node.global_position = Vector2(96, -144)
	add_child(forge_node)
	forge_node.setup(player, forge_ui_node)
	player.forge_ref = forge_node

func _add_npcs():
	# Fabbro Aldric
	var aldric = make_npc("Aldric", Vector2(96, -80), Color("#8B6914"))
	aldric.dialogues = [
		"Servo il miglior acciaio di queste terre.",
		"Portami minerali e ti forgerò qualcosa di speciale.",
		"La Forgeria è proprio lì dietro. Usa [E] per aprirla.",
	]
	aldric.pre_interact_cb = func():
		if QuestManager.is_active("quest_03"):
			var prog = QuestManager.progress_text("quest_03")
			aldric.dialogues = [
				"Stai raccogliendo i frammenti? Progresso: " + prog,
				"Continua così, ti aspetto!",
			]
		elif QuestManager.is_done("quest_03"):
			aldric.dialogues = ["Ottimo lavoro! Il Martello è ora disponibile in Forgeria."]
		else:
			aldric.dialogues = [
				"Servo il miglior acciaio di queste terre.",
				"Portami 3 Frammenti di ferro e sblocchi una nuova ricetta.",
				"La Forgeria è lì accanto. Usa [E] per aprirla.",
			]
		if not QuestManager.is_active("quest_03") and not QuestManager.is_done("quest_03"):
			aldric.set_action("Accetta incarico", func():
				QuestManager.accept_quest("quest_03")
				aldric.action_label = ""
				aldric.action_cb = Callable()
				if aldric._action_btn:
					aldric._action_btn.visible = false)

	# Anziano del villaggio
	var anziano = make_npc("Anziano", Vector2(0, -96), Color("#9C7C54"))
	anziano.dialogues = [
		"Ember Pact... un antico accordo tra tre gilde.",
		"Il Locandiere che nutre, il Fabbro che forgia, l'Esploratore che scopre.",
		"Senza di loro il mondo cade nell'oscurità.",
		"Dimostra il tuo valore sconfiggendo 3 Slime nella Foresta a Nord.",
	]
	anziano.pre_interact_cb = func():
		if QuestManager.is_done("quest_01"):
			anziano.dialogues = ["Hai dimostrato il tuo valore. Il mondo ha bisogno di eroi come te."]
		elif QuestManager.is_active("quest_01"):
			anziano.dialogues = ["" + QuestManager.progress_text("quest_01") + " — continua così!"]
		else:
			anziano.dialogues = [
				"Ember Pact... un antico accordo tra tre gilde.",
				"Il Locandiere che nutre, il Fabbro che forgia, l'Esploratore che scopre.",
				"Senza di loro il mondo cade nell'oscurità.",
				"Dimostra il tuo valore sconfiggendo 3 Slime nella Foresta a Nord.",
			]
			anziano.set_action("Accetta incarico", func():
				QuestManager.accept_quest("quest_01")
				anziano.action_label = ""
				anziano.action_cb = Callable()
				if anziano._action_btn:
					anziano._action_btn.visible = false)

	# Guardia (east side, near mine entrance)
	var guardia = make_npc("Guardia", Vector2(256, 0), Color("#4A5568"))
	guardia.pre_interact_cb = func():
		if player.get_attack() >= 15:
			guardia.dialogues = ["Sei armato. Passa pure, avventuriero."]
		else:
			guardia.dialogues = ["La miniera è pericolosa.", "Torna quando sei più forte (ATK >= 15)."]

	# Bacheca
	var bacheca = Node2D.new()
	bacheca.set_script(load("res://scripts/quest_board.gd"))
	bacheca.global_position = Vector2(80, -48)
	add_child(bacheca)

func _add_exits():
	# North → Forest
	add_exit(Vector2(0, -248), Vector2(64, 16),
		"res://scenes/world/forest.tscn", "south")

	# South → Inn
	add_exit(Vector2(0, 248), Vector2(64, 16),
		"res://scenes/world/inn.tscn", "north")

	# East → Mine (blocked unless player has ATK >= 15)
	add_exit(Vector2(328, 0), Vector2(16, 64),
		"res://scenes/world/mine_entrance.tscn", "south",
		func():
			if player.get_attack() >= 15:
				return true
			NotificationManager.notify("Hai bisogno di un'arma più potente!")
			return false)

# ── Role select (first run) ───────────────────────────────────────────

func _show_role_select():
	role_select_ui = CanvasLayer.new()
	role_select_ui.set_script(RoleSelectUIScript)
	role_select_ui.layer = 8
	add_child(role_select_ui)
	role_select_ui.role_chosen.connect(_on_role_chosen)
	role_select_ui.show_select()

func _on_role_chosen(role_id: String):
	player.apply_role(role_id)
	PlayerData.save_from_player(player)
	save_mgr.save_game(player)
	_start_game()
