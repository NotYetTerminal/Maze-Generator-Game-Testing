extends Spatial

var columns: int
var rows: int
var colour_counter: float = 0.0
#var last_size = 0

# uses nested lists to store colours
var floor_colours: Array = []


#func _process(_delta: float) -> void:
#	# changing the random colours in real time
#	if last_size != size:
#		_render()
#		last_size = size
#	pass


# called by main to set size
func set_maze_size(width: int, length: int) -> void:
	columns = width
	rows = length
	_fill_with_black()
	_reset_colour_to()
	#_fill_with_randoms()
	_set_mesh_ratio()
	_render()


# fills the vectors array with white
func _fill_with_black() -> void:
	var new_list: Array = []
	for _x in range(columns):
		new_list = []
		for _y in range(rows):
			new_list.append(Color.black)
		floor_colours.append(new_list)


# resets colours array to white
func _reset_colour_to(reset_color: Color = Color.white) -> void:
	for x_index in range(floor_colours.size()):
		for y_index in range(floor_colours[x_index].size()):
			if floor_colours[x_index][y_index] != reset_color:
				floor_colours[x_index][y_index] = reset_color


# fills the vectors array with randoms
#func _fill_with_randoms() -> void:
#	floor_colours.clear()
#	for _index in range(columns * rows):
#		floor_colours.append(Color(randf(), randf(), randf()))


# sets the mesh side length ratio so it matches up with the maze size
func _set_mesh_ratio():
	var mesh: Mesh = $MeshInstance.get_mesh()
	mesh.set("size", Vector2(columns * 2, rows * 2))
	translation = Vector3((columns / 2.0) - 0.5, -0.5, (rows / 2.0) - 0.5)


# packs the data together and sends it to the shader
func _render() -> void:	
	# packs data into the texture
	var texture = _makeTexture(columns, rows, floor_colours)
	
	# sends the texture over to the shader
	var material = $MeshInstance.get_active_material(0)
	material.set_shader_param("vectors", texture)
	material.set_shader_param("vectorsTextureWidth", float(columns))
	material.set_shader_param("vectorsTextureHeight", float(rows))


#https://www.godotforums.org/discussion/27487/passing-an-array-to-a-shader
# takes in a width and length for the size of the texture
# vectors is an array of Color
# preferably the vectors.size() is width * length to show all data
func _makeTexture(width: int, length: int, array_data: Array) -> ImageTexture:
	var w = width
	var l = length
	var img = Image.new()
	img.create(w, l, false, Image.FORMAT_RGBAF)
	img.lock()
	#var x: int
	#var y: int
#	print(array_data.size())
#	print(length)
#	print(width)
#	for i in range(array_data.size()):
#		y = i / w
#		x = i % w
	for x_index in range(array_data.size()):
		for y_index in range(array_data[x_index].size()):
			img.set_pixel(x_index, y_index, array_data[x_index][y_index])
	img.unlock()
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex


# converts xy coordinate to index for array
#func _get_array_index(coor: Vector2) -> int:
#	return int((coor.x * columns) + coor.y)


# sets the path as a colour
#func update_path(path_coors: Array) -> void:
#	_fill_with_white()
#	for coor in path_coors:
#		var index = _get_array_index(coor)
#		floor_colours[index] = Color.yellow
#	_render()


# sets the state of the floor tiles
func update_floor_states(floor_states: Array) -> void:
	for x_index in range(floor_states.size()):
		for y_index in range(floor_states[x_index].size()):
			match int(floor_states[x_index][y_index]):
				0:
					floor_colours[x_index][y_index] = Color.black
				1:
					floor_colours[x_index][y_index] = Color.white
				2:
					floor_colours[x_index][y_index] = Color.darkblue
				3:
					floor_colours[x_index][y_index] = Color.red
				4:
					floor_colours[x_index][y_index] = Color.darkturquoise
				5:
					floor_colours[x_index][y_index] = Color.green
				6:
					floor_colours[x_index][y_index] = Color.purple
				7:
					floor_colours[x_index][y_index] = Color.pink
				8:
					floor_colours[x_index][y_index] = Color.burlywood
				9:
					floor_colours[x_index][y_index] = Color.yellow
				10:
					floor_colours[x_index][y_index] = Color.darkgreen
				_:
					floor_colours[x_index][y_index] = Color.magenta
	_render()

# same but has colour
func update_floor_states_colourful(floor_states: Array) -> void:
	for x_index in range(floor_states.size()):
		for y_index in range(floor_states[x_index].size()):
			if floor_states[x_index][y_index]:
				if floor_colours[x_index][y_index] == Color.black:
					floor_colours[x_index][y_index] = Color.from_hsv(colour_counter, 1, 1)
			else:
				floor_colours[x_index][y_index] = Color.black
	colour_counter += 0.004
	_render()


# reacts to signal from main
# updates highlight place
#func update_floor(highlight_coor: Vector2) -> void:
#	_fill_with_white()
#	var index = _get_array_index(highlight_coor)
#	floor_colours[index] = Color.yellow
#	_render()
