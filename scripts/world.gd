extends Node2D

@onready var tilemap = $TileMapLayer
@onready var player = $Player

const EnemyScene = preload("res://scenes/enemies/enemy.tscn")
const BattleUIScene = preload("res://scenes/ui/battle_ui.tscn")
const ItemPickupScript = preload("res://scripts/item_pickup.gd")

var battle_manager: Node
var battle_ui_instance: Node
var in_battle := false
var enemy_instance: Node = null

func _ready():
	generate_world()
	spawn_enemy(Vector2(128, 64))
	
	battle_ui_instance = BattleUIScene.instantiate()
	add_child(battle_ui_instance)
	
	battle_manager = Node.new()
	battle_manager.set_script(load("res://scripts/battle_manager.gd"))
	add_child(battle_manager)
	battle_manager.battle_ended.connect(_on_battle_ended)

func generate_world():
	# Crea il tileset via codice
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	
	# Crea una texture verde 16x16 per il terreno
	var image = Image.create(16, 16, false, Image.FORMAT_RGB8)
	image.fill(Color(0.29, 0.51, 0.24))  # verde erba
	
	# Bordo più scuro per dare profondità
	for x in range(16):
		for y in range(16):
			if x == 0 or y == 0:
				image.set_pixel(x, y, Color(0.20, 0.38, 0.16))
	
	var texture = ImageTexture.create_from_image(image)
	
	# Aggiungi source al tileset
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(16, 16)
	source.create_tile(Vector2i(0, 0))
	tileset.add_source(source, 0)
	
	tilemap.tile_set = tileset
	
	# Genera la mappa
	for x in range(-20, 20):
		for y in range(-20, 20):
			tilemap.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

func spawn_enemy(pos: Vector2):
	var enemy = EnemyScene.instantiate()
	enemy.global_position = pos
	add_child(enemy)
	enemy_instance = enemy
	print("Enemy script: ", enemy.get_script())
	print("Enemy class: ", enemy.get_class())

func _process(_delta):
	if in_battle:
		return
	check_player_enemy_collision()

func check_player_enemy_collision():
	if enemy_instance == null or not is_instance_valid(enemy_instance):
		return
	var dist = player.global_position.distance_to(enemy_instance.global_position)
	if dist < 20:
		start_battle(enemy_instance)

func start_battle(enemy: Node):
	in_battle = true
	battle_manager.start_battle(player, enemy, battle_ui_instance)

func _on_battle_ended(won: bool):
	in_battle = false
	if won:
		print("Vittoria!")
		if enemy_instance != null and is_instance_valid(enemy_instance):
			spawn_drop(enemy_instance.global_position, enemy_instance.drop_item)
	else:
		print("Sconfitta o fuga")

func spawn_drop(pos: Vector2, item_name: String):
	var pickup = Area2D.new()
	pickup.set_script(ItemPickupScript)
	add_child(pickup)
	pickup.global_position = pos
	pickup.item_name = item_name
