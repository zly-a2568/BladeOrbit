extends CharacterBody2D
class_name Player

signal high_damage()
signal level_up(level: int)

const axe_inst: PackedScene = preload("res://Scene/axe.tscn")

const SPEED = 180.0
const RECOVERY_SPEED = 32
const DAMAGED_SPEED_FACTOR = 0.5
const LOW_HEALTH_THRESHOLD = 3.0
const BLINK_TIMES = 3
const BLINK_INTERVAL = 0.1

const LEVEL_UP_XP := [10.0, 50.0, 150.0,250.0,400.0]
const HEALTH_BAR_MAX :=[18.0, 28.0, 36.0, 45.0]
const LEVEL_EXP_BAR_MAX := [50.0, 150.0, 250.0, 400.0]

#player game properties
@export_group("Properties")
@export var health: int = 12
@export var experience: float = 0.0:
	set(v):
		experience = v
		create_tween().tween_property($StandaloneLayer/UI/H/V/ExperienceBar, "value", v, 0.2).set_ease(Tween.EASE_IN)
@export var axe_rotate_speed: float = PI * 1.5
@export var axe_count: int = 1
@export var high_damage_rate: float = 1.5
@export var high_damage_chance: float = 0.12
@export var invincible_time: float = 1.0

var damaged: bool = false
var shocking: bool = false
var shock_amount: float = 0
#var game_level: int = 1
var dying: bool = false
var can_restart: bool = false

@onready var animation: AnimationPlayer = $Animation
@onready var sprite: Sprite2D = $Texture
@onready var camera: Camera2D = $Camera2D
@onready var axes: Node2D = $Axes
@onready var invincible_bar: ProgressBar = $ProgressBar
@onready var shader := $StandaloneLayer/Vignette.material as ShaderMaterial
@onready var health_bar: TextureProgressBar = $StandaloneLayer/UI/H/V/HealthBar
@onready var health_bar_eased: TextureProgressBar = $StandaloneLayer/UI/H/V/HealthBar/HealthBarEased
@onready var experience_bar: TextureProgressBar = $StandaloneLayer/UI/H/V/ExperienceBar
@onready var crit_label: Label = $StandaloneLayer/UI/Label
@onready var mask: TextureRect = $StandaloneLayer/Mask
@onready var game_over_label: Label = $StandaloneLayer/Label


func _ready() -> void:
	get_tree().paused = false
	update_axes.call_deferred()
	for bar in [health_bar, health_bar_eased]:
		bar.max_value = health
		bar.value = health
	experience_bar.max_value = 10.0
	


func _process(delta: float) -> void:
	_update_vignette_pulse()
	if dying:
		return
	_update_camera_shake(delta)
	_update_game_level()


func _physics_process(delta: float) -> void:
	if dying:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		var speed := SPEED * (DAMAGED_SPEED_FACTOR if damaged else 1.0)
		velocity = speed * (Vector2(0, dir.y) if absf(dir.y) >= absf(dir.x) else Vector2(dir.x, 0))
		_face_direction()
	else:
		velocity = Vector2.ZERO
		animation.play("RESET")
	move_and_slide()


func _input(event: InputEvent) -> void:
	if dying and can_restart:
		if event is InputEventMouseButton:
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				get_tree().reload_current_scene()


func apply_buff(property: StringName, value: Variant) -> void:
	set(property, value)
	if property == &"axe_rotate_speed" or property == &"axe_count":
		update_axes.call_deferred()
	elif property == &"health":
		create_tween().tween_property(health_bar, "value", health, 0.2).set_ease(Tween.EASE_OUT)
		create_tween().tween_property(health_bar_eased, "value", health, 0.4).set_ease(Tween.EASE_OUT)


func get_damage(amount: int) -> void:
	if dying or damaged:
		return
	damaged = true
	health -= amount
	_play_hurt_feedback()
	if health <= 0:
		die()


func shock_camera(amount: float) -> void:
	shocking = true
	shock_amount = amount


func notify_high_damage() -> void:
	high_damage.emit()


func update_axes() -> void:
	if axes.get_child_count() < axe_count:
		for i in range(axe_count - axes.get_child_count()):
			axes.add_child(axe_inst.instantiate())
		_configure_axes(true)
	else:
		_configure_axes(false)


