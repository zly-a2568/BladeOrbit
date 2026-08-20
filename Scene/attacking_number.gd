extends Label

var origin_pos:Vector2=Vector2.ZERO
var velocity:Vector2=Vector2.ZERO
var valid:bool=true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position=origin_pos
	velocity.x=randf_range(-30,30)
	velocity.y=randf_range(-400,0)

func destroy():
	var t=create_tween()
	t.tween_property(self,"modulate:a",0.0,0.2)
	t.tween_callback(queue_free)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity.y+=9.8
	position+=velocity*delta
	if (position.y-origin_pos.y)>40:
		if valid:
			valid=false
			destroy()
