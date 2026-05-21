extends Node2D

const EnemyScene = preload("res://scenes/enemies/enemy.tscn")
const ItemPickupScript = preload("res://scripts/item_pickup.gd")
const ForgeUIScript = preload("res://scripts/forge_ui.gd")
const ForgeScript = preload("res://scripts/forge.gd")
const GameOverUIScript = preload("res://scripts/game_over_ui.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")
const RoleSelectUIScript = preload("res://scripts/role_select_ui.gd")

@onready var tilemap = $TileMapLayer
@onready var player = $Player

var inventory_ui: Node = null
var forge_ui_node: Node = null
var forge_node: Node = null
var game_over_ui_node: Node = null
var role_select_ui: Node = null
var save_mgr: Node = null
var hp_bar_fill: ColorRect = null
var hp_text_label: Label = null
var enemies: Array = []
var _respawn_timer: float = 0.0

const RESPAWN_INTERVAL := 30.0
const MAX_ENEMIES := 5

# ── Lifecycle ────────────────────────────────────────────────────────

func _ready():
	_register_actions()
	_setup_tilemap()
	_setup_common_ui()
	_setup_zone()
	_init_player()

# ── Virtual ──────────────────────────────────────────────────────────

func get_zone_name() -> String:
	return ""

func get_scene_path() -> String:
	return ""

func _setup_tilemap():
	pass

func _setup_zone():
	pass

func get_spawn_pos(spawn_id: String) -> Vector2:
	return Vector2.ZERO

func _on_first_run():
	player.apply_role("esploratore")
	PlayerData.save_from_player(player)
	_start_game()

func _spawn_zone_enemies():
	pass

# ── Common setup ─────────────────────────────────────────────────────

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
		var mb = InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mb)
	if not InputMap.has_action("wasd_setup"):
		InputMap.add_action("wasd_setup")
		for pair in [["ui_right", KEY_D], ["ui_left", KEY_A], ["ui_down", KEY_S], ["ui_up", KEY_W]]:
			var ev3 = InputEventKey.new()
			ev3.keycode = pair[1]
			InputMap.action_add_event(pair[0], ev3)

func _setup_common_ui():
	inventory_ui = CanvasLayer.new()
	inventory_ui.name = "InventoryUI"
	inventory_ui.set_script(load("res://scripts/inventory_ui.gd"))
	add_child(inventory_ui)
	inventory_ui.player_ref = player
	player.inventory_changed.connect(inventory_ui.update_display)
	player.inv_ref = inventory_ui

	forge_ui_node = CanvasLayer.new()
	forge_ui_node.set_script(ForgeUIScript)
	add_child(forge_ui_node)

	game_over_ui_node = CanvasLayer.new()
	game_over_ui_node.set_script(GameOverUIScript)
	game_over_ui_node.layer = 10
	add_child(game_over_ui_node)

	save_mgr = Node.new()
	save_mgr.set_script(SaveManagerScript)
	add_child(save_mgr)

	_setup_hp_bar()

	player.hp_changed.connect(_on_player_hp_changed)
	player.attacked.connect(_on_player_attacked)
	player.inventory_changed.connect(func(_inv): _save())

func _setup_hp_bar():
	var hp_layer = CanvasLayer.new()
	hp_layer.layer = 1
	add_child(hp_layer)

	var hbox = HBoxContainer.new()
	hbox.position = Vector2(8, 8)
	hbox.add_theme_constant_override("separation", 4)
	hp_layer.add_child(hbox)

	var heart_icon = TextureRect.new()
	heart_icon.texture = load("res://assets/ui/hp_heart_full.png")
	heart_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	heart_icon.custom_minimum_size = Vector2(16, 16)
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(heart_icon)

	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.15, 0.08, 0.08, 0.85)
	bar_bg.custom_minimum_size = Vector2(80, 10)
	hbox.add_child(bar_bg)

	hp_bar_fill = ColorRect.new()
	hp_bar_fill.color = Color("#C1121F")
	hp_bar_fill.size = Vector2(80, 10)
	bar_bg.add_child(hp_bar_fill)

	hp_text_label = Label.new()
	hp_text_label.add_theme_font_size_override("font_size", 9)
	hp_text_label.add_theme_color_override("font_color", Color("#F5E6C8"))
	hbox.add_child(hp_text_label)

