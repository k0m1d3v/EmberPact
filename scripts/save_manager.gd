extends Node

const SAVE_PATH = "user://save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(player: Node):
	var data = {
		"role": player.role,
		"hp": player.hp,
		"max_hp": player.max_hp,
		"base_attack": player.base_attack,
		"base_defense": player.base_defense,
		"inventory": player.inventory,
		"equipped_weapon": player.equipped_weapon,
		"equipped_armor": player.equipped_armor,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game(player: Node) -> bool:
	if not has_save():
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary or data.get("role", "") == "":
		return false
	player.role = data["role"]
	player.hp = data.get("hp", 50)
	player.max_hp = data.get("max_hp", 50)
	player.base_attack = data.get("base_attack", 12)
	player.base_defense = data.get("base_defense", 3)
	player.inventory = data.get("inventory", [])
	player.equipped_weapon = data.get("equipped_weapon", {})
	player.equipped_armor = data.get("equipped_armor", {})
	print("Caricato. Ruolo: %s | HP: %d/%d" % [player.role, player.hp, player.max_hp])
	player.inventory_changed.emit(player.inventory)
	return true

func delete_save():
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("save.json")
