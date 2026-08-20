extends CharacterBody2D
class_name Player
@onready var animation: AnimationPlayer = $Animation
@onready var axes: Node2D = $Axes
@onready var health_bar: TextureProgressBar = $StandaloneLayer/UI/H/V/HealthBar
@onready var health_bar_eased: TextureProgressBar = $StandaloneLayer/UI/H/V/HealthBar/HealthBarEased

const axe_inst:PackedScene=preload("res://Scene/axe.tscn")

const SPEED = 180.0
const RECOVERY_SPEED=32
var damaged:bool=false
var shocking:bool=false
var shock_amount:float=0
var game_level:int=1
#player game properties
@export_group("Properties")
@export var health:int=12
@export var experience:float=0.0:
	set(v):
		experience=v
		$StandaloneLayer/UI/H/V/ExperienceBar.value=v
@export var axe_rotate_speed:float=PI*1.3
@export var axe_count:int=1
@export var high_damage_rate:float=1.5
@export var high_damage_chance:float=0.12
@export var invincible_time:float=1.0

func _ready() -> void:
	update_axes.call_deferred()
	health_bar.max_value=health
	health_bar_eased.max_value=health
	health_bar.value=health
	health_bar_eased.value=health
	$StandaloneLayer/UI/H/V/ExperienceBar.max_value=10.0


func play_damaged():
	health_bar.value=health
	create_tween().tween_property(health_bar_eased,"value",health,0.3)
	
	for i in range(3):
		$Texture.modulate=Color.RED
		await get_tree().create_timer(0.1).timeout
		$Texture.modulate=Color.WHITE
		await get_tree().create_timer(0.1).timeout
	$ProgressBar.value=0.0
	var t=get_tree().create_tween()
	$ProgressBar.visible=true
	t.tween_property($ProgressBar,"value",100.0,invincible_time)
	t.tween_property(self,"damaged",false,0.0)
	t.tween_property($ProgressBar,"visible",false,0.0)

func apply_buff(property:StringName,value:Variant):
	set(property,value)
	if property=="axe_rotate_speed" or property=="axe_count":
		update_axes.call_deferred()

func _process(delta: float) -> void:
	if shocking:
		$Camera2D.offset.x=randf_range(-shock_amount,shock_amount)
		$Camera2D.offset.y=randf_range(-shock_amount,shock_amount)
		shock_amount=move_toward(shock_amount,0,RECOVERY_SPEED*delta)
		if is_zero_approx($Camera2D.offset.length_squared()):
			shocking=false
	if experience>=10.0 and game_level<2:
		$"../Enemies".spawn_internal*=0.8
		$StandaloneLayer/UI/H/V/ExperienceBar.max_value=50.0
		game_level+=1
	if experience>=50.0 and game_level<3:
		$StandaloneLayer/UI/H/V/ExperienceBar.max_value=150.0
		$"../Enemies".spawn_internal*=0.6
		game_level+=1
	if experience>=150.0 and game_level<4:
		$"../Enemies".spawn_internal*=0.5
		game_level+=1

func _physics_process(delta: float) -> void:
	
	var dir=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if dir!=Vector2.ZERO:
		velocity= (SPEED if not damaged else SPEED*0.5)*(Vector2(0,dir.y)if abs(dir.y)>=abs(dir.x) else Vector2(dir.x,0))
		
		if velocity.x<0:
			if animation.current_animation!="left":
				animation.play("left")
		if velocity.x>0:
			if animation.current_animation!="right":
				animation.play("right")	
		if velocity.y<0:
			if animation.current_animation!="up":
				animation.play("up")
		if velocity.y>0:
			if animation.current_animation!="down":
				animation.play("down")
	else:
		if dir.x==0:
			velocity.x=0
		if dir.y==0:
			velocity.y=0
		animation.play("RESET")
	
	move_and_slide()

func update_axes():
	if axes.get_child_count() < axe_count:
		for i in range(axe_count-axes.get_child_count()):
			var axe=axe_inst.instantiate()
			axes.add_child(axe)
		var ct:int=0
		for a:Axe in axes.get_children():
			a.angular=2*PI/axe_count*ct
			a.rotate_speed=axe_rotate_speed
			ct+=1
	else:
		for a:Axe in axes.get_children():
			a.rotate_speed=axe_rotate_speed

func shock_camera(amount:float):
	shocking=true
	shock_amount=amount

func die():
	pass

func get_damage(amount:int):
	if damaged:
		return
	damaged=true
	health-=amount
	play_damaged()
	if health<=0:
		die()
