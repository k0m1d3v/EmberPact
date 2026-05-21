extends Node

signal quest_accepted(quest: Dictionary)
signal quest_progress_updated(quest: Dictionary)
signal quest_completed(quest: Dictionary)

const DEFINITIONS: Array = [
	{
		"id": "quest_01",
		"title": "Prova del Fuoco",
		"desc": "Uccidi 3 Slime per dimostrare il tuo valore.",
		"objective_type": "kill",
		"objective_target": "Slime",
		"objective_count": 3,
		"reward_gold": 10,
		"reward_item": "",
		"giver": "Anziano",
	},
	{
		"id": "quest_02",
		"title": "Rifornimento della Locanda",
		"desc": "Porta 2 Pellicce a Marta in locanda.",
		"objective_type": "collect",
		"objective_target": "Pelliccia",
		"objective_count": 2,
		"reward_gold": 0,
		"reward_item": "riposo_gratuito",
		"giver": "Marta",
	},
	{
		"id": "quest_03",
		"title": "L'Acciaio del Fabbro",
		"desc": "Porta 3 Frammenti di ferro ad Aldric in città.",
		"objective_type": "deliver",
		"objective_target": "Frammento di ferro",
		"objective_count": 3,
		"reward_gold": 0,
		"reward_item": "ricetta_martello",
		"giver": "Aldric",
	},
]

var available: Array = []
var active: Array = []
var completed: Array = []

func _ready():
	_init_available()

func _init_available():
	available = []
	for q in DEFINITIONS:
		available.append(q["id"])

func get_def(quest_id: String) -> Dictionary:
	for q in DEFINITIONS:
		if q["id"] == quest_id:
			return q
	return {}

func get_active_quest(quest_id: String) -> Dictionary:
	for q in active:
		if q["id"] == quest_id:
			return q
	return {}

func is_active(quest_id: String) -> bool:
	return not get_active_quest(quest_id).is_empty()

func is_done(quest_id: String) -> bool:
	return quest_id in completed

func accept_quest(quest_id: String):
	if quest_id not in available or is_done(quest_id):
		return
	available.erase(quest_id)
	var state = get_def(quest_id).duplicate(true)
	state["objective_current"] = 0
	state["completed"] = false
	active.append(state)
	quest_accepted.emit(state)
	NotificationManager.notify("Quest accettata: " + state["title"])

func on_enemy_killed(enemy_name: String):
	_update_progress("kill", enemy_name)

func on_item_collected(item_name: String):
	_update_progress("collect", item_name)

func on_item_delivered(item_name: String):
	_update_progress("deliver", item_name)

func _update_progress(obj_type: String, target: String):
	for q in active:
		if q.get("completed", false):
			continue
		if q["objective_type"] == obj_type and q["objective_target"] == target:
			q["objective_current"] = min(q["objective_current"] + 1, q["objective_count"])
			quest_progress_updated.emit(q)
			if q["objective_current"] >= q["objective_count"]:
				_finish_quest(q)
			return

func _finish_quest(quest: Dictionary):
	quest["completed"] = true
	active.erase(quest)
	completed.append(quest["id"])
	if quest["reward_gold"] > 0:
		var pl = _find_player()
		if pl:
			for _i in quest["reward_gold"]:
				pl.add_item("Moneta di rame")
	if quest["reward_item"] == "ricetta_martello":
		PlayerData.hammer_recipe_unlocked = true
	quest_completed.emit(quest)
	NotificationManager.notify("Quest completata: " + quest["title"] + "!")

func _find_player() -> Node:
	var sc = Engine.get_main_loop().current_scene
	return sc.get_node_or_null("Player") if sc else null

func progress_text(quest_id: String) -> String:
	var q = get_active_quest(quest_id)
	if q.is_empty():
		return ""
	return "%s: %d/%d" % [q["objective_target"], q["objective_current"], q["objective_count"]]

func reset():
	available = []
	active = []
	completed = []
	_init_available()