func _init_player():
	if not PlayerData.is_initialized():
		if save_mgr.has_save() and save_mgr.load_game(player):
			var target = PlayerData.current_scene
			var mine = get_scene_path()
			if target != "" and mine != "" and target != mine:
				SceneManager.change_scene(target, PlayerData.spawn_point)
				return
			var sp = get_spawn_pos(PlayerData.spawn_point)
			if sp != Vector2.ZERO:
				player.global_position = sp
				player.target_position = sp
			_start_game()
		else:
			player.set_process(false)
			_on_first_run()
	else:
		PlayerData.apply_to_player(player)
		var sp = get_spawn_pos(PlayerData.spawn_point)
		if sp != Vector2.ZERO:
			player.global_position = sp
			player.target_position = sp
		_start_game()

func _start_game():
	player.set_process(true)
	_on_player_hp_changed(player.hp, player.max_hp)
	PlayerData.current_scene = get_scene_path()
	if get_zone_name() != "":
		NotificationManager.notify("Zona: " + get_zone_name())

# ── Process ──────────────────────────────────────────────────────────

func _process(delta):
	if enemies.size() < MAX_ENEMIES:
		_respawn_timer += delta
		if _respawn_timer >= RESPAWN_INTERVAL:
			_respawn_timer = 0.0
			_spawn_zone_enemies()

# ── Enemy helpers ────────────────────────────────────────────────────

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

func rand_pos(min_dist: float = 96.0, range_tiles: int = 20) -> Vector2:
	for _i in range(40):
		var tx = randi_range(-range_tiles, range_tiles)
		var ty = randi_range(-range_tiles, range_tiles)
		var pos = Vector2(tx * 16, ty * 16)
		if pos.distance_to(player.global_position) >= min_dist:
			return pos
	return Vector2(200, 200)

func add_exit(center: Vector2, size: Vector2, target_scene: String, spawn_id: String,
		condition_cb: Callable = Callable()):
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = size
	col.shape = box
	area.position = center
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(func(body):
		if body == player:
			if condition_cb.is_valid() and not condition_cb.call():
				return
			SceneManager.change_scene(target_scene, spawn_id))

func spawn_drop(pos: Vector2, item_name: String):
	var pickup = Area2D.new()
	pickup.set_script(ItemPickupScript)
	add_child(pickup)
	pickup.global_position = pos
	pickup.item_name = item_name

func make_npc(npc_name_str: String, pos: Vector2, color: Color) -> Node:
	var npc = Node2D.new()
	npc.set_script(load("res://scripts/npc.gd"))
	npc.npc_name = npc_name_str
	npc.sprite_color = color
	npc.global_position = pos
	add_child(npc)
	return npc

# ── Signal handlers ──────────────────────────────────────────────────

func _on_player_attacked(tile_pos: Vector2):
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(tile_pos) < 14:
			enemy.take_damage(player.get_attack())
			break

func _on_enemy_died(pos: Vector2, drop: String, enemy_node: Node):
	enemies.erase(enemy_node)
	QuestManager.on_enemy_killed(enemy_node.enemy_name)
	spawn_drop(pos, drop)
	_save()

func _on_player_hp_changed(current_hp: int, max_hp: int):
	if hp_bar_fill != null and max_hp > 0:
		hp_bar_fill.size.x = 80.0 * float(max(current_hp, 0)) / float(max_hp)
	if hp_text_label != null:
		hp_text_label.text = "%d/%d" % [max(current_hp, 0), max_hp]
	if current_hp <= 0:
		player.hp = player.max_hp
		if hp_bar_fill != null:
			hp_bar_fill.size.x = 80.0
		if hp_text_label != null:
			hp_text_label.text = "%d/%d" % [player.max_hp, player.max_hp]
		_save()
		game_over_ui_node.show_game_over()

func _save():
	if save_mgr and PlayerData.is_initialized():
		PlayerData.save_from_player(player)
		save_mgr.save_game(player)

func set_camera_limits(left: int, top: int, right: int, bottom: int):
	var cam = player.get_node_or_null("Camera2D")
	if cam:
		cam.limit_left = left
		cam.limit_top = top
		cam.limit_right = right
		cam.limit_bottom = bottom
		cam.position_smoothing_enabled = true
