extends Node

signal battle_ended(won: bool)

var player_ref: Node
var enemy_ref: Node
var battle_ui: Node
var in_battle := false

var player_hp := 50
var player_max_hp := 50
var player_attack := 12
var player_defense := 3

func start_battle(player: Node, enemy: Node, ui: Node):
	player_ref = player
	enemy_ref = enemy
	in_battle = true
	
	battle_ui = ui
	if not battle_ui.has_method("show_battle"):
		battle_ui = ui.get_tree().get_root().find_child("BattleUI", true, false)
	
	var ename = "Nemico"
	var ehp = 30
	if enemy_ref.has_method("take_damage"):
		ename = enemy_ref.enemy_name
		ehp = enemy_ref.hp
	
	battle_ui.show_battle(player_hp, ename, ehp)
	battle_ui.action_chosen.connect(_on_action)

func _on_action(action: String):
	if not in_battle:
		return
	battle_ui.set_buttons_enabled(false)
	
	var ename = "Nemico"
	if enemy_ref.has_method("take_damage"):
		ename = enemy_ref.enemy_name
	
	if action == "attack":
		var dmg = 0
		var ehp = 0
		
		if enemy_ref.has_method("take_damage"):
			var actual_attack = player_ref.get_attack() if player_ref != null and player_ref.has_method("get_attack") else player_attack
			dmg = enemy_ref.take_damage(actual_attack)
			ehp = enemy_ref.hp
		else:
			dmg = player_attack
			ehp = 0
		
		var battle_log = "Hai inflitto %d danni! (HP nemico: %d)" % [dmg, ehp]
		
		var dead = false
		if enemy_ref.has_method("is_dead"):
			dead = enemy_ref.is_dead()
		else:
			dead = ehp <= 0
		
		if dead:
			battle_log += "\n💀 %s sconfitto!" % ename
			end_battle(true)
			battle_ui.update_log(battle_log)
			return
		
		var enemy_atk = 8
		var enemy_def = 2
		if enemy_ref.has_method("take_damage"):
			enemy_atk = enemy_ref.attack
			enemy_def = enemy_ref.defense
		
		var enemy_dmg = max(1, enemy_atk - player_defense)
		player_hp -= enemy_dmg
		battle_log += "\n%s ti attacca per %d! (Tuoi HP: %d)" % [ename, enemy_dmg, player_hp]
		
		if player_hp <= 0:
			battle_log += "\n💀 Sei stato sconfitto..."
			end_battle(false)
			battle_ui.update_log(battle_log)
			return
		
		battle_ui.update_log(battle_log)
		battle_ui.set_buttons_enabled(true)
	
	elif action == "flee":
		battle_ui.update_log("Sei fuggito!")
		end_battle(false)

func end_battle(won: bool):
	in_battle = false
	battle_ended.emit(won)
	await get_tree().create_timer(2.0).timeout
	battle_ui.hide()
	if won and is_instance_valid(enemy_ref):
		enemy_ref.queue_free()
	if battle_ui.action_chosen.is_connected(_on_action):
		battle_ui.action_chosen.disconnect(_on_action)
