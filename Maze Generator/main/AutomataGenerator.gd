extends Node

const size_percentage: float = 0.1
const sector_sections: int = 3

const alive_states: Array = [1, 2, 3, 4, 5]
const born_states: Array = [3]

var max_width: int
var max_length: int

var sector_x_sizes: Array = []
var sector_y_sizes: Array = []

# uses nested lists to store states
# false wall
# true floor
# 0 wall
# 1, 5 floor
# 2 sector wall
# 3 door
# 4 checkpoint
var states: Array = []
var last_states: Array = []


func iterate() -> Array:
	var _t = _iterate_generation()
	return states

func check_spaces() -> Array:
	_check_all_spaces_in_sectors()
	return states

# creates a maze based on cellular automata
func create_maze(width: int, length: int) -> Array:
	max_width = width
	max_length = length
	var start_time: int = OS.get_system_time_msecs()
	
	# create emtpy states in array
	_fill_empty_states()
	
	# start off with random centre
	_make_random_noise()
	
	# iterate until all four walls have been modified
	while not _check_all_walls_changed():
		# if cellular automata stops
		# restart the whole generation
		if not _iterate_generation():
			print("RESET")
			states = []
			_fill_empty_states()
			_make_random_noise()
	
	print(OS.get_system_time_msecs() - start_time)
	
	# convert states from bool to int
	# 0 wall
	# 1, 5 floor
	# 2 sector wall
	# 3 door
	# 4 checkpoint
	_convert_states()
	
	# put in sector lines
	_make_sector_lines()
	#return states
	
	# check all space in sectors
	_check_all_spaces_in_sectors()
	print(OS.get_system_time_msecs() - start_time)
	
	# make sector seperating doors
	_make_sector_doors()
	
	# create start and end positions
	_create_start_and_end()
	print(OS.get_system_time_msecs() - start_time)
	
	return states

# creates a tunnel from 0,0 to maze
# and from max_width, max_length to maze
func _create_start_and_end() -> void:
	_create_tunnel(0, 0, true)
	_create_tunnel(max_width - 1, max_length - 1, false)

# create start tunnel
func _create_tunnel(x_start: int, y_start: int, up_and_right: bool) -> void:
	var dir: int = 0
	var last_cell_a_door: bool = false
	while states[x_start][y_start] == 0 or states[x_start][y_start] == 2:
		if states[x_start][y_start] == 2:	# if we move to a sector wall
			states[x_start][y_start] = 3	# create a door instead of a empty floor
			last_cell_a_door = true
		else:
			states[x_start][y_start] = 5
			last_cell_a_door = false
		dir = randi() % 2
		if up_and_right:
			if not last_cell_a_door:
				if dir:
					x_start += 1
				else:
					y_start += 1
			else:
				if states[x_start][y_start + 1] == 2:
					x_start += 1
				else:
					y_start += 1
		else:
			if not last_cell_a_door:
				if dir:
					x_start -= 1
				else:
					y_start -= 1
			else:
				if states[x_start][y_start - 1] == 2:
					x_start -= 1
				else:
					y_start -= 1

# converts states bool to ints for later use
func _convert_states():
	for x in range(max_width):
		for y in range(max_length):
			states[x][y] = int(states[x][y])

# makes the doors between sectors along the wall
func _make_sector_doors():
	# get eac wall segment
	#var colour_index: int = 3
	var x_index: int = 0
	var y_start: int = 0
	var y_end: int = 0
	var wall_1: Array = []
	var wall_2: Array = []
	for wall_index_1 in range(1, sector_sections):
		x_index = wall_index_1 * sector_x_sizes[wall_index_1 - 1]
		y_start = 0
		y_end = 0
		for wall_index_2 in range(sector_sections):
			wall_1 = []
			wall_2 = []
			y_start = y_end
			y_end += sector_y_sizes[wall_index_2]
			for y_index in range(y_start, y_end):
				wall_1.append([x_index, y_index])
				wall_2.append([y_index, x_index])
				#states[x_index][y_index] = colour_index
				#states[y_index][x_index] = colour_index + 3
			#colour_index += 1
			
			_make_door(wall_1, true)
			_make_door(wall_2, false)


