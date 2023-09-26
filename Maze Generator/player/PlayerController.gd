extends KinematicBody

var mouse_sensitivity: float = 0.1
var speed: float = 1.5
var h_acceleration: float = 12.0

var direction: Vector3 = Vector3.ZERO
var h_velocity: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO

var camera_fov: float = 70.0
var shake_intensity: float = 1

var stamina: float = 100.0
var stamina_recharge_delay: float = 1
var stamina_empty: bool = false

onready var head = $Head
onready var camera = $Head/Camera
onready var stamina_bar = $UI/StaminaBar

# captures mouse in screen
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# takes in movement from moise
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

# takes in movement wasd
# and implements running
func _physics_process(delta: float) -> void:
	direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	
	direction = direction.normalized()
	
	if Input.is_action_pressed("run") and not stamina_empty:
		direction *= 1.5
		camera_fov += 200 * delta
		stamina -= 50 * delta
		if stamina <= 0:
			stamina_empty = true
		stamina_recharge_delay = 1
		
		camera.h_offset = randf() * shake_intensity * delta
		camera.v_offset = randf() * shake_intensity * delta
		camera.rotation_degrees = Vector3(0, 0, randf() * 100 * shake_intensity * delta)
	else:
		camera_fov -= 200 * delta
		if stamina_recharge_delay <= 0:
			stamina += 50 * delta
			if stamina >= 100:
				stamina_empty = false
		else:
			stamina_recharge_delay -= delta
		
		camera.h_offset = 0
		camera.v_offset = 0
		camera.rotation_degrees = Vector3.ZERO
	
	camera_fov = clamp(camera_fov, 70, 85)
	camera.fov = camera_fov
	stamina = clamp(stamina, 0, 100)
	stamina_bar.value = stamina
	
	h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
	movement.z = h_velocity.z
	movement.x = h_velocity.x
	
	var _t: Vector3 = move_and_slide(movement, Vector3.UP)
