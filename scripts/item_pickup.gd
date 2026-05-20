extends Area2D

var item_name: String = "Frammento di ferro"

func _ready():
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/item_pickup.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

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