# makes a door on the sector wall
func _make_door(walls: Array, vertical: bool) -> void:
	var valid_positions: Array = []
	for wall_loc in walls:
		if vertical:
			if states[wall_loc[0] + 1][wall_loc[1]] == 1 and states[wall_loc[0] - 1][wall_loc[1]] == 1:
				valid_positions.append(wall_loc)
		else:
			if states[wall_loc[0]][wall_loc[1] + 1] == 1 and states[wall_loc[0]][wall_loc[1] - 1] == 1:
				valid_positions.append(wall_loc)
	
	if valid_positions.size() != 0:
		var chosen_index: int = randi() % valid_positions.size()
		states[valid_positions[chosen_index][0]][valid_positions[chosen_index][1]] = 3
	else:
		print("NONE")

# checks if all of the space in a sector are reachable
func _check_all_spaces_in_sectors() -> void:
	var threads_list: Array = []
	for x_sector in range(sector_sections):
		#print("X ", x_sector)
		for y_sector in range(sector_sections):
			#print("Y ", y_sector)
			threads_list.append(Thread.new())
			threads_list[-1].start(self, "_check_sector_spaces", [x_sector, y_sector])
			#_check_sector_spaces([x_sector, y_sector])
	
	for thread in threads_list:
		thread.wait_to_finish()

# checks one sector spaces
func _check_sector_spaces(userdata: Array) -> void:
	var x_index: int = userdata[0]
	var y_index: int = userdata[1]
	var starting_x_index: int = 0
	for x in range(x_index):
		starting_x_index += sector_x_sizes[x]
	var max_x_size =  starting_x_index + sector_x_sizes[x_index]
	
	var starting_y_index: int = 0
	for y in range(y_index):
		starting_y_index += sector_y_sizes[y]
	var max_y_size = starting_y_index + sector_y_sizes[y_index]
	
	var spaces_walls: Array = []
	var checked_locations: Array = []
	
	for x_check in range(starting_x_index, max_x_size):
		for y_check in range(starting_y_index, max_y_size):
			if states[x_check][y_check] == 1 and not ([x_check, y_check] in checked_locations):
				checked_locations.append_array(_collect_area(spaces_walls, x_check, y_check))
	
	#print(spaces_walls.size())
	#print(checked_locations.size())
	
	_remove_walls(spaces_walls)
	
	# puts in 1 checlpoint to each sector
	var position: Array = spaces_walls[0][randi() % spaces_walls[0].size()]
	states[position[0]][position[1]] = 4
	
	#print(spaces_walls.size())

# removes the walls between disconnected spaces
func _remove_walls(spaces_walls: Array) -> void:
	var breaking: bool = false
	var start_loc: Array = []
	var end_loc: Array = []
	while spaces_walls.size() > 1:
		breaking = false
		
		for checking_wall_list_index in range(1, spaces_walls.size()):
			for wall_location_index in range(spaces_walls[checking_wall_list_index].size()):
				#print(spaces_walls[0][wall_location_index], " ", spaces_walls[checking_wall_list_index])
				var wall_loc: Array = spaces_walls[checking_wall_list_index][wall_location_index]
				if wall_loc in spaces_walls[0]:
					states[wall_loc[0]][wall_loc[1]] = 1
					spaces_walls[0].erase(wall_loc)
					spaces_walls[checking_wall_list_index].erase(wall_loc)
					
					spaces_walls[0].append_array(spaces_walls.pop_at(checking_wall_list_index))
					breaking = true
					start_loc = []
					break
			if breaking:
				break
		
		# if there more than one wall between spaces
		if not breaking:
			if start_loc.size() == 0:
				# gets a random point in space 0
				var index: int = randi() % spaces_walls[0].size()
				start_loc = spaces_walls[0][index]
				
				# gets the closest point in space 1
				var shortest: float = 4095.0
				var temp_distance: float = 0.0
				var short_index: int = 0
				
				for end_wall_index in range(spaces_walls[1].size()):
					temp_distance = _distance_between(start_loc, spaces_walls[1][end_wall_index])
					if temp_distance < shortest:
						shortest = temp_distance
						short_index = end_wall_index
				
				end_loc = spaces_walls[1][short_index]
				
				# gets the closest point in space 0
				shortest = 4095.0
				temp_distance = 0.0
				short_index = 0
				
				for end_wall_index in range(spaces_walls[0].size()):
					temp_distance = _distance_between(end_loc, spaces_walls[0][end_wall_index])
					if temp_distance < shortest:
						shortest = temp_distance
						short_index = end_wall_index
				
				start_loc = spaces_walls[0][short_index]
			
			states[start_loc[0]][start_loc[1]] = 1
			spaces_walls[0].erase(start_loc)
			
			var temp_pos: Array = []
			
			if start_loc[0] + 1 != max_width:
				temp_pos = [start_loc[0] + 1, start_loc[1]]
				if not (temp_pos in spaces_walls[0]) and states[temp_pos[0]][temp_pos[1]] == 0:
					spaces_walls[0].append(temp_pos)
			
			if start_loc[0] != 0:
				temp_pos = [start_loc[0] - 1, start_loc[1]]
				if not (temp_pos in spaces_walls[0]) and states[temp_pos[0]][temp_pos[1]] == 0:
					spaces_walls[0].append(temp_pos)
			
			if start_loc[1] + 1 != max_length:
				temp_pos = [start_loc[0], start_loc[1] + 1]
				if not (temp_pos in spaces_walls[0]) and states[temp_pos[0]][temp_pos[1]] == 0:
					spaces_walls[0].append(temp_pos)
			
			if start_loc[1] != 0:
				temp_pos = [start_loc[0], start_loc[1] - 1]
				if not (temp_pos in spaces_walls[0]) and states[temp_pos[0]][temp_pos[1]] == 0:
					spaces_walls[0].append(temp_pos)
			
			var angle: float = rad2deg(atan2(end_loc[1] - start_loc[1], end_loc[0] - start_loc[0]))
			if angle > 45 and angle <= 135:
				start_loc[1] += 1
			elif angle > 135 or angle <= -135:
				start_loc[0] -= 1
			elif angle > -135 and angle <= -45:
				start_loc[1] -= 1
			elif angle > -45 or angle <= 45:
				start_loc[0] += 1

