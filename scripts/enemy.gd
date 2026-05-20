extends CharacterBody2D

var hp := 30
var max_hp := 30
var attack := 8
var defense := 2
var enemy_name := "Slime"
var drop_item := "Frammento di ferro"

func take_damage(amount: int) -> int:
	var damage = max(1, amount - defense)
	hp -= damage
	return damage

func is_dead() -> bool:
	return hp <= 0
