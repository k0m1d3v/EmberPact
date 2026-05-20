extends CanvasLayer

signal action_chosen(action: String)

@onready var log_label = $Control/VBoxContainer/BattleLog
@onready var attack_btn = $Control/VBoxContainer/HBoxContainer/Attacca
@onready var flee_btn = $Control/VBoxContainer/HBoxContainer/Fuggi

func _ready():
	attack_btn.pressed.connect(_on_attack)
	flee_btn.pressed.connect(_on_flee)
	hide()

func show_battle(player_hp: int, enemy_name: String, enemy_hp: int):
	show()
	set_buttons_enabled(true)
	update_log("⚔️ %s appare!\nTuoi HP: %d | HP nemico: %d" % [enemy_name, player_hp, enemy_hp])

func update_log(text: String):
	log_label.text = text

func set_buttons_enabled(enabled: bool):
	attack_btn.disabled = !enabled
	flee_btn.disabled = !enabled

func _on_attack():
	action_chosen.emit("attack")

func _on_flee():
	action_chosen.emit("flee")
