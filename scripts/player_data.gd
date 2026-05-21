extends Node

var role: String = ""
var hp: int = 50
var max_hp: int = 50
var base_attack: int = 12
var base_defense: int = 3
var inventory: Array = []
var equipped_weapon: Dictionary = {}
var equipped_armor: Dictionary = {}
var current_scene: String = "res://scenes/world/town.tscn"
var spawn_point: String = "default"
var hammer_recipe_unlocked: bool = false

func is_initialized() -> bool:
	return role != ""

func save_from_player(player: Node):
	role = player.role
	hp = player.hp
	max_hp = player.max_hp
	base_attack = player.base_attack
	base_defense = player.base_defense
	inventory = player.inventory.duplicate(true)
	equipped_weapon = player.equipped_weapon.duplicate(true)
	equipped_armor = player.equipped_armor.duplicate(true)

func apply_to_player(player: Node):
	player.role = role
	player.hp = hp
	player.max_hp = max_hp
	player.base_attack = base_attack
	player.base_defense = base_defense
	player.inventory = inventory.duplicate(true)
	player.equipped_weapon = equipped_weapon.duplicate(true)
	player.equipped_armor = equipped_armor.duplicate(true)

func reset():
	role = ""
	hp = 50
	max_hp = 50
	base_attack = 12
	base_defense = 3
	inventory = []
	equipped_weapon = {}
	equipped_armor = {}
	current_scene = "res://scenes/world/town.tscn"
	spawn_point = "default"
	hammer_recipe_unlocked = false