func die() -> void:
	dying = true
	get_tree().paused = true
	animation.play("dying")
	await get_tree().create_timer(0.7).timeout
	var t = create_tween()
	t.tween_property(mask, "modulate:a", 0.5, 0.2)
	t.tween_property(game_over_label, "visible_characters", 4, 0.4)
	await get_tree().create_timer(0.6).timeout
	Levels.game_level=1
	can_restart = true


func _face_direction() -> void:
	var anim := ""
	if velocity.y > 0:
		anim = "down"
	elif velocity.y < 0:
		anim = "up"
	elif velocity.x > 0:
		anim = "right"
	elif velocity.x < 0:
		anim = "left"
	if animation.current_animation != anim:
		animation.play(anim)


func _update_vignette_pulse() -> void:
	if health <= LOW_HEALTH_THRESHOLD and health > 0.0:
		shader.set_shader_parameter("alpha", sin(Time.get_ticks_msec() * 0.01) * 0.7 + 0.7)
	else:
		shader.set_shader_parameter("alpha", 0.0)


func _update_camera_shake(delta: float) -> void:
	if not shocking:
		return
	camera.offset.x = randf_range(-shock_amount, shock_amount)
	camera.offset.y = randf_range(-shock_amount, shock_amount)
	shock_amount = move_toward(shock_amount, 0, RECOVERY_SPEED * delta)
	if is_zero_approx(camera.offset.length_squared()):
		shocking = false


func _update_game_level() -> void:
	while Levels.game_level <= LEVEL_UP_XP.size() and experience >= LEVEL_UP_XP[Levels.game_level - 1]:
		Levels.game_level += 1
		experience_bar.max_value = LEVEL_EXP_BAR_MAX[Levels.game_level - 2]
		for bar:TextureProgressBar in [health_bar,health_bar_eased]:
			bar.max_value=HEALTH_BAR_MAX[Levels.game_level - 2]
		level_up.emit(Levels.game_level)


func _play_hurt_feedback() -> void:
	SoundManager.play_sound("pain", "player")
	health_bar.value = health
	create_tween().tween_property(health_bar_eased, "value", health, 0.3)
	_spawn_hurt_clone_flash()
	await _blink_red()
	_run_invincibility_drain()


func _spawn_hurt_clone_flash() -> void:
	var tex_alt := sprite.duplicate() as Sprite2D
	tex_alt.position = sprite.position
	add_child(tex_alt)
	var t1 := create_tween()
	t1.tween_property(tex_alt, "modulate:a", 0.0, 0.3)
	t1.parallel().tween_property(tex_alt, "scale", Vector2.ONE * 1.5, 0.3)
	t1.tween_callback(tex_alt.queue_free)


func _blink_red() -> void:
	for i in range(BLINK_TIMES):
		sprite.modulate = Color.RED
		await get_tree().create_timer(BLINK_INTERVAL).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(BLINK_INTERVAL).timeout


func _run_invincibility_drain() -> void:
	invincible_bar.value = 0.0
	invincible_bar.visible = true
	var t = get_tree().create_tween()
	t.tween_property(invincible_bar, "value", 100.0, invincible_time)
	t.tween_property(self, "damaged", false, 0.0)
	t.tween_property(invincible_bar, "visible", false, 0.0)


func _configure_axes(rephase: bool) -> void:
	var ct: int = 0
	for a: Axe in axes.get_children():
		a.player = self
		a.rotate_speed = axe_rotate_speed
		if rephase:
			a.angular = TAU / axe_count * ct
		ct += 1


func _on_high_damage() -> void:
	if dying:
		return
	var clone_body := crit_label.duplicate(DuplicateFlags.DUPLICATE_USE_INSTANTIATION) as Label
	clone_body.modulate.a = 0.0
	clone_body.offset_transform_scale = Vector2.ONE * 0.4
	clone_body.offset_transform_position = Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	crit_label.get_parent().add_child(clone_body)
	var t := create_tween()
	t.tween_property(clone_body, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(clone_body, "offset_transform_scale", Vector2.ONE * 0.95, 0.3)
	t.tween_property(clone_body, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(clone_body, "offset_transform_scale", Vector2.ONE * 1.5, 0.3)
	t.tween_callback(clone_body.queue_free)
