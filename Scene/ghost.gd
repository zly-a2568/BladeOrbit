extends Enemy
class_name Ghost


func _act(delta: float) -> void:
	if dying:
		return
	go_on_map(delta)
