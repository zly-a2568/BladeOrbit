extends Enemy
class_name Bat

const SPEED = 60.0
var player:CharacterBody2D


func _ready() -> void:
	super()
	player=get_tree().get_first_node_in_group("player")
	

func _physics_process(delta: float) -> void:
	super(delta)
	if (player.global_position-global_position).length_squared()>100:
		var direction=(player.global_position-global_position).normalized()
		velocity=direction*SPEED if not damaged else direction*SPEED*0.5
		move_and_slide()
	
	if damaged:
		play_damaged()
	
