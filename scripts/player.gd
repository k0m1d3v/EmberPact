extends CharacterBody2D

const TILE_SIZE = 16
const MOVE_SPEED = 8.0

signal inventory_changed(inventory: Array)
signal hp_changed(current_hp: int, max_hp: int)
signal attacked(tile_pos: Vector2)

var is_moving := false
var target_position := Vector2.ZERO
var last_direction := Vector2(1, 0)
var attack_cooldown := 0.0
var attack_flash: ColorRect = null
var forge_ref: Node = null
var inv_ref: Node = null
var npc_near: Node = null
var is_in_dialogue: bool = false

var role: String = ""
var inventory: Array = []
var equipped_weapon: Dictionary = {}
var equipped_armor: Dictionary = {}
var hp: int = 50
var max_hp: int = 50
var base_attack: int = 12
var base_defense: int = 3

func _ready():
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	target_position = global_position

	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.texture = load("res://assets/sprites/player.png")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.visible = false

	attack_flash = ColorRect.new()
	attack_flash.color = Color(1.0, 0.9, 0.1, 0.7)
	attack_flash.size = Vector2(14, 14)
	attack_flash.position = Vector2(-7, -7)
	attack_flash.visible = false
	add_child(attack_flash)

func _process(delta):
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if is_in_dialogue:
		return

	var near_forge = forge_ref != null and forge_ref.can_interact and \
		global_position.distance_to(forge_ref.global_position) < 24
	var near_npc = npc_near != null and is_instance_valid(npc_near)
	var inv_open = inv_ref != null and inv_ref.visible

	if Input.is_action_just_pressed("interact"):
		if near_npc:
			npc_near.interact()
		elif not near_forge:
			if inv_open:
				inv_ref.hide()
			elif inv_ref != null:
				inv_ref.show_panel()

	# Space/click: attack only when inventory is closed
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0 and not inv_open:
		attack_cooldown = 0.4
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var diff = get_global_mouse_position() - global_position
			if abs(diff.x) >= abs(diff.y):
				last_direction = Vector2(sign(diff.x), 0)
			else:
				last_direction = Vector2(0, sign(diff.y))
		attacked.emit(global_position + last_direction * TILE_SIZE)
		_show_attack_flash()

	if is_moving:
		global_position = global_position.move_toward(target_position, MOVE_SPEED)
		if global_position == target_position:
			is_moving = false
		return

	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction = Vector2(TILE_SIZE, 0)
		last_direction = Vector2(1, 0)
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2(-TILE_SIZE, 0)
		last_direction = Vector2(-1, 0)
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2(0, TILE_SIZE)
		last_direction = Vector2(0, 1)
	elif Input.is_action_pressed("ui_up"):
		direction = Vector2(0, -TILE_SIZE)
		last_direction = Vector2(0, -1)

	if direction != Vector2.ZERO:
		target_position = global_position + direction
		is_moving = true

func _show_attack_flash():
	attack_flash.position = last_direction * TILE_SIZE + Vector2(-7, -7)
	attack_flash.modulate.a = 0.7
	attack_flash.visible = true
	var tween = create_tween()
	tween.tween_property(attack_flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): attack_flash.visible = false)

func take_damage(amount: int):
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)

func get_defense() -> int:
	return base_defense + equipped_armor.get("defense", 0)

func get_attack() -> int:
	if not equipped_weapon.is_empty():
		return equipped_weapon.get("damage", base_attack)
	return base_attack

func apply_role(role_id: String):
	role = role_id
	match role_id:
		"esploratore":
			max_hp = 50; hp = 50; base_attack = 12; base_defense = 3
		"fabbro":
			max_hp = 40; hp = 40; base_attack = 15; base_defense = 2
		"locandiere":
			max_hp = 65; hp = 65; base_attack = 8; base_defense = 5
	hp_changed.emit(hp, max_hp)

func add_item(item_name: String):
	inventory.append(item_name)
	inventory_changed.emit(inventory)
	QuestManager.on_item_collected(item_name)
	NotificationManager.show("+ " + item_name)