# finds all disconnected open spaces
func _collect_area(spaces_walls: Array, x_coor: int, y_coor: int) -> Array:
	var checked_locations: Array = []
	var to_be_checked_locations: Array = [[x_coor, y_coor]]
	var walls: Array = []
	
	var working_coors: Array = []
	var temp_pos: Array = []
	while to_be_checked_locations.size() != 0:
		working_coors = to_be_checked_locations.pop_front()
		checked_locations.append(working_coors)
		
		if working_coors[0] + 1 != max_width:
			temp_pos = [working_coors[0] + 1, working_coors[1]]
			if not (temp_pos in checked_locations):
				if states[temp_pos[0]][temp_pos[1]] == 1:
					to_be_checked_locations.append(temp_pos)
				elif states[temp_pos[0]][temp_pos[1]] == 0:
					if not (temp_pos in walls):
						walls.append(temp_pos)
		
		if working_coors[0] != 0:
			temp_pos = [working_coors[0] - 1, working_coors[1]]
			if not (temp_pos in checked_locations):
				if states[temp_pos[0]][temp_pos[1]] == 1:
					to_be_checked_locations.append(temp_pos)
				elif states[temp_pos[0]][temp_pos[1]] == 0:
					if not (temp_pos in walls):
						walls.append(temp_pos)
		
		if working_coors[1] + 1 != max_length:
			temp_pos = [working_coors[0], working_coors[1] + 1]
			if not (temp_pos in checked_locations):
				if states[temp_pos[0]][temp_pos[1]] == 1:
					to_be_checked_locations.append(temp_pos)
				elif states[temp_pos[0]][temp_pos[1]] == 0:
					if not (temp_pos in walls):
						walls.append(temp_pos)
		
		if working_coors[1] != 0:
			temp_pos = [working_coors[0], working_coors[1] - 1]
			if not (temp_pos in checked_locations):
				if states[temp_pos[0]][temp_pos[1]] == 1:
					to_be_checked_locations.append(temp_pos)
				elif states[temp_pos[0]][temp_pos[1]] == 0:
					if not (temp_pos in walls):
						walls.append(temp_pos)
	
	spaces_walls.append(walls)
	return checked_locations

# calculates sector sizes and makes sector lines
func _make_sector_lines() -> void:
	for _i in range(sector_sections):
		sector_x_sizes.append(int(max_width / float(sector_sections)))
		sector_y_sizes.append(int(max_length / float(sector_sections)))
	sector_x_sizes[-1] += max_width % sector_sections
	sector_y_sizes[-1] += max_length % sector_sections
	
	# make x lines
	var x_index_1: int = 0
	for wall_index_1 in range(1, sector_sections):
		x_index_1 = wall_index_1 * sector_x_sizes[wall_index_1 - 1]
		for y_index_1 in range(max_length):
			states[x_index_1][y_index_1] = 2
	
	# make y lines
	var y_index_2: int = 0
	for wall_index_2 in range(1, sector_sections):
		y_index_2 = wall_index_2 * sector_y_sizes[wall_index_2 - 1]
		for x_index_2 in range(max_width):
			states[x_index_2][y_index_2] = 2

