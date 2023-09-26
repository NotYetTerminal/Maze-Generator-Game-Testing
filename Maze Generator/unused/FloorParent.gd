extends Spatial

export (PackedScene) var floor_tile_scene

var width: int
var length: int
var floor_list: Array = []


func _spawn_floor_tiles():
	for x in width:
		for z in length:
			var new_tile = floor_tile_scene.instance()
			add_child(new_tile)
			new_tile.translation = Vector3(x, 0, z)
			floor_list.append(new_tile)


func set_size(in_width: int, in_length: int) -> void:
	width = in_width
	length = in_length
	_spawn_floor_tiles()
	#spawn_tiles = true

# Show spawning slowly
#var spawn_tiles: bool = false
#var current_x: int = 0
#var current_z: int = 0


#func _process(delta: float) -> void:
#	for i in range(length):
#		_spawn_tile()


#func _spawn_tile():
#	if spawn_tiles:
#		if current_z < length:
#			var new_tile = floor_tile_scene.instance()
#			add_child(new_tile)
#			new_tile.translation = Vector3(current_x, 0, current_z)
#			floor_list.append(new_tile)
#			current_z += 1
#		else:
#			if current_x < width:
#				current_z = 0
#				current_x += 1
#			else:
#				spawn_tiles = false
