extends "res://scripts/zone_base.gd"

const TILE_PATH := Vector2i(1, 0)
const TILE_ROCK := Vector2i(3, 0)
const TILE_TREE := Vector2i(5, 0)

func get_zone_name() -> String:
	return "Locanda"

func get_scene_path() -> String:
	return "res://scenes/world/inn.tscn"

func get_spawn_pos(spawn_id: String) -> Vector2:
	match spawn_id:
		"north": return Vector2(0, -128)
		_:       return Vector2(0, 0)

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

	var src_floor = TileSetAtlasSource.new()
	src_floor.texture = load("res://assets/tiles/tile_inn_floor.png")
	src_floor.texture_region_size = Vector2i(16, 16)
	src_floor.create_tile(Vector2i(0, 0))
	tileset.add_source(src_floor, 1)

	tilemap.tile_set = tileset

	# Floor: inn floor tiles (30x20)
	for x in range(-15, 16):
		for y in range(-10, 11):
			tilemap.set_cell(Vector2i(x, y), 1, Vector2i(0, 0))

	# Outer walls
	for x in range(-15, 16):
		tilemap.set_cell(Vector2i(x, -10), 0, TILE_ROCK)
		tilemap.set_cell(Vector2i(x, 10),  0, TILE_ROCK)
	for y in range(-10, 11):
		tilemap.set_cell(Vector2i(-15, y), 0, TILE_ROCK)
		tilemap.set_cell(Vector2i(15, y),  0, TILE_ROCK)

	# Interior features: fireplace area (rock cluster west side)
	for dx in range(-12, -8):
		for dy in range(-6, -2):
			tilemap.set_cell(Vector2i(dx, dy), 0, TILE_ROCK)

	# Garden (tree tiles east side)
	for dx in range(8, 13):
		for dy in range(3, 8):
			tilemap.set_cell(Vector2i(dx, dy), 0, TILE_TREE)

# ── Zone ─────────────────────────────────────────────────────────────

func _setup_zone():
	set_camera_limits(-240, -160, 256, 176)
	_add_npcs()
	_add_exits()

func _add_npcs():
	# Marta the innkeeper
	var marta = make_npc("Marta", Vector2(-48, -48), Color("#A0522D"))
	marta.npc_sprite = "res://assets/sprites/npc_marta.png"
	marta.dialogues = [
		"Benvenuto alla Locanda del Focolare!",
		"Posso ripristinare i tuoi HP per 5 Monete di rame.",
	]

	var rest_called = false
	marta.set_action("Riposa (5 monete)", func():
		var coins = 0
		for item in player.inventory:
			if item is String and item == "Moneta di rame":
				coins += 1
		if coins >= 5:
			var removed = 0
			var i = 0
			while i < player.inventory.size() and removed < 5:
				if player.inventory[i] is String and player.inventory[i] == "Moneta di rame":
					player.inventory.remove_at(i)
					removed += 1
				else:
					i += 1
			player.hp = player.max_hp
			player.hp_changed.emit(player.hp, player.max_hp)
			player.inventory_changed.emit(player.inventory)
			NotificationManager.notify("HP ripristinati!")
			marta.dialogues = ["Buon riposo! Vieni quando hai bisogno."]
			if QuestManager.is_active("quest_02"):
				var pellicce = 0
				for item in player.inventory:
					if item is String and item == "Pelliccia":
						pellicce += 1
				if pellicce >= 2:
					NotificationManager.notify("Quest completata: Rifornimento!")
		else:
			marta.dialogues = ["Non hai abbastanza monete (ti servono 5)."])

	marta.pre_interact_cb = func():
		if QuestManager.is_done("quest_02"):
			marta.dialogues = ["Grazie per le pellicce! Sei sempre il benvenuto."]
			marta.action_label = ""
			marta.action_cb = Callable()
		elif QuestManager.is_active("quest_02"):
			var prog = QuestManager.progress_text("quest_02")
			marta.dialogues = [
				"Come va la raccolta? " + prog,
				"Posso comunque ripristinarti gli HP per 5 monete.",
			]
		else:
			marta.dialogues = [
				"Benvenuto alla Locanda del Focolare!",
				"Ho bisogno di 2 Pellicce per i giacigli. Me le porti?",
				"Ti offro il riposo gratuito in cambio!",
			]
			marta.set_action("Accetta incarico", func():
				QuestManager.accept_quest("quest_02")
				marta.action_label = ""
				marta.action_cb = Callable()
				if marta._action_btn:
					marta._action_btn.visible = false)

func _add_exits():
	# North → Town
	add_exit(Vector2(0, -168), Vector2(48, 16),
		"res://scenes/world/town.tscn", "from_inn")
