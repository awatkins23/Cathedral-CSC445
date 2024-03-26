extends Node3D

######### Export Variables #########
@export_group("Properties")
@export var target: Node
@export var isometric: bool

#var mouse_enabled := false:
	#set(value):
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
		#mouse_enabled = value

######### Variables #########
var camera_rotation: Vector3
var mouse_velocity: Vector2

######### Children #########
@onready var camera = $Camera

######### Functions #########
func set_mode(new_mode: bool) -> void:
	if isometric == new_mode:
		return
	isometric = new_mode
	camera_rotation = Vector3(-45.0, camera_rotation.y - 45.0, 0.0) if isometric else Vector3(-90.0, camera_rotation.y + 45.0, 0.0)
	get_tree().call_group("camera", "on_camera_mode_changed", isometric)
	rotation_updated()

func rotation_updated() -> void:
	get_tree().call_group("camera", "on_camera_rotation_changed", camera_rotation)

func toggle_mode() -> void:
	set_mode(!isometric)

func rotate_left() -> void:
	camera_rotation.y = camera_rotation.y - 90.0
	rotation_updated()
	
func rotate_right() -> void:
	camera_rotation.y = camera_rotation.y + 90.0
	rotation_updated()

######### HUD Group Signals #########
func on_toggle_camera_mode():
	toggle_mode()

func on_left_pressed():
	rotate_left()
	
func on_right_pressed():
	rotate_right()

######### Signals #########
func _ready():
	set_mode(true)
	position = target.position
	rotation_degrees = camera_rotation
	camera.position = Vector3(0.0, 0.0, 10.0)
	pass
	
func _input(event):
	#if event is InputEventMouse:
		#mouse_enabled = event.button_mask == MOUSE_BUTTON_MASK_RIGHT
	#if mouse_enabled and (event is InputEventMouseMotion):
		#mouse_velocity = (event as InputEventMouseMotion).relative * mouse_strength
	if event is InputEventMouseMotion:
		var viewport = get_viewport()
		var mouse_pos = viewport.get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var dir = camera.project_ray_normal(mouse_pos)
		var intersect = Plane(Vector3.UP, 0.0).intersects_ray(from, dir)
		get_tree().call_group("board", "set_mouse_position", intersect)

func _physics_process(delta):
	# check inputs
	if Input.is_action_just_pressed("camera_toggle"):
		toggle_mode()
	if Input.is_action_just_pressed("camera_right"):
		rotate_right()
	if Input.is_action_just_pressed("camera_left"):
		rotate_left()
	if Input.is_action_just_pressed("camera_top_down"):
		set_mode(false)
	if Input.is_action_just_pressed("camera_isometric"):
		set_mode(true)
	
	# Set position and rotation to targets
	
	position = position.lerp(target.position, delta * 12)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 12)
	
	#camera.position = camera.position.lerp(8 * delta)
	
	#handle_input(delta)

# Handle input

#func handle_input(delta):
	#
	#var input := Vector3.ZERO
#
	## Rotation
	#camera_rotation += Vector3(
		#-mouse_velocity.y if mouse_enabled else -input.x, 
		#-mouse_velocity.x if mouse_enabled else -input.y, 
		#0)  * rotation_speed * delta
	#camera_rotation.x = clamp(camera_rotation.x, -89, -10)
	#mouse_velocity = Vector2.ZERO
	#
	## Zooming
	#
	#zoom += Input.get_axis("zoom_in", "zoom_out") * zoom_speed * delta
	#zoom = clamp(zoom, zoom_maximum, zoom_minimum)
