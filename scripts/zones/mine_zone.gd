extends "res://scripts/zone_base.gd"

const TILE_ROCK := Vector2i(3, 0)
const TILE_PATH := Vector2i(1, 0)
const TILE_DUNG := Vector2i(4, 0)

const MINE_ENEMIES = [
	{"enemy_name": "Slime",     "hp": 40, "attack": 10, "defense": 3, "drop": "Frammento di ferro"},
	{"enemy_name": "Scheletro", "hp": 30, "attack": 12, "defense": 4, "drop": "Osso"},
]

func get_zone_name() -> String:
	return "Miniera"

func get_scene_path() -> String:
	return "res://scenes/world/mine_entrance.tscn"

func get_spawn_pos(spawn_id: String) -> Vector2:
	match spawn_id:
		"south": return Vector2(0, 272)
		_:       return Vector2(0, 272)

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

	# Fill rock base (40x40 tiles)
	for x in range(-20, 21):
		for y in range(-20, 21):
			tilemap.set_cell(Vector2i(x, y), 0, TILE_ROCK)

	# Main tunnel N-S
	for y in range(-20, 21):
		for dx in range(-2, 3):
			tilemap.set_cell(Vector2i(dx, y), 0, TILE_PATH)

	# Side tunnels
	for x in range(-20, 21):
		for dy in range(-1, 2):
			tilemap.set_cell(Vector2i(x, dy - 8), 0, TILE_PATH)
			tilemap.set_cell(Vector2i(x, dy + 8), 0, TILE_PATH)

	# Ore veins (dungeon entrance tile used as ore marker)
	var ore_spots = [
		Vector2i(-8, -12), Vector2i(10, -5), Vector2i(-12, 6),
		Vector2i(14, 12), Vector2i(-6, 15), Vector2i(8, -16),
		Vector2i(-16, 0), Vector2i(12, -14),
	]
	for os in ore_spots:
		tilemap.set_cell(os, 0, TILE_DUNG)

	# Entrance at south
	for dx in range(-3, 4):
		tilemap.set_cell(Vector2i(dx, 19), 0, TILE_PATH)
		tilemap.set_cell(Vector2i(dx, 20), 0, TILE_PATH)

# ── Zone ─────────────────────────────────────────────────────────────

func _setup_zone():
	set_camera_limits(-320, -320, 336, 336)
	_add_torches()
	_add_ore_pickups()
	_spawn_zone_enemies()
	_add_exits()

func _add_torches():
	var torch_positions = [
		Vector2(-48, -80), Vector2(48, -80),
		Vector2(-48, 32),  Vector2(48, 32),
		Vector2(-48, 144), Vector2(48, 144),
		Vector2(-128, -8), Vector2(128, -8),
	]
	for tp in torch_positions:
		var torch = ColorRect.new()
		torch.color = Color("#FFD700")
		torch.size = Vector2(6, 6)
		torch.position = tp - Vector2(3, 3)
		add_child(torch)

func _add_ore_pickups():
	var coal_positions = [
		Vector2(-128, -192), Vector2(160, 80), Vector2(-48, 240),
		Vector2(192, -112),
	]
	for cp in coal_positions:
		spawn_drop(cp, "Carbone")

	var iron_positions = [
		Vector2(80, -192), Vector2(-160, 96),
	]
	for ip in iron_positions:
		spawn_drop(ip, "Frammento di ferro")

func _spawn_zone_enemies():
	var count = MAX_ENEMIES - enemies.size()
	for i in range(count):
		var cfg = MINE_ENEMIES[i % MINE_ENEMIES.size()]
		spawn_enemy(cfg, rand_pos(80.0, 18))

func _add_exits():
	# South → Town
	add_exit(Vector2(0, 328), Vector2(64, 16),
		"res://scenes/world/town.tscn", "from_mine")
