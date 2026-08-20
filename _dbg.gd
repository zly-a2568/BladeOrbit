extends Node2D

func _ready() -> void:
	var game: Node2D = (load("res://Scene/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await get_tree().create_timer(0.3).timeout
	var map: TileMapLayer = game.get_node("Map")
	var obs: TileMapLayer = game.get_node("Obstacles")
	var player: CharacterBody2D = game.get_node("Player")
	var enemies := get_tree().get_nodes_in_group("map_moving")

	var rect: Rect2i = map.get_used_rect()
	rect = rect.grow(1)
	print("MAP used_rect=", map.get_used_rect())

	var floortiles := {}
	for c in map.get_used_cells():
		floortiles[c] = true
	var blocks := {}
	for c in obs.get_used_cells():
		blocks[c] = true

	var player_pos: Vector2i = map.local_to_map(map.to_local(player.global_position))
	var goal: Vector2i = (enemies[0] as Enemy).tile_pos
	var visited := {}
	var prev := {}
	var q: Array[Vector2i] = [player_pos]
	var qi := 0
	visited[player_pos] = true
	while qi < q.size():
		var p: Vector2i = q[qi]
		qi += 1
		if p == goal:
			break
		for d in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT]:
			var np: Vector2i = p + d
			if not rect.has_point(np):
				continue
			if visited.has(np) or (blocks.has(np)):
				continue
			visited[np] = true
			prev[np] = p
			q.append(np)

	for y in range(rect.position.y, rect.position.y + rect.size.y):
		var line := ""
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var c := Vector2i(x, y)
			if c == goal:
				line += "G"
			elif c == player_pos:
				line += "P"
			elif blocks.has(c):
				line += "#"
			elif not floortiles.has(c):
				line += "~"   # void: no floortiles tile but inside used_rect
			else:
				line += "."
		print(line)
	print("goal=", goal, " player_pos=", player_pos)
	print("--- done ---")
	get_tree().quit()
