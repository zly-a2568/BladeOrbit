extends Enemy
class_name Bat

const SPEED = 60.0
const CHASE_MIN_DISTANCE_SQ = 100.0
const DAMAGED_SPEED_FACTOR = 0.5

var player: CharacterBody2D


func _ready() -> void:
	super()
	player = get_tree().get_first_node_in_group("player")


func _act(_delta: float) -> void:
	if player == null:
		return
	var to_player := player.global_position - global_position
	if to_player.length_squared() > CHASE_MIN_DISTANCE_SQ:
		var direction := to_player.normalized()
		velocity = direction * SPEED * (DAMAGED_SPEED_FACTOR if damaged else 1.0)


func _can_move() -> bool:
	return true
