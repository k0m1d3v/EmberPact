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
	_setup_visuals()

const SPRITE_MAP = {
	"Slime":    "res://assets/sprites/enemy_slime.png",
	"Goblin":   "res://assets/sprites/enemy_goblin.png",
	"Orco":     "res://assets/sprites/enemy_orc.png",
	"Scheletro":"res://assets/sprites/enemy_skeleton.png",
	"Lupo":     "res://assets/sprites/enemy_wolf.png",
}

func _setup_visuals():
	var color_rect = get_node_or_null("ColorRect")
	var sprite_path = SPRITE_MAP.get(enemy_name, "")
	if sprite_path != "":
		if color_rect:
			color_rect.visible = false
		var sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
	elif color_rect:
		color_rect.color = Color("#E63946")

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
