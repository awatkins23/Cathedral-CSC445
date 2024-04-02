extends Node3D

######### Export Variables #########
@export_group("Board Config")
@export var grid_columns: int = 10
@export var grid_rows: int = 10

@export_group("Components")
@export var camera: Node3D

# piece counts mapped by type. i.e light_piece_counts[Piece.TAVERN] is the number of placable taverns.
@export_group("Piece Counts")
@export var light_piece_counts: Array[int] = [
	2, 2, 2, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1
]
@export var dark_piece_counts: Array[int] = [
	2, 2, 2, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0
]

@export_group("Teams")
@export var light_material: Material
@export var dark_material: Material
@export var cathedral_material: Material
@export var error_material: Material

######### Preload Pieces #########
var piece_scenes: Array[PackedScene] = [
	preload("res://objects/pieces/tavern.tscn"), 		# Tavern
	preload("res://objects/pieces/stable.tscn"), 		# Stable
	preload("res://objects/pieces/inn.tscn"), 			# Inn
	preload("res://objects/pieces/bridge.tscn"), 		# Bridge
	preload("res://objects/pieces/square.tscn"), 		# Square
	preload("res://objects/pieces/manor.tscn"), 		# Manor
	preload("res://objects/pieces/light_abbey.tscn"), 	# Light Abbey
	preload("res://objects/pieces/dark_abbey.tscn"), 	# Dark Abbey
	preload("res://objects/pieces/light_academy.tscn"), # Light Academy
	preload("res://objects/pieces/dark_academy.tscn"), 	# Dark Academy
	preload("res://objects/pieces/infirmary.tscn"), 	# Infirmary
	preload("res://objects/pieces/castle.tscn"), 		# Castle
	preload("res://objects/pieces/tower.tscn"), 		# Tower
	preload("res://objects/pieces/cathedral.tscn"), 	# Cathedral
]

######### Script Variables #########
var selected_cell: Vector2

# placing piece information
var _placing_piece_rotation: float
var _placing_piece_type: Globals.Piece
var _placing_piece_min_bound: Vector2
var _placing_piece_max_bound: Vector2
var _placing_piece: Piece

var _board = [] # Array[Array[Tile]]
var _placed_pieces: Array[Piece] = []

# game info
var _current_team: Globals.Team = Globals.Team.CATHEDRAL
var _turn_count: int = 0
######### Children #########
@onready var _board_node = $GridLines

######### Functions #########
func _get_piece_material(team: Globals.Team) -> Material:
	match(team):
		Globals.Team.LIGHT:
			return light_material
		Globals.Team.DARK:
			return dark_material
		Globals.Team.CATHEDRAL:
			return cathedral_material
	return light_material

func to_cell(pos: Vector3) -> Vector2:
	var scale = _board_node.scale
	
	var cell_width = scale.x / grid_columns
	var cell_height = scale.y / grid_rows
	
	var col = max(0, min(grid_columns - 1, floor(pos.x / cell_width)))
	var row = max(0, min(grid_rows - 1, floor(pos.z / cell_height)))
	
	return Vector2(col, row)

func world_to_local(pos: Vector3) -> Vector3:
	var scale = _board_node.scale
	var half_scale = (scale / 2)
	var min_pos = (_board_node.position - half_scale) * Vector3(1.0, 0.0, 1.0)
	var max_pos = (_board_node.position + half_scale) * Vector3(1.0, 0.0, 1.0)
	
	var x = max(min_pos.x, min(max_pos.x, pos.x))
	var z = max(min_pos.z, min(max_pos.z, pos.z))
	
	x = max_pos.x + x
	z = max_pos.z + z

	return Vector3(x, pos.y, z) 

func _get_cell_world_position(cell: Vector2) -> Vector3:
	var scale = _board_node.scale
	var half_scale = (scale / 2)
	var cell_width = scale.x / grid_columns
	var cell_height = scale.y / grid_rows
	return Vector3((cell.x * cell_width) - half_scale.x, _board_node.position.y, (cell.y * cell_height) - half_scale.y) + Vector3(cell_width / 2.0, 0.0, cell_height / 2.0)

