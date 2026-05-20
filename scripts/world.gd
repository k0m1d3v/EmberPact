extends Node2D

@onready var tilemap = $TileMapLayer
@onready var player = $Player

const EnemyScene = preload("res://scenes/enemies/enemy.tscn")
const ItemPickupScript = preload("res://scripts/item_pickup.gd")
const ForgeScript = preload("res://scripts/forge.gd")
const ForgeUIScript = preload("res://scripts/forge_ui.gd")
const GameOverUIScript = preload("res://scripts/game_over_ui.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")
const RoleSelectUIScript = preload("res://scripts/role_select_ui.gd")

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

var inventory_ui_instance: Node
var forge_node: Node = null
var forge_ui_node: Node = null
var game_over_ui_node: Node = null
var save_mgr: Node = null
var role_select_ui: Node = null
var hp_label: Label = null
var hp_bar_fill: ColorRect = null
var enemies: Array = []

func _ready():
	_register_actions()
	generate_world()
	spawn_all_enemies(INITIAL_POSITIONS)

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
	player.forge_ref = forge_node

	game_over_ui_node = CanvasLayer.new()
	game_over_ui_node.set_script(GameOverUIScript)
	game_over_ui_node.layer = 10
	add_child(game_over_ui_node)

	save_mgr = Node.new()
	save_mgr.set_script(SaveManagerScript)
	add_child(save_mgr)

	role_select_ui = CanvasLayer.new()
	role_select_ui.set_script(RoleSelectUIScript)
	role_select_ui.layer = 8
	add_child(role_select_ui)
	role_select_ui.role_chosen.connect(_on_role_chosen)

	var hp_layer = CanvasLayer.new()
	hp_layer.layer = 1
	add_child(hp_layer)
	var hp_bg = ColorRect.new()
	hp_bg.color = Color("#4A0000")
	hp_bg.size = Vector2(84, 10)
	hp_bg.position = Vector2(8, 8)
	hp_layer.add_child(hp_bg)
	hp_bar_fill = ColorRect.new()
	hp_bar_fill.color = Color("#E63946")
	hp_bar_fill.size = Vector2(84, 10)
	hp_bar_fill.position = Vector2(8, 8)
	hp_layer.add_child(hp_bar_fill)
	hp_label = Label.new()
	hp_label.position = Vector2(8, 20)
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_layer.add_child(hp_label)

	player.hp_changed.connect(_on_player_hp_changed)
	player.attacked.connect(_on_player_attacked)
	player.inventory_changed.connect(func(_inv): save_mgr.save_game(player))

	player.set_process(false)

	if save_mgr.has_save() and save_mgr.load_game(player):
		_start_game()
	else:
		role_select_ui.show_select()

func _register_actions():
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var ev = InputEventKey.new()
		ev.keycode = KEY_E
		InputMap.action_add_event("interact", ev)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var ev2 = InputEventKey.new()
		ev2.keycode = KEY_SPACE
		InputMap.action_add_event("attack", ev2)

func generate_world():
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	var atlas_texture = load("res://assets/tiles/tileset_atlas.png")
	var source = TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(16, 16)
	for col in range(6):
		source.create_tile(Vector2i(col, 0))
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
	enemy.player_ref = player
	enemy.global_position = pos
	add_child(enemy)
	enemies.append(enemy)
	enemy.died.connect(_on_enemy_died)

func get_random_spawn_pos() -> Vector2:
	for _i in range(30):
		var tx = randi_range(-17, 17)
		var ty = randi_range(-17, 17)
		var pos = Vector2(tx * 16, ty * 16)
		if pos.distance_to(player.global_position) >= 96:
			return pos
	return Vector2(200, 200)

func _on_player_attacked(tile_pos: Vector2):
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(tile_pos) < 14:
			enemy.take_damage(player.get_attack())
			break

func _on_enemy_died(pos: Vector2, drop: String, enemy_node: Node):
	enemies.erase(enemy_node)
	spawn_drop(pos, drop)
	save_mgr.save_game(player)
	if enemies.is_empty():
		print("Tutti i nemici sconfitti! Rigenerazione tra 10 secondi...")
		get_tree().create_timer(10.0).timeout.connect(respawn_enemies)

func _on_player_hp_changed(current_hp: int, max_hp: int):
	if hp_label:
		hp_label.text = "%d / %d" % [current_hp, max_hp]
	if hp_bar_fill and max_hp > 0:
		hp_bar_fill.size.x = 84.0 * float(current_hp) / float(max_hp)
	if current_hp <= 0:
		player.hp = player.max_hp
		if hp_label:
			hp_label.text = "%d / %d" % [player.max_hp, max_hp]
		if hp_bar_fill:
			hp_bar_fill.size.x = 84.0
		save_mgr.save_game(player)
		game_over_ui_node.show_game_over()

func respawn_enemies():
	print("Nemici rigenerati!")
	spawn_all_enemies()

func spawn_drop(pos: Vector2, item_name: String):
	var pickup = Area2D.new()
	pickup.set_script(ItemPickupScript)
	add_child(pickup)
	pickup.global_position = pos
	pickup.item_name = item_name

func _start_game():
	player.set_process(true)
	_on_player_hp_changed(player.hp, player.max_hp)

func _on_role_chosen(role_id: String):
	player.apply_role(role_id)
	save_mgr.save_game(player)
	_start_game()
