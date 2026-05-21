extends Node

const SAVE_PATH = "user://save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(player: Node):
	PlayerData.save_from_player(player)
	var data = {
		"role":                    PlayerData.role,
		"hp":                      PlayerData.hp,
		"max_hp":                  PlayerData.max_hp,
		"base_attack":             PlayerData.base_attack,
		"base_defense":            PlayerData.base_defense,
		"inventory":               PlayerData.inventory,
		"equipped_weapon":         PlayerData.equipped_weapon,
		"equipped_armor":          PlayerData.equipped_armor,
		"current_scene":           PlayerData.current_scene,
		"spawn_point":             PlayerData.spawn_point,
		"hammer_recipe_unlocked":  PlayerData.hammer_recipe_unlocked,
		"quests_available":        QuestManager.available,
		"quests_active":           QuestManager.active,
		"quests_completed":        QuestManager.completed,
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

	PlayerData.role           = data["role"]
	PlayerData.hp             = data.get("hp", 50)
	PlayerData.max_hp         = data.get("max_hp", 50)
	PlayerData.base_attack    = data.get("base_attack", 12)
	PlayerData.base_defense   = data.get("base_defense", 3)
	PlayerData.inventory      = data.get("inventory", [])
	PlayerData.equipped_weapon = data.get("equipped_weapon", {})
	PlayerData.equipped_armor  = data.get("equipped_armor", {})
	PlayerData.current_scene  = data.get("current_scene", "res://scenes/world/town.tscn")
	PlayerData.spawn_point    = data.get("spawn_point", "default")
	PlayerData.hammer_recipe_unlocked = data.get("hammer_recipe_unlocked", false)

	if data.has("quests_available"):
		QuestManager.available = data["quests_available"].duplicate(true)
	if data.has("quests_active"):
		QuestManager.active = data["quests_active"].duplicate(true)
	if data.has("quests_completed"):
		QuestManager.completed = data["quests_completed"].duplicate(true)

	PlayerData.apply_to_player(player)
	player.inventory_changed.emit(player.inventory)
	return true

func delete_save():
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("save.json")
