extends Node2D

@onready var tilemap = $TileMapLayer
@onready var player = $Player

const EnemyScene = preload("res://scenes/enemies/enemy.tscn")
const BattleUIScene = preload("res://scenes/ui/battle_ui.tscn")
const ItemPickupScript = preload("res://scripts/item_pickup.gd")
const ForgeScript = preload("res://scripts/forge.gd")
const ForgeUIScript = preload("res://scripts/forge_ui.gd")

const ENEMY_CONFIGS = [
	{"enemy_name": "Slime",     "hp": 30, "attack": 8,  "defense": 2, "drop": "Frammento di ferro"},
	{"enemy_name": "Goblin",    "hp": 20, "attack": 12, "defense": 1, "drop": "Moneta di rame"},
	{"enemy_name": "Orco",      "hp": 50, "attack": 15, "defense": 5, "drop": "Pelle grezza"},
	{"enemy_name": "Scheletro", "hp": 25, "attack": 10, "defense": 3, "drop": "Osso"},
	{"enemy_name": "Lupo",      "hp": 35, "attack": 14, "defense": 2, "drop": "Pelliccia"},
]

const INITIAL_POSITIONS = [
	Vector2(128, 64),
	Vector2(-96, 80),
	Vector2(160, -128),
	Vector2(-144, -96),
	Vector2(96, -160),
]

var battle_manager: Node
var battle_ui_instance: Node
var inventory_ui_instance: Node
var forge_node: Node = null
var forge_ui_node: Node = null
var in_battle := false
var enemies: Array = []
var current_battle_enemy: Node = null

func _ready():
	_register_actions()
	generate_world()
	spawn_all_enemies(INITIAL_POSITIONS)

	battle_ui_instance = BattleUIScene.instantiate()
	add_child(battle_ui_instance)

	battle_manager = Node.new()
	battle_manager.set_script(load("res://scripts/battle_manager.gd"))
	add_child(battle_manager)
	battle_manager.battle_ended.connect(_on_battle_ended)

	inventory_ui_instance = CanvasLayer.new()
	inventory_ui_instance.set_script(load("res://scripts/inventory_ui.gd"))
	add_child(inventory_ui_instance)
	player.inventory_changed.connect(inventory_ui_instance.update_display)

	forge_ui_node = CanvasLayer.new()
	forge_ui_node.set_script(ForgeUIScript)
	add_child(forge_ui_node)

	forge_node = Node2D.new()
	forge_node.set_script(ForgeScript)
	forge_node.global_position = Vector2(48, -32)
	add_child(forge_node)
	forge_node.setup(player, forge_ui_node)

func _register_actions():
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var ev = InputEventKey.new()
		ev.keycode = KEY_E
		InputMap.action_add_event("interact", ev)

func generate_world():
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	var image = Image.create(16, 16, false, Image.FORMAT_RGB8)
	image.fill(Color(0.29, 0.51, 0.24))

	for x in range(16):
		for y in range(16):
			if x == 0 or y == 0:
				image.set_pixel(x, y, Color(0.20, 0.38, 0.16))

	var texture = ImageTexture.create_from_image(image)

	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(16, 16)
	source.create_tile(Vector2i(0, 0))
	tileset.add_source(source, 0)

	tilemap.tile_set = tileset

	for x in range(-20, 20):
		for y in range(-20, 20):
			tilemap.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

func spawn_all_enemies(positions: Array = []):
	for i in range(ENEMY_CONFIGS.size()):
		var pos: Vector2 = positions[i] if i < positions.size() else get_random_spawn_pos()
		spawn_enemy(ENEMY_CONFIGS[i], pos)

func spawn_enemy(config: Dictionary, pos: Vector2):
	var enemy = EnemyScene.instantiate()
	enemy.enemy_name = config["enemy_name"]
	enemy.hp = config["hp"]
	enemy.max_hp = config["hp"]
	enemy.attack = config["attack"]
	enemy.defense = config["defense"]
	enemy.drop_item = config["drop"]
	enemy.global_position = pos
	add_child(enemy)
	enemies.append(enemy)

func get_random_spawn_pos() -> Vector2:
	for _i in range(30):
		var tx = randi_range(-17, 17)
		var ty = randi_range(-17, 17)
		var pos = Vector2(tx * 16, ty * 16)
		if pos.distance_to(player.global_position) >= 96:
			return pos
	return Vector2(200, 200)

func _process(_delta):
	if in_battle:
		return
	check_player_enemy_collision()

func check_player_enemy_collision():
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if player.global_position.distance_to(enemy.global_position) < 20:
			start_battle(enemy)
			return

func start_battle(enemy: Node):
	in_battle = true
	current_battle_enemy = enemy
	if forge_node != null:
		forge_node.can_interact = false
	battle_manager.start_battle(player, enemy, battle_ui_instance)

func _on_battle_ended(won: bool):
	in_battle = false
	if won:
		print("Vittoria!")
		if current_battle_enemy != null and is_instance_valid(current_battle_enemy):
			spawn_drop(current_battle_enemy.global_position, current_battle_enemy.drop_item)
		enemies.erase(current_battle_enemy)
		current_battle_enemy = null
		if enemies.is_empty():
			print("Tutti i nemici sconfitti! Rigenerazione tra 10 secondi...")
			get_tree().create_timer(10.0).timeout.connect(respawn_enemies)
	else:
		print("Sconfitta o fuga")
		current_battle_enemy = null
	if forge_node != null:
		forge_node.can_interact = true

func respawn_enemies():
	print("Nemici rigenerati!")
	spawn_all_enemies()

func spawn_drop(pos: Vector2, item_name: String):
	var pickup = Area2D.new()
	pickup.set_script(ItemPickupScript)
	add_child(pickup)
	pickup.global_position = pos
	pickup.item_name = item_name
