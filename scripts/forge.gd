extends Node2D

var can_interact: bool = true
var player_ref: Node
var forge_ui_ref: Node

func _ready():
	var rect = ColorRect.new()
	rect.color = Color(0.1, 0.2, 0.55)
	rect.size = Vector2(14, 14)
	rect.position = Vector2(-7, -7)
	add_child(rect)

	var label = Label.new()
	label.text = "Forgeria"
	label.add_theme_font_size_override("font_size", 8)
	label.position = Vector2(-20, -20)
	add_child(label)

func setup(player: Node, forge_ui: Node):
	player_ref = player
	forge_ui_ref = forge_ui

func _process(_delta):
	if not can_interact or player_ref == null or forge_ui_ref == null:
		return
	if forge_ui_ref.visible:
		return
	if Input.is_action_just_pressed("interact"):
		if global_position.distance_to(player_ref.global_position) < 24:
			forge_ui_ref.show_forge(player_ref)
