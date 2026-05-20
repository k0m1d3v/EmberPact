extends Node

signal battle_ended(won: bool, was_defeat: bool)

var player_ref: Node
var enemy_ref: Node
var battle_ui: Node
var in_battle := false

var player_attack := 12

func start_battle(player: Node, enemy: Node, ui: Node):
	player_ref = player
	enemy_ref = enemy
	in_battle = true

	battle_ui = ui
	if not battle_ui.has_method("show_battle"):
		battle_ui = ui.get_tree().get_root().find_child("BattleUI", true, false)

	var ename = enemy_ref.enemy_name if enemy_ref.has_method("take_damage") else "Nemico"
	var ehp = enemy_ref.hp if enemy_ref.has_method("take_damage") else 30

	battle_ui.show_battle(player_ref.hp, player_ref.max_hp, ename, ehp)
	battle_ui.action_chosen.connect(_on_action)

func _on_action(action: String):
	if not in_battle:
		return
	battle_ui.set_buttons_enabled(false)

	var ename = enemy_ref.enemy_name if enemy_ref.has_method("take_damage") else "Nemico"

	if action == "attack":
		var dmg = 0
		var ehp = 0
		if enemy_ref.has_method("take_damage"):
			var actual_attack = player_ref.get_attack() if player_ref.has_method("get_attack") else player_attack
			dmg = enemy_ref.take_damage(actual_attack)
			ehp = enemy_ref.hp
		else:
			dmg = player_attack

		var battle_log = "Hai inflitto %d danni! (HP nemico: %d)" % [dmg, ehp]

		var dead = enemy_ref.is_dead() if enemy_ref.has_method("is_dead") else ehp <= 0
		if dead:
			battle_log += "\n💀 %s sconfitto!" % ename
			end_battle(true)
			battle_ui.update_log(battle_log)
			return

		battle_log += _enemy_counterattack(ename)
		if player_ref.hp <= 0:
			battle_log += "\n💀 Sei stato sconfitto..."
			end_battle(false, true)
			battle_ui.update_log(battle_log)
			return

		battle_ui.update_log(battle_log)
		battle_ui.set_buttons_enabled(true)

	elif action == "use_item":
		var usable = _get_usable_items()
		if usable.is_empty():
			battle_ui.update_log("Nessun oggetto utilizzabile.")
			battle_ui.set_buttons_enabled(true)
			return

		var potion = usable[0]
		var heal = potion.get("heal", 0)
		player_ref.hp = min(player_ref.hp + heal, player_ref.max_hp)
		var idx = player_ref.inventory.find(potion)
		if idx >= 0:
			player_ref.inventory.remove_at(idx)
		player_ref.inventory_changed.emit(player_ref.inventory)

		var battle_log = "Usato %s! HP: %d/%d" % [potion.get("name", "?"), player_ref.hp, player_ref.max_hp]
		battle_log += _enemy_counterattack(ename)
		if player_ref.hp <= 0:
			battle_log += "\n💀 Sei stato sconfitto..."
			end_battle(false, true)
			battle_ui.update_log(battle_log)
			return

		battle_ui.update_log(battle_log)
		battle_ui.set_buttons_enabled(true)

	elif action == "flee":
		battle_ui.update_log("Sei fuggito!")
		end_battle(false, false)

func _enemy_counterattack(ename: String) -> String:
	var enemy_atk = enemy_ref.attack if enemy_ref.has_method("take_damage") else 8
	var defense = player_ref.get_defense() if player_ref.has_method("get_defense") else 3
	var dmg = max(1, enemy_atk - defense)
	player_ref.hp -= dmg
	return "\n%s ti attacca per %d! (HP: %d/%d)" % [ename, dmg, max(0, player_ref.hp), player_ref.max_hp]

func _get_usable_items() -> Array:
	var usable: Array = []
	if player_ref == null:
		return usable
	for item in player_ref.inventory:
		if item is Dictionary and item.get("type") == "potion":
			usable.append(item)
	return usable

func end_battle(won: bool, was_defeat: bool = false):
	in_battle = false
	if not won:
		player_ref.hp = player_ref.max_hp
	battle_ended.emit(won, was_defeat)
	await get_tree().create_timer(2.0).timeout
	battle_ui.hide()
	if won and is_instance_valid(enemy_ref):
		enemy_ref.queue_free()
	if battle_ui.action_chosen.is_connected(_on_action):
		battle_ui.action_chosen.disconnect(_on_action)
