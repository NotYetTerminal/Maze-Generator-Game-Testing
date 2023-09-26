extends Node

var width: int = 100
var length: int = 100

#export (Vector2) var highlight_coor setget set_highlight_coor

# uses nested lists to store states
# 0 wall
# 1, 5 floor
# 2 sector wall
# 3 door
# 4 checkpoint
var floor_states: Array = []

export (PackedScene) var wall_1_scene
export (PackedScene) var wall_2_apart_scene
export (PackedScene) var wall_2_corner_scene
export (PackedScene) var wall_3_scene
export (PackedScene) var wall_4_scene
export (PackedScene) var wall_scene
export (PackedScene) var player_scene

var walls: Array = []
var player: KinematicBody = null

# startup stuff
func _ready() -> void:
	#randomize()
	#$Camera.give_size(width, length)
	$MazeFloor.set_maze_size(width, length)
	floor_states = $AutomataGenerator.create_maze(width, length)
	_update_floor_states(floor_states)
	
	var start_time: int = OS.get_system_time_msecs()
	_spawn_in_walls()
	print(OS.get_system_time_msecs() - start_time)
	
	_spawn_player()


#func _process(_delta: float) -> void:
#	if player != null:
#		var wall_object: Spatial = null
#		var min_x: float = max(player.translation.x - 20, 0)
#		var min_z: float = max(player.translation.z - 20, 0)
#		var max_x: float = min(player.translation.x + 20, width - 1)
#		var max_z: float = min(player.translation.z + 20, length - 1)
#		for x_index in range(walls.size()):
#			for y_index in range(walls[x_index].size()):
#				wall_object = walls[x_index][y_index]
#				if (wall_object.translation.x < min_x or
#					wall_object.translation.z < min_z or
#					wall_object.translation.x > max_x or
#					wall_object.translation.z > max_z):
#					wall_object.visible = false
#				else:
#					wall_object.visible = true


# spawns the player in
func _spawn_player():
	player = player_scene.instance()
	add_child(player)
	player.translation = Vector3(0, -0.5, 0)
	player.rotation_degrees = Vector3(0, -135, 0)
	#player.translation = Vector3(-5, -0.5, -5)

# spawns in walls
func _spawn_in_walls():
	var object: Spatial
	var row: Array = []
	for x in range(floor_states.size()):
		row = []
		for z in range(floor_states[x].size()):
			match floor_states[x][z]:
				0:
					object = _get_correct_wall(x, z)
					if object != null:
						add_child(object)
						object.translation = Vector3(x, 0, z)
						#object.visible = false
						row.append(object)
				1:
					pass
				2:
					object = _get_correct_wall(x, z)
					if object != null:
						add_child(object)
						object.translation = Vector3(x, 0, z)
						#object.visible = false
						row.append(object)
				_:
					pass
		walls.append(row)
	
	# spawn in perimeter
	for x in range(width):
		match floor_states[x][0]:
			1, 3, 4, 5:
				object = wall_1_scene.instance()
				add_child(object)
				object.translation = Vector3(x, 0, -1)
				object.rotation_degrees = Vector3(0, 0, 0)
		
		match floor_states[x][length - 1]:
			1, 3, 4, 5:
				object = wall_1_scene.instance()
				add_child(object)
				object.translation = Vector3(x, 0, length)
				object.rotation_degrees = Vector3(0, 180, 0)
	
	for z in range(length):
		match floor_states[0][z]:
			1, 3, 4, 5:
				object = wall_1_scene.instance()
				add_child(object)
				object.translation = Vector3(-1, 0, z)
				object.rotation_degrees = Vector3(0, 90, 0)
		
		match floor_states[width - 1][z]:
			1, 3, 4, 5:
				object = wall_1_scene.instance()
				add_child(object)
				object.translation = Vector3(width, 0, z)
				object.rotation_degrees = Vector3(0, -90, 0)

# gets the correct wall depending on the floor tiles around it
func _get_correct_wall(x_coor: int, y_coor: int) -> Spatial:
	var bordering: int = 0
	if y_coor + 1 != length:
		match floor_states[x_coor][y_coor + 1]:
			1, 3, 4, 5:
				bordering += 1
	if x_coor + 1 != width:
		match floor_states[x_coor + 1][y_coor]:
			1, 3, 4, 5:
				bordering += 2
	if y_coor != 0:
		match floor_states[x_coor][y_coor - 1]:
			1, 3, 4, 5:
				bordering += 4
	if x_coor != 0:
		match floor_states[x_coor - 1][y_coor]:
			1, 3, 4, 5:
				bordering += 8
	
	# binary used to get wall type and rotation
	# 1 wall
	# 0001 = 0
	# 0010 = 90
	# 0100 = 180
	# 1000 = -90
	
	# 2 wall corner
	# 0011 = 0
	# 0110 = 90
	# 1100 = 180
	# 1001 = -90
	
	# 2 wall apart
	# 0101 = 0
	# 1010 = 90
	
	# 3 wall
	# 1110 = 0
	# 1101 = 90
	# 1011 = 180
	# 0111 = -90
	
	# 4 wall 
	# 1111 = 0
	
	var object: Spatial = null
	var rotation: float = 0
	match bordering:
		1, 2, 4, 8:
			object = wall_1_scene.instance()
			match bordering:
				1:
					rotation = 0
				2:
					rotation = 90
				4:
					rotation = 180
				8:
					rotation = -90
		3, 6, 12, 9:
			object = wall_2_corner_scene.instance()
			match bordering:
				6:
					rotation = 90
				12:
					rotation = 180
				9:
					rotation = -90
		5, 10:
			object = wall_2_apart_scene.instance()
			match bordering:
				10:
					rotation = 90
		14, 13, 11, 7:
			object = wall_3_scene.instance()
			match bordering:
				13:
					rotation = 90
				11:
					rotation = 180
				7:
					rotation = -90
		15:
			object = wall_4_scene.instance()
	
	if bordering != 0:
		object.rotation_degrees = Vector3(0, rotation, 0)
	return object

# for demonstration
#func _process(_delta: float) -> void:
#	if Input.is_action_pressed("ui_accept"):
#		floor_states = $AutomataGenerator.iterate()
#		_update_floor_states(floor_states)
#	if Input.is_action_just_pressed("ui_down"):
#		floor_states = $AutomataGenerator.check_spaces()
#		_update_floor_states(floor_states)

func _update_floor_states(states: Array) -> void:
	#$MazeFloor.update_floor_states_colourful(states)
	$MazeFloor.update_floor_states(states)

# used for highlighting one square
# only triggers when values changed
#func set_highlight_coor(new_coor) -> void:
#	if int(abs(new_coor.x)) != highlight_coor.x or int(abs(new_coor.y)) != highlight_coor.y:
#		new_coor.x = int(abs(new_coor.x)) % length
#		new_coor.y = int(abs(new_coor.y)) % width
#		highlight_coor = new_coor
#		_update_floor_vectors()
#
#
## calls the maze to update highlight coordinate
#func _update_floor_vectors() -> void:
#	if (get_children().size() != 0):
#		$MazeFloor.update_floor(highlight_coor)

