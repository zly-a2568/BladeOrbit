extends Enemy
class_name Ghost


func _physics_process(delta: float) -> void:
	if health<=0:
		die()
		return
	go_on_map(delta)
	if damaged:
		play_damaged()
	move_and_slide()
