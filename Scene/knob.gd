extends TouchScreenButton


var pos_delta: Vector2 = Vector2(13.0, 13.0)
var max_offset: float = 5.0
var pressing: bool = false
var origin_pos: Vector2 = Vector2.ZERO
var fg_pos: Vector2 = Vector2.ZERO
@onready var game: Node2D = $"../../.."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var c: Dictionary = Config.data["knob"]
	pos_delta = Vector2(c["pos_delta"][0], c["pos_delta"][1])
	max_offset = c["max_offset"]

func _input(event: InputEvent) -> void:
	if not game.started:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			position=event.position-pos_delta
			origin_pos=global_position
			create_tween().tween_property(self,"modulate:a",1.0,0.1)
		else:
			create_tween().tween_property(self,"modulate:a",0.0,0.1)
			Input.action_release("ui_right")
			Input.action_release("ui_left")
			Input.action_release("ui_up")
			Input.action_release("ui_down")
	if event is InputEventScreenDrag:
		fg_pos=event.position-pos_delta
		var delta:Vector2=(fg_pos-origin_pos).limit_length(max_offset)
		global_position=origin_pos+delta
		var movement:=delta.normalized()
		if delta.x<0:
			Input.action_release("ui_right")
			Input.action_press("ui_left",abs(movement.x))
		if delta.x>0:
			Input.action_release("ui_left")
			Input.action_press("ui_right",abs(movement.x))
		if delta.y<0:
			Input.action_release("ui_down")
			Input.action_press("ui_up",abs(movement.y))
		if delta.y>0:
			Input.action_release("ui_up")
			Input.action_press("ui_down",abs(movement.y))
		
