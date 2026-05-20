extends CharacterBody2D

const TILE_SIZE = 16
const MOVE_SPEED = 8.0

signal inventory_changed(inventory: Array)

var is_moving := false
var target_position := Vector2.ZERO
var inventory: Array = []
var equipped_weapon: Dictionary = {}
var equipped_armor: Dictionary = {}
var hp: int = 50
var max_hp: int = 50
var base_defense: int = 3

func _ready():
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	target_position = global_position

func _process(_delta):
	if is_moving:
		global_position = global_position.move_toward(target_position, MOVE_SPEED)
		if global_position == target_position:
			is_moving = false
		return

	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction = Vector2(TILE_SIZE, 0)
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2(-TILE_SIZE, 0)
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2(0, TILE_SIZE)
	elif Input.is_action_pressed("ui_up"):
		direction = Vector2(0, -TILE_SIZE)

	if direction != Vector2.ZERO:
		target_position = global_position + direction
		is_moving = true

func get_defense() -> int:
	return base_defense + equipped_armor.get("defense", 0)

func get_attack() -> int:
	if not equipped_weapon.is_empty():
		return equipped_weapon.get("damage", 12)
	return 12

func add_item(item_name: String):
	inventory.append(item_name)
	print("Raccolto: %s" % item_name)
	print("Inventario: ", inventory)
	inventory_changed.emit(inventory)
