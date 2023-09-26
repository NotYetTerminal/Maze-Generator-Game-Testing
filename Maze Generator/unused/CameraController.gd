extends Camera


func give_size(floor_width: int, floor_length: int) -> void:
	size = (max(floor_width, floor_length) * 1.1)
	translation = Vector3((floor_width / 2.0) - 0.5, 20, (floor_length / 2.0) - 0.5)
