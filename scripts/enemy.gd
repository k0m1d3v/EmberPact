extends CharacterBody2D

signal died(pos: Vector2, drop: String, enemy: Node)

var hp := 30
var max_hp := 30
var attack := 8
var defense := 2
var enemy_name := "Slime"
var drop_item := "Frammento di ferro"

var player_ref: Node = null
var move_timer := 0.0
var attack_timer := 0.0

const MOVE_INTERVAL := 0.6
const ATTACK_INTERVAL := 1.2
const AGGRO_RANGE := 80.0
const TILE_SIZE := 16

func _ready():
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))

func take_damage(amount: int) -> int:
	var damage = max(1, amount - defense)
	hp -= damage
	if hp <= 0:
		died.emit(global_position, drop_item, self)
		queue_free()
	return damage

func is_dead() -> bool:
	return hp <= 0

func _process(delta):
	if player_ref == null or hp <= 0 or player_ref.role == "":
		return

	var dist = global_position.distance_to(player_ref.global_position)

	move_timer += delta
	if move_timer >= MOVE_INTERVAL:
		move_timer = 0.0
		if dist <= AGGRO_RANGE and dist > TILE_SIZE * 1.2:
			var diff = player_ref.global_position - global_position
			var step: Vector2
			if abs(diff.x) >= abs(diff.y):
				step = Vector2(sign(diff.x) * TILE_SIZE, 0)
			else:
				step = Vector2(0, sign(diff.y) * TILE_SIZE)
			global_position += step

	attack_timer += delta
	if attack_timer >= ATTACK_INTERVAL:
		attack_timer = 0.0
		if dist <= TILE_SIZE * 1.5:
			var dmg = max(1, attack - player_ref.get_defense())
			player_ref.take_damage(dmg)