func _place_piece(type: Globals.Piece, team: Globals.Team, cell: Vector2, rotation: float) -> bool:
	# load the piece
	var piece_scene: PackedScene = piece_scenes[type]
	if piece_scene == null:
		return false
	
	# instantiate the piece
	var piece: Piece = piece_scene.instantiate()
	
	# check if the cell is valid
	if !_is_piece_tile_valid(cell, piece, rotation):
		piece.queue_free()
		return false
	
	# set piece properties
	piece.column = cell.x
	piece.row = cell.y
	piece.team = team
	
	# set material
	piece.material = _get_piece_material(team)
	
	# set piece position & rotation
	piece.position = _get_cell_world_position(cell)
	piece.rotation_degrees = Vector3(0.0, rotation, 0.0)
	
	# add to pieces table
	_placed_pieces.append(piece)
	
	# update tiles
	for shape_offset: Vector2 in piece.get_shape_rotated(rotation):
		_board[cell.x + shape_offset.x][cell.y + shape_offset.y][2] = piece
	
	# play animation
	piece.animator.play("piece_animations/place_piece")
	# add to board
	add_child(piece)
	
	return true

func _refresh_piece_bounds(piece: Piece = _placing_piece, rotation: float = 0.0) -> void:
	var min_x: int = 0
	var min_y: int = 0
	var max_x: int = 0
	var max_y: int = 0
	for offset: Vector2 in piece.get_shape_rotated(rotation):
		min_x = min(min_x, offset.x)
		min_y = min(min_y, offset.y)
		max_x = max(max_x, offset.x)
		max_y = max(max_y, offset.y)
		
	_placing_piece_min_bound = Vector2(min_x, min_y)
	_placing_piece_max_bound = Vector2(max_x, max_y)

func _begin_piece_placement(type: Globals.Piece, team: Globals.Team) -> void:
	# debounce
	if _placing_piece:
		return
	
	# set the type of the piece that we're placing
	_placing_piece_type = type

	# check if the piece is loaded
	var piece_scene: PackedScene = piece_scenes[type]
	if piece_scene == null:
		return

	# reset rotation to normal
	_placing_piece_rotation = 0.0
	
	# load the piece into the scene and set it as a child of the board
	var piece: Piece = piece_scene.instantiate()
	piece.team = team
	piece.material = _get_piece_material(team)

	# calculate min and max bound
	_refresh_piece_bounds(piece)
	
	# set default position
	_set_selected_cell(selected_cell, piece)
	
	# add to board
	add_child(piece)
	
	# set the placing piece variable
	_placing_piece = piece
	
	# signal on piece placement signal
	get_tree().call_group("board", "on_piece_placement_begin", type)
	 
func _end_piece_placement() -> bool:
	if !_placing_piece:
		return false
	
	var type = _placing_piece.type
	
	var status = _place_piece(
		type,
		_placing_piece.team,
		selected_cell,
		_placing_piece_rotation
	)
	
	# delete the scene
	_placing_piece.queue_free()
	
	# call on end
	get_tree().call_group("board", "on_piece_placement_end", type, status)
	
	# reset variables
	_placing_piece = null
	
	return status
	
func _cancel_piece_placement() -> void:
	if _placing_piece:
		_placing_piece.queue_free()
	_placing_piece = null
# checks if a tile is valid
func _is_tile_valid(pos: Vector2) -> bool:
	# check if the tile is in bounds
	var x = pos.x
	var y = pos.y
	if x > (grid_columns - 1) or y > (grid_rows - 1) or 0 > x or 0 > y:
		return false
		
	# check if the tile is taken
	var tile = _board[x][y]
	return tile[2] == null

# checks if a tile for a piece is valid
func _is_piece_tile_valid(pos: Vector2, piece: Piece, rotation: float) -> bool:
	# process the tiles to check
	for shape_offset: Vector2 in piece.get_shape_rotated(rotation):
		if !_is_tile_valid(pos + shape_offset):
			return false
	
	return true
	
func _set_selected_cell(new_cell: Vector2, piece: Piece) -> void:
	new_cell.x = clamp(new_cell.x, abs(_placing_piece_min_bound.x), (grid_columns - 1) - _placing_piece_max_bound.x)
	new_cell.y = clamp(new_cell.y, abs(_placing_piece_min_bound.y), (grid_rows - 1) - _placing_piece_max_bound.y)
	
	selected_cell = new_cell

######### Board Group Signals #########
func set_mouse_position(new_pos: Vector3) -> void:
	if _placing_piece:
		_set_selected_cell(to_cell(world_to_local(new_pos)), _placing_piece)
		
#func on_piece_placement_begin(piece: Globals.Piece) -> void:
#	return

# called when piece placement ends
func on_piece_placement_end(piece: Globals.Piece, success: bool) -> void:
	if !_placing_piece:
		return
		
	if success:
		match(_current_team):
			Globals.Team.CATHEDRAL:
				light_piece_counts[Globals.Piece.CATHEDRAL] = light_piece_counts[Globals.Piece.CATHEDRAL] - 1
				_current_team = Globals.Team.DARK
			Globals.Team.LIGHT:
				light_piece_counts[piece] = light_piece_counts[piece] - 1
				_current_team = Globals.Team.DARK
			Globals.Team.DARK:
				dark_piece_counts[piece] = dark_piece_counts[piece] - 1
				_current_team = Globals.Team.LIGHT
		
		_turn_count += 1
		
