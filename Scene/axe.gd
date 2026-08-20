extends CharacterBody2D
class_name Axe
var rotate_speed=PI
const RADIUS=40.0
var angular:float=PI/4*3
const ATTACKING_NUMBER = preload("uid://xse7q58h2rl8")

func _physics_process(delta: float) -> void:
	position.x=RADIUS*cos(angular)
	position.y=RADIUS*sin(angular)
	angular-=rotate_speed*delta
	rotation=angular+PI/4*3

func spawn_attacking_number(pos:Vector2,amount:float,high_damage:bool):
	var number:Label=ATTACKING_NUMBER.instantiate()
	if high_damage:
		number.modulate=Color.RED
	number.text=str(amount)
	number.origin_pos=pos
	get_parent().get_parent().get_parent().add_child(number)
	

func _on_detector_body_entered(body: Node2D) -> void:
	var high_damage_chance:float=get_parent().get_parent().get("high_damage_chance")
	var high_damage_rate:float=get_parent().get_parent().get("high_damage_rate")
	if body is Enemy:
		if body.damaged:
			return
		var damage=2.0
		var is_high_damage:bool=false
		if randf_range(0.0,1.0)<=high_damage_chance:
			damage*=high_damage_rate
			is_high_damage=true
		body.health-=damage
		body.damaged=true
		get_tree().get_first_node_in_group("player").shock_camera(4)
		SoundManager.play_sound("laser","enemy")
		spawn_attacking_number(body.global_position,damage,is_high_damage)
