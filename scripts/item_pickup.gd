extends Area2D

var item_name: String = "Frammento di ferro"

func _ready():
	var rect = ColorRect.new()
	rect.color = Color(1.0, 0.85, 0.0)
	rect.size = Vector2(12, 12)
	rect.position = Vector2(-6, -6)
	add_child(rect)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.has_method("add_item"):
		body.add_item(item_name)
		queue_free()
