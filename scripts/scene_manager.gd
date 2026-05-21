extends CanvasLayer

var _fade: ColorRect
var _pending_scene: String = ""
var _pending_spawn: String = "default"
var _busy: bool = false

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.anchor_right = 1.0
	_fade.anchor_bottom = 1.0
	_fade.modulate.a = 0.0
	add_child(_fade)

func change_scene(scene_path: String, spawn_id: String = "default"):
	if _busy:
		return
	_busy = true
	_pending_scene = scene_path
	_pending_spawn = spawn_id

	var current = get_tree().current_scene
	if current:
		var pl = current.get_node_or_null("Player")
		if pl:
			PlayerData.save_from_player(pl)
	PlayerData.current_scene = scene_path
	PlayerData.spawn_point = spawn_id

	var tw = create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.3)
	tw.tween_callback(_do_change)

func _do_change():
	get_tree().change_scene_to_file(_pending_scene)
	get_tree().process_frame.connect(_frame1, CONNECT_ONE_SHOT)

func _frame1():
	get_tree().process_frame.connect(_frame2, CONNECT_ONE_SHOT)

func _frame2():
	var tw = create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): _busy = false)