# iterates one generation
func _iterate_generation() -> bool:
	# get the number of alive neighbours of each square
	var alive_neighbours: Array = _get_alive_neighbours()
	#print(alive_neighbours)
	
	# merge two lists together of new cells
	var new_state_cells: Array = []
	var new_list: Array = []
	var value: int = 0
	for x_index in range(states.size()):
		new_list = []
		for y_index in range(states[x_index].size()):
			value = alive_neighbours[x_index][y_index]
			new_list.append((value in born_states) or 	# get all of the newly born cells
							(value in alive_states and	# get all of the still alive cells
							 states[x_index][y_index])) # get only the alive cells
		new_state_cells.append(new_list)
	#print(new_state_cells)
	
	var changed: bool = states != new_state_cells
	if changed:
		states = new_state_cells
	
	return changed

# gets the number of alive neighbours for each cell
func _get_alive_neighbours() -> Array:
	# set up blank array
	var out_array: Array = []
	var new_list: Array = []
	for x_index in range(states.size()):
		new_list = []
		for _y_index in range(states[x_index].size()):
			new_list.append(0)
		out_array.append(new_list)
	
	# add to each cell depending on neighbouring cells
	for x_index in range(states.size()):
		for y_index in range(states[x_index].size()):
			if states[x_index][y_index]:
				if x_index != 0:
					out_array[x_index - 1][y_index] += 1			# left
					if y_index != 0:
						out_array[x_index - 1][y_index - 1] += 1	# bottom_left
					if y_index != max_length - 1:
						out_array[x_index - 1][y_index + 1] += 1	# up_left
				
				if x_index != max_width - 1:
					out_array[x_index + 1][y_index] += 1			# right
					if y_index != 0:
						out_array[x_index + 1][y_index - 1] += 1	# bottom_right
					if y_index != max_length - 1:
						out_array[x_index + 1][y_index + 1] += 1	# up_right
				
				if y_index != 0:
					out_array[x_index][y_index - 1] += 1			# bottom
				
				if y_index != max_length - 1:
					out_array[x_index][y_index + 1] += 1			# up
			
	return out_array

# checks if at least one cell at each wall has changed
func _check_all_walls_changed() -> bool:
	var bottom_changed = _OR(states[0])
	var left_changed = _OR(_get_across_y(0, states))
	var top_changed = _OR(states[-1])
	var right_changed = _OR(_get_across_y(-1, states))
	
	return top_changed and left_changed and bottom_changed and right_changed

# fills the states array with all dead cells
func _fill_empty_states() -> void:
	var new_list: Array = []
	for x in max_width:
		new_list = []
		for y in max_length:
			new_list.append(false)
		states.append(new_list)

# fills the centre of the grid with random noise
# besd on size_percentage
func _make_random_noise() -> void:
	# get centre square size
	var centre_width: int = int(ceil(max_width * size_percentage))
	var centre_length: int = int(ceil(max_length * size_percentage))
	
	# get true centre
	var x_centre: float = (max_width + 1) / 2.0
	var y_centre: float = (max_length + 1) / 2.0
	
	# get the starting position of inserting the noise
	var x_start: int = int(floor(x_centre - (centre_width / 2.0)))
	var y_start: int = int(floor(y_centre - (centre_length / 2.0)))
	
	# insert random noise
	for x_index in range(centre_width):
		for y_index in range(centre_length):
			states[x_start + x_index][y_start + y_index] = bool(randi() % 2)

# gets a column of array
func _get_across_y(index: int, full_array: Array) -> Array:
	var out_array: Array = []
	for row in full_array:
		out_array.append(row[index])
	return out_array

# performs boolean OR operation on all elements
func _OR(items: Array) -> bool:
	for value in items:
		if value:
			return true
	return false

# checks if value is out of bounds
func _check_out_of_bounds(x_coor: int, y_coor: int) -> bool:
	return x_coor < 0 or x_coor >= max_width or y_coor < 0 or y_coor >= max_length

# distance formula
func _distance_between(pos_1: Array, pos_2: Array) -> float:
	return sqrt(pow(pos_2[0] - pos_1[0], 2) + pow(pos_2[1] - pos_1[1], 2))
