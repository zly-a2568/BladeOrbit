extends Label
class_name AttackingNumber

enum MoveMode{
	GRAVITY,
	STRAIGHT
}

var origin_pos:Vector2=Vector2.ZERO
var velocity:Vector2=Vector2.ZERO
var valid:bool=true
var motion_mode:MoveMode=MoveMode.STRAIGHT
var timer:float=0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position=origin_pos
	if motion_mode==MoveMode.GRAVITY:
		velocity.y=randf_range(-400,0)
		velocity.x=randf_range(-30,30)
		var t = create_tween()
		t.tween_property(self,"scale",Vector2.ONE*2.0,0.35).set_ease(Tween.EASE_OUT)
		t.tween_property(self,"scale",Vector2.ZERO,0.35).set_ease(Tween.EASE_IN)
	else:
		var player:Player=get_tree().get_first_node_in_group("player")
		velocity=(origin_pos-player.global_position).normalized()*randf_range(600,800)

func destroy():
	var t=create_tween()
	t.tween_property(self,"modulate:a",0.0,0.5)
	t.tween_callback(queue_free)

func set_motion_mode(mode:MoveMode):
	motion_mode=mode

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer+=delta
	if motion_mode==MoveMode.GRAVITY:
		velocity.y+=9.8
	else:
		velocity*=0.9
	if timer>=0.7:
		if valid:
			valid=false
			destroy()
	position+=velocity*delta
	
		
