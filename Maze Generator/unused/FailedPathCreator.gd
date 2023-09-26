extends Node

var maze_width: int
var maze_length: int
var starting_position: Vector2
var path_coors: Array = []

var finished: bool = false


func create_path(width: int, length: int, minimum_distance: int) -> Array:
	maze_width = width
	maze_length = length
	path_coors.clear()
	
	_pick_start_position()
	path_coors.append(starting_position)
	print(starting_position)
	
	var current_position: Vector2 = starting_position
	var valid_directions: Array = [Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN]
	var chosen_direction: Vector2
	
	print(path_coors)
	
	while(not finished):
	#for index in range(10):
		chosen_direction = valid_directions[randi() % valid_directions.size()]
		print(chosen_direction)
		print(_chosen_direction_valid(current_position + chosen_direction))
		if _chosen_direction_valid(current_position + chosen_direction):
			current_position += chosen_direction
			valid_directions = [Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN]
			# remove to not go backwards
			valid_directions.erase(chosen_direction)
			path_coors.append(current_position)
			
		elif path_coors.size() >= minimum_distance:
			# if longer or equal we just finish
			print("finished")
			finished = true
		else:
			valid_directions.erase(chosen_direction)
			# if no valid ways to go
			if valid_directions.size() == 0:
				# we just try again
				print("dead")
				return create_path(maze_width, maze_length, minimum_distance)
			else:
				pass
	
	return path_coors


func _chosen_direction_valid(new_position: Vector2) -> bool:
	# check if new position already in path coordinates or out of bounds
	if new_position in path_coors: return false
	elif new_position.x < 0: return false
	elif new_position.x >= maze_width: return false
	elif new_position.y < 0: return false
	elif new_position.y >= maze_length: return false
	else: return true

# picks a random starting point on the edge
func _pick_start_position() -> void:
	starting_position.x = randf()
	starting_position.y = randf()
	if randi() % 2 == 0:
		starting_position.x = round(starting_position.x)
	else:
		starting_position.y = round(starting_position.y)

	starting_position.x = int(starting_position.x * (maze_width - 1))
	starting_position.y = int(starting_position.y * (maze_length - 1))
	
