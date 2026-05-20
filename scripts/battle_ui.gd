extends CanvasLayer

signal action_chosen(action: String)

@onready var log_label = $Control/VBoxContainer/BattleLog
@onready var attack_btn = $Control/VBoxContainer/HBoxContainer/Attacca
@onready var flee_btn = $Control/VBoxContainer/HBoxContainer/Fuggi

var use_item_btn: Button = null

func _ready():
	attack_btn.pressed.connect(_on_attack)
	flee_btn.pressed.connect(_on_flee)

	use_item_btn = Button.new()
	use_item_btn.text = "Usa oggetto"
	use_item_btn.pressed.connect(_on_use_item)
	attack_btn.get_parent().add_child(use_item_btn)

	hide()

func show_battle(player_hp: int, player_max_hp: int, enemy_name: String, enemy_hp: int):
	show()
	set_buttons_enabled(true)
	update_log("⚔️ %s appare!\nHP: %d/%d | HP nemico: %d" % [enemy_name, player_hp, player_max_hp, enemy_hp])

func update_log(text: String):
	log_label.text = text

func set_buttons_enabled(enabled: bool):
	attack_btn.disabled = not enabled
	flee_btn.disabled = not enabled
	if use_item_btn != null:
		use_item_btn.disabled = not enabled

func _on_attack():
	action_chosen.emit("attack")

func _on_flee():
	action_chosen.emit("flee")

func _on_use_item():
	action_chosen.emit("use_item")
