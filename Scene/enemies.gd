extends Node2D

class_name EnemySpawner

signal player_tile_changed(tile: Vector2i)

const CELL_SIZE := 16.0
const SPAWN_DISTANCE_MIN := 100.0
const SPAWN_DISTANCE_MAX := 400.0
const ENEMY_NUMBER_MAX :=150
const GRID_RADIUS := 64
const GRID_REBUILD_MARGIN := 32

enum EnemyType {
	BAT,
	GHOST,
	SHOOTER
}

const ENEMY_SCENES := {
	EnemyType.BAT: preload("res://Scene/bat.tscn"),
	EnemyType.GHOST: preload("res://Scene/ghost.tscn"),
	EnemyType.SHOOTER: preload("res://Scene/shooter.tscn"),
}

var SPAWN_ROLLS := [
	[EnemyType.SHOOTER, 0.0],
	[EnemyType.GHOST, 0.3],
	[EnemyType.BAT, 0.4],
]

@onready var map: TileMapLayer = $"../Map"
@onready var obstacles: TileMapLayer = $"../Obstacles"
@onready var player: Player = $"../Player"

var spawn_interval := 3.0
var spawn_timer := 0.0
var player_tile := Vector2i.ZERO
var grid_center := Vector2i.ZERO
var astar_grid := AStarGrid2D.new()


func _ready() -> void:
	add_to_group(Enemy.PATH_SERVICE_GROUP)
	player.level_up.connect(_on_player_level_up)
	player_tile = obstacles.local_to_map(obstacles.to_local(player.global_position))
	grid_center = player_tile
	_rebuild_grid(grid_center)


func _physics_process(delta: float) -> void:
	_tick_spawning(delta)
	_update_player_tile()


func request_path(from_tile: Vector2i, to_tile: Vector2i) -> Array[Vector2i]:
	if not astar_grid.is_in_boundsv(from_tile) or not astar_grid.is_in_boundsv(to_tile):
		return []
	return astar_grid.get_id_path(from_tile, to_tile)


func spawn_enemy_at(coord: Vector2i, type: EnemyType) -> void:
	for i in range(8):
		if not _is_solid(coord):
			break
		coord += Vector2i(2, 0)
	var inst := _instantiate_enemy(type)
	inst.tile_pos = coord
	inst.scale = Vector2.ZERO
	inst.global_position = map.to_global(map.map_to_local(coord))
	add_child(inst)
	inst.died.connect(_on_enemy_died)
	get_tree().create_tween().tween_property(inst, "scale", Vector2.ONE, 0.3)


func _on_enemy_died(reward: float) -> void:
	player.experience += reward


func _is_solid(coord: Vector2i) -> bool:
	return obstacles.get_cell_atlas_coords(coord) != Vector2i(-1, -1)


func _rebuild_grid(center: Vector2i) -> void:
	grid_center = center
	var half := Vector2i.ONE * GRID_RADIUS
	astar_grid.region = Rect2i(center - half, half * 2)
	astar_grid.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	for x in range(astar_grid.region.position.x, astar_grid.region.end.x):
		for y in range(astar_grid.region.position.y, astar_grid.region.end.y):
			var coord := Vector2i(x, y)
			if _is_solid(coord):
				astar_grid.set_point_solid(coord)


func _maybe_rebuild_grid(tile: Vector2i) -> void:
	var offset := tile - grid_center
	if maxi(absi(offset.x), absi(offset.y)) <= GRID_REBUILD_MARGIN:
		return
	_rebuild_grid(tile)


func _tick_spawning(delta: float) -> void:
	if get_child_count()>=ENEMY_NUMBER_MAX:
		return
	spawn_timer += delta
	if spawn_timer < spawn_interval:
		return
	spawn_timer = 0.0
	spawn_enemy_at(map.local_to_map(_random_spawn_position()), _pick_enemy_type())


func _update_player_tile() -> void:
	var tile := obstacles.local_to_map(obstacles.to_local(player.global_position))
	if tile == player_tile:
		return
	player_tile = tile
	_maybe_rebuild_grid(tile)
	player_tile_changed.emit(tile)


func _random_spawn_position() -> Vector2:
	var angle := randf_range(-PI, PI)
	var pos := player.global_position \
			+ randf_range(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX) * Vector2(cos(angle), sin(angle)) \
			- global_position
	return pos


func _pick_enemy_type() -> EnemyType:
	var roll := randf_range(0.0, 1.0)
	var cumulative := 0.0
	for entry: Array in SPAWN_ROLLS:
		cumulative += entry[1]
		if roll <= cumulative:
			var picked: EnemyType = entry[0]
			return picked
	return SPAWN_ROLLS[-1][0]


func _instantiate_enemy(type: EnemyType) -> Enemy:
	return ENEMY_SCENES[type].instantiate() as Enemy


func _on_player_level_up(level: int) -> void:
	match(level):
		2:
			spawn_interval=1.5
			SPAWN_ROLLS[2] = [EnemyType.BAT,0.5]
			SPAWN_ROLLS[1] = [EnemyType.GHOST,0.4]
			SPAWN_ROLLS[0] = [EnemyType.SHOOTER,0.1]
		3:
			spawn_interval=0.75
			SPAWN_ROLLS[2] = [EnemyType.BAT,0.2]
			SPAWN_ROLLS[1] = [EnemyType.GHOST,0.4]
			SPAWN_ROLLS[0] = [EnemyType.SHOOTER,0.4]
			
		4:
			spawn_interval=0.4
			SPAWN_ROLLS[2] = [EnemyType.BAT,0.0]
			SPAWN_ROLLS[1] = [EnemyType.GHOST,0.3]
			SPAWN_ROLLS[0] = [EnemyType.SHOOTER,0.7]
		5:
			spawn_interval=0.3
			SPAWN_ROLLS[2] = [EnemyType.BAT,0.4]
			SPAWN_ROLLS[1] = [EnemyType.GHOST,0.0]
			SPAWN_ROLLS[0] = [EnemyType.SHOOTER,0.6]
