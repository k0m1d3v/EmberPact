extends "res://scripts/zone_base.gd"

const TILE_GRASS := Vector2i(0, 0)
const TILE_PATH  := Vector2i(1, 0)
const TILE_ROCK  := Vector2i(3, 0)
const TILE_DUNG  := Vector2i(4, 0)
const TILE_TREE  := Vector2i(5, 0)

const FOREST_ENEMIES = [
	{"enemy_name": "Lupo",   "hp": 35, "attack": 14, "defense": 2, "drop": "Pelliccia"},
	{"enemy_name": "Goblin", "hp": 20, "attack": 12, "defense": 1, "drop": "Moneta di rame"},
]

func get_zone_name() -> String:
	return "Foresta"

func get_scene_path() -> String:
	return "res://scenes/world/forest.tscn"

func get_spawn_pos(spawn_id: String) -> Vector2:
	match spawn_id:
		"south": return Vector2(0, 432)
		"north": return Vector2(0, -432)
		_:       return Vector2(0, 432)

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

	# Fill grass base (-30 to 30 tiles = 60x60)
	for x in range(-30, 31):
		for y in range(-30, 31):
			tilemap.set_cell(Vector2i(x, y), 0, TILE_GRASS)

	# Tree border (3 tiles thick)
	for x in range(-30, 31):
		for y in range(-30, 31):
			if x < -26 or x > 26 or y < -26 or y > 26:
				tilemap.set_cell(Vector2i(x, y), 0, TILE_TREE)

	# Central clearing path (cross)
	for x in range(-6, 7):
		tilemap.set_cell(Vector2i(x, 0), 0, TILE_PATH)
	for y in range(-6, 7):
		tilemap.set_cell(Vector2i(0, y), 0, TILE_PATH)

	# North path to dungeon
	for y in range(-26, -6):
		tilemap.set_cell(Vector2i(0, y), 0, TILE_PATH)

	# South path to town exit
	for y in range(6, 27):
		tilemap.set_cell(Vector2i(0, y), 0, TILE_PATH)

	# Dungeon entrance at north
	for dx in range(-2, 3):
		tilemap.set_cell(Vector2i(dx, -25), 0, TILE_DUNG)

	# Scattered rocks in forest
	var rock_spots = [
		Vector2i(-15, -10), Vector2i(12, 8), Vector2i(-8, 15),
		Vector2i(18, -12), Vector2i(-20, 5), Vector2i(10, -18),
	]
	for rs in rock_spots:
		tilemap.set_cell(rs, 0, TILE_ROCK)

# ── Zone ─────────────────────────────────────────────────────────────

func _setup_zone():
	set_camera_limits(-480, -480, 496, 496)
	_spawn_zone_enemies()
	_add_exits()

func _spawn_zone_enemies():
	var count = MAX_ENEMIES - enemies.size()
	for i in range(count):
		var cfg = FOREST_ENEMIES[i % FOREST_ENEMIES.size()]
		spawn_enemy(cfg, rand_pos(80.0, 24))

func _add_exits():
	# South → Town
	add_exit(Vector2(0, 472), Vector2(64, 16),
		"res://scenes/world/town.tscn", "from_forest")
