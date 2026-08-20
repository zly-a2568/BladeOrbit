extends Node2D
@onready var map: TileMapLayer = $"../Map"
@onready var obstacles: TileMapLayer = $"../Obstacles"

@onready var player: CharacterBody2D = $"../Player"

const CELL_SIZE:=16.0
var bat:PackedScene=preload("res://Scene/bat.tscn")
var ghost:PackedScene=preload("res://Scene/ghost.tscn")
var timer:float=0.0
var last_player_pos:Vector2i=Vector2i.ZERO
var map_rect:Rect2
var spawn_internal:=3.0

var astar_grid=AStarGrid2D.new()
enum EnemyType{
	BAT,
	GHOST
}

func  spawn_enemy_at(coord:Vector2i,type:EnemyType):
	if obstacles.get_cell_atlas_coords(coord)!=Vector2i(-1,-1):
		coord+=Vector2i(2,0)
	var spawn_pos:=map.to_global(map.map_to_local(coord))
		
	var inst:Enemy
	match type:
		EnemyType.BAT:
			inst = bat.instantiate() as CharacterBody2D
		EnemyType.GHOST:
			inst = ghost.instantiate() as CharacterBody2D
			inst.tile_pos=coord
			inst.next_pos=coord
			inst.path=astar_grid.get_id_path(inst.tile_pos,last_player_pos)
	inst.global_position=spawn_pos
	add_child(inst)




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mp_rect=map.get_used_rect()
	map_rect.position=mp_rect.position*16.0+Vector2(8.0,8.0)
	map_rect.end=mp_rect.end*16.0-Vector2(8.0,8.0)
	astar_grid.region=obstacles.get_used_rect()
	astar_grid.cell_size=Vector2(16.0,16.0)
	astar_grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	for i in obstacles.get_used_cells():
		astar_grid.set_point_solid(i)

func _physics_process(delta: float) -> void:
	timer+=delta
	if timer>=spawn_internal:
		timer=0
		var angle=randf_range(-PI,PI)
		var pos = $"../Player".global_position+randf_range(100,400)*Vector2(cos(angle),sin(angle))-global_position
		pos.x=clamp(pos.x,map_rect.position.x,map_rect.end.x)
		pos.y=clamp(pos.y,map_rect.position.y,map_rect.end.y)
		spawn_enemy_at(map.local_to_map(pos),EnemyType.BAT if randi_range(0,1)==0 else EnemyType.GHOST) 
	var player_pos=obstacles.local_to_map(obstacles.to_local(player.global_position))
	if player_pos!=last_player_pos:
		for e:Enemy in get_tree().get_nodes_in_group("map_moving"):
			e.path=astar_grid.get_id_path(e.tile_pos,player_pos)
			last_player_pos=player_pos