func hud_begin_piece_placement(piece: Globals.Piece) -> void:
	_cancel_piece_placement()
	match(_current_team):
		Globals.Team.CATHEDRAL:
			var remaining = light_piece_counts[Globals.Piece.CATHEDRAL]
			if remaining > 0:
				_begin_piece_placement(Globals.Piece.CATHEDRAL, _current_team)
		Globals.Team.LIGHT:
			match(piece):
				Globals.Piece.DARK_ABBEY:
					piece = Globals.Piece.LIGHT_ABBEY
				Globals.Piece.DARK_ACADEMY:
					piece = Globals.Piece.LIGHT_ACADEMY
					
			var remaining = light_piece_counts[piece]
			if remaining > 0:
				_begin_piece_placement(piece, _current_team)
		Globals.Team.DARK:
			match(piece):
				Globals.Piece.LIGHT_ABBEY:
					piece = Globals.Piece.DARK_ABBEY
				Globals.Piece.LIGHT_ACADEMY:
					piece = Globals.Piece.DARK_ACADEMY
					
			var remaining = dark_piece_counts[piece]
			if remaining > 0:
				_begin_piece_placement(piece, _current_team)

func hud_end_piece_placement() -> void:
	_end_piece_placement()

func hud_cancel_piece_placement() -> void:
	_cancel_piece_placement()
	
######### Signals #########
func _input(event):
	if event is InputEventMouseButton:
		if !event.is_canceled() and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_end_piece_placement()

func _ready():
	# initialize the board variable
	for col_n in range(grid_columns):
		var row = []
		for row_n in range(grid_rows):
			row.append([
				col_n,
				row_n,
				null
			])
		_board.append(row);
	
	# default board set up
	#_place_piece(Globals.Piece.INFIRMARY, Globals.Team.DARK, Vector2(5.0, 5.0), 0.0)
	#_place_piece(Globals.Piece.TAVERN, Globals.Team.LIGHT, Vector2(0.0, 0.0), 0.0)
	#_place_piece(Globals.Piece.TAVERN, Globals.Team.DARK, Vector2(2.0, 0.0), 0.0)
	#_place_piece(Globals.Piece.TAVERN, Globals.Team.CATHEDRAL, Vector2(3.0, 0.0), 0.0)
	#_place_piece(Globals.Piece.CATHEDRAL, Globals.Team.CATHEDRAL, Vector2(1.0, 1.0), 90.0)
	
	# place piece
	#_begin_piece_placement(Globals.Piece.CATHEDRAL, Globals.Team.CATHEDRAL)
	#_begin_piece_placement(Globals.Piece.CATHEDRAL, Globals.Team.CATHEDRAL)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _placing_piece:
		# update piece position
		var target_pos = _get_cell_world_position(selected_cell)
		_placing_piece.position = _placing_piece.position.lerp(target_pos, delta * 16)
		_placing_piece.rotation_degrees = _placing_piece.rotation_degrees.lerp(Vector3(0.0, _placing_piece_rotation, 0.0), delta * 16)
		
		# check tile validity
		var material = _get_piece_material(_current_team)
		if !_is_piece_tile_valid(selected_cell, _placing_piece, _placing_piece_rotation) and _placing_piece.material != error_material:
			_placing_piece.material = error_material
		elif _placing_piece.material != material:
			_placing_piece.material = material
		
		# check inputs
		if Input.is_action_just_pressed("piece_left") or Input.is_action_just_pressed("piece_right") or Input.is_action_just_pressed("piece_up") or Input.is_action_just_pressed("piece_down"):
			var input := Vector3.ZERO
			
			input.x = Input.get_axis("piece_left", "piece_right")
			input.z = Input.get_axis("piece_up", "piece_down")
			
			input = input.rotated(Vector3.UP, camera.rotation.y).normalized()

			_set_selected_cell(Vector2(clamp(round(selected_cell.x + input.x), 0, 9), clamp(round(selected_cell.y + input.z), 0, 9)), _placing_piece)
		if Input.is_action_just_pressed("piece_rotate"):
			_placing_piece_rotation += 90.0
			_refresh_piece_bounds(_placing_piece, _placing_piece_rotation)
			_set_selected_cell(selected_cell, _placing_piece)
		if Input.is_action_just_pressed("piece_place"):
			_end_piece_placement()
		if Input.is_action_just_pressed("cancel_placement"):
			_cancel_piece_placement()
	pass
