extends CharacterBody2D

class_name Enemy
var damaged:bool=false
var dying:bool=false
var map_moving:bool=false
var path:Array[Vector2i]=[]
var tile_pos:Vector2i=Vector2i.ZERO
var next_pos:Vector2i=Vector2i.ZERO
@export var health:float=3.0
@export var damage_amount:int=1
@export var exp_reward:float=0.5
@export var invincible_time:float=0.6
@onready var health_bar: TextureProgressBar = $HealthBar
const ITEM = preload("uid://biqu7yu622j6t")
const MAP_SPEED:=64.0
const TILE:=16.0

func _ready() -> void:
	$Hitter.body_entered.connect(func(body:Node2D):
		if body is Player:
			body.get_damage(damage_amount)
			SoundManager.play_sound("pain","player")
		)
	health_bar.max_value=health

func _process(delta: float) -> void:
	health_bar.value=health

func _physics_process(delta: float) -> void:
	if health<=0:
		die()

func play_damaged():
	var flash:float=invincible_time/4.0
	$Sprite2D.modulate=Color.RED
	await get_tree().create_timer(flash).timeout
	$Sprite2D.modulate=Color.WHITE
	await get_tree().create_timer(flash).timeout
	$Sprite2D.modulate=Color.RED
	await get_tree().create_timer(flash).timeout
	$Sprite2D.modulate=Color.WHITE
	await get_tree().create_timer(flash).timeout
	damaged=false

func die():
	if dying:
		return
	dying=true
	var tween=get_tree().create_tween()
	(get_tree().get_first_node_in_group("player") as Player).experience+=exp_reward
	if map_moving:
		get_parent().map_moving_count-=1
	tween.tween_property($Sprite2D,"modulate:a",0.0,0.2)
		
	tween.tween_callback(func():
		var chance=randf_range(0.0,1.0)
		if chance<=0.5:
			var inst=ITEM.instantiate() as Area2D
			inst.global_position=global_position
			get_parent().get_parent().add_child(inst)
		queue_free()
		)
	
func go_on_map(delta:float):
	if path.is_empty():
		velocity=Vector2.ZERO
		return
	var target:Vector2 = Vector2(next_pos)*TILE+Vector2(TILE*0.5,TILE*0.5)
	if (position-target).length_squared()>0:
		position.x=move_toward(position.x,target.x,MAP_SPEED*delta)
		position.y=move_toward(position.y,target.y,MAP_SPEED*delta)
	else:
		tile_pos=path[0]
		next_pos=path[0]
		path.remove_at(0)
