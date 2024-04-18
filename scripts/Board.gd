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

@export_group("Materials")
@export var light_material: Material
@export var dark_material: Material
@export var cathedral_material: Material
@export var error_material: Material
@export var hover_material: Material
@export var light_territory_material: Material
@export var dark_territory_material: Material
@export var hover_territory_material: Material

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

var _territory_marker = preload("res://objects/board_territory_marker.tscn")

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
var _territory_markers: Array[MeshInstance3D]
var _hover_territory: int = -1 # the index of the territory that is currently being hovered over
var _territories = [
	[], # dark
	[] # light
]
var _territories_tile_maps = [
	{}, # dark
	{} # light
]

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

func to_cell(pos: Vector3):
	var scale = _board_node.scale
	
	var cell_width = scale.x / grid_columns
	var cell_height = scale.y / grid_rows
	
	var col = floor(pos.x / cell_width)
	var row = floor(pos.z / cell_height)
	
	var clamped_col = max(0, min(grid_columns - 1, col))
	var clamped_row = max(0, min(grid_rows - 1, row))
	
	return [
		Vector2(clamped_col, clamped_row),
		col != clamped_col or row != clamped_row
	]

func world_to_local(pos: Vector3) -> Vector3:
	var scale = _board_node.scale
	var half_scale = (scale / 2)
	var min_pos = (_board_node.position - half_scale) * Vector3(1.0, 0.0, 1.0)
	var max_pos = (_board_node.position + half_scale) * Vector3(1.0, 0.0, 1.0)
	
	var x = max(min_pos.x - 1, min(max_pos.x, pos.x))
	var z = max(min_pos.z - 1, min(max_pos.z, pos.z))
	
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

func _refresh_piece_bounds(piece: Piece = _placing_piece, piece_rotation: float = 0.0) -> void:
	var min_x: int = 0
	var min_y: int = 0
	var max_x: int = 0
	var max_y: int = 0
	for offset: Vector2 in piece.get_shape_rotated(piece_rotation):
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
	_set_selected_cell(selected_cell)
	
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
func _is_piece_tile_valid(pos: Vector2, piece: Piece, piece_rotation: float) -> bool:
	var opposing_team = Globals.Team.DARK if _current_team == Globals.Team.LIGHT else Globals.Team.LIGHT
	var pos_hash = _hash_coord(pos.x, pos.y)
	if _territories_tile_maps[opposing_team].has(pos_hash):
		if _territories[opposing_team][_territories_tile_maps[opposing_team][pos_hash]][1]:
			return false
	
	# process the tiles to check
	for shape_offset: Vector2 in piece.get_shape_rotated(piece_rotation):
		if !_is_tile_valid(pos + shape_offset):
			return false
	
	return true
	
func _set_selected_cell(new_cell: Vector2) -> void:
	new_cell.x = clamp(new_cell.x, abs(_placing_piece_min_bound.x), (grid_columns - 1) - _placing_piece_max_bound.x)
	new_cell.y = clamp(new_cell.y, abs(_placing_piece_min_bound.y), (grid_rows - 1) - _placing_piece_max_bound.y)
	
	selected_cell = new_cell

func _hash_coord(x: int, y: int) -> String:
	return str(x,'-',y)

func _flood_fill(x: int, y: int, team: Globals.Team, visited: Dictionary):
	if x < 0 or x >= grid_columns or y < 0 or y >= grid_rows:
		return [true, []]
		
	var coord_hash = _hash_coord(x, y)
	var tile = _board[x][y]
	var tile_piece = tile[2]
	
	if (tile_piece != null and tile_piece.team == team) or visited.has(coord_hash):
		return [true, []]
		
	visited[coord_hash] = true
	var area = [Vector2(x, y)]
	var enclosed = true
	
	var directions = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)]
	for direction in directions:
		var result = _flood_fill(x + direction.x, y + direction.y, team, visited)
		enclosed = enclosed and result[0]
		for new_tile in result[1]:
			area.append(new_tile)
	
	return [enclosed, area]

func _get_territories(team: Globals.Team):
	var visited = {}
	var territories = []
	
	for territory in _territories[team]:
		# if territory is claimed, add it to the visited list
		if territory[1]:
			for tile in territory[0]:
				visited[_hash_coord(tile.x, tile.y)] = true

	for x in range(grid_columns):
		for y in range(grid_rows):
			if !visited.has(_hash_coord(x, y)):
				var result = _flood_fill(x, y, team, visited)
				if result[0] and result[1]:
					territories.append(result[1])
	
	return territories

func _render_territory(territory, material: Material) -> void:
	for cell in territory[0]:
		var marker = _territory_marker.instantiate()
		marker.position = _get_cell_world_position(cell) + Vector3(0, 0.01, 0)
		marker.set_surface_override_material(0, material)
		add_child(marker)
		_territory_markers.append(marker)

func _refresh_render_territories() -> void:
	# delete old territory markers
	for marker in _territory_markers:
		marker.queue_free()
	
	_territory_markers = []
	
	# render the hover territory
	if _hover_territory != -1 and _territories[_current_team][_hover_territory][1] != true:
		_render_territory(_territories[_current_team][_hover_territory], hover_territory_material)
	
	var team_n = 0
	for team_territories in _territories:
		for territory in team_territories:
			if territory[1]:
				_render_territory(territory, dark_territory_material if team_n == Globals.Team.DARK else light_territory_material)
		team_n += 1

func _get_team_valid_territories(team: Globals.Team):
	var unchecked_territories = _get_territories(team)
	var valid_territories = []
	for territory in unchecked_territories:
		if _is_territory_valid(territory, team):
			valid_territories.append([
				territory, # tiles
				false, # claimed
			])
	return valid_territories
	
func _get_territories_tile_map(territories) -> Dictionary:
	var tile_map = {}
	var n = 0
	for territory in territories:
		for tile in territory[0]:
			tile_map[_hash_coord(tile.x, tile.y)] = n
		n += 1
	return tile_map
	
# checks if any given territory is valid for a given team
func _is_territory_valid(territory, team: Globals.Team) -> bool:
	var pieces = {}
	var opposing_piece_count = 0

	for cell in territory:
		var tile = _board[cell.x][cell.y]
		var tile_piece = tile[2]
		if tile_piece and !pieces.has(tile_piece):
			if tile_piece.team != team:
				opposing_piece_count += 1
			pieces[tile_piece] = true
	
	return 1 >= opposing_piece_count

func _claim_territory(territory_index: int):
	var territory = _territories[_current_team][territory_index]
	if !territory[1]:
		# remove piece inside of the territory
		var piece = null
		for cell in territory[0]:
			var tile = _board[cell.x][cell.y]
			if tile[2]:
				if !piece:
					piece = tile[2]
				tile[2] = null
				
		if piece:
			match(piece.team):
				Globals.Team.LIGHT:
					light_piece_counts[piece.type] = light_piece_counts[piece.type] + 1
				Globals.Team.DARK:
					dark_piece_counts[piece.type] = dark_piece_counts[piece.type] + 1
			piece.queue_free()
			
		territory[1] = true
		
func _update_team_territories(team: Globals.Team):
	var new_territories = []
	for territory in _territories[team]:
		if territory[1]:
			new_territories.append(territory)

	var valid = _get_team_valid_territories(team)
	for territory in valid:
		new_territories.append(territory)

	_territories[team] = new_territories
	_territories_tile_maps[team] = _get_territories_tile_map(new_territories)

######### Board Group Signals #########
func set_mouse_position(new_pos: Vector3) -> void:
	var to_cell_result = to_cell(world_to_local(new_pos))
	var hover_cell = to_cell_result[0]
	if _placing_piece:
		_set_selected_cell(hover_cell)

	# handle the hovering piece
	if _turn_count >= 3:
		var tile_map = _territories_tile_maps[_current_team]
		var cell_hash = _hash_coord(hover_cell.x, hover_cell.y)
		var has_hash = tile_map.has(cell_hash)

		if has_hash and _hover_territory != tile_map[cell_hash] and !to_cell_result[1] and !_placing_piece:
			_hover_territory = tile_map[cell_hash]
			var territory = _territories[_current_team][_hover_territory]
			if !territory[1]:
				for cell in territory[0]:
					var tile = _board[cell.x][cell.y]
					var piece = tile[2]
					if piece:
						piece.material = hover_material
			_refresh_render_territories()
		elif (!has_hash or to_cell_result[1] or _placing_piece) and _hover_territory != -1:
			_hover_territory = -1
			for cell in _territories[_current_team][_hover_territory][0]:
				var tile = _board[cell.x][cell.y]
				var piece = tile[2]
				if piece:
					piece.material = _get_piece_material(piece.team)
			_refresh_render_territories()
			
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
		
		# dark team can only claim territory after turn 3 (their second turn)
		if _turn_count >= 3:
			_update_team_territories(Globals.Team.DARK)
		
		# light team can only claim territory after turn 4 (their second turn)
		if _turn_count >= 4:
			_update_team_territories(Globals.Team.LIGHT)
		
		# reset the hover territory
		_hover_territory = -1
		_refresh_render_territories()
		
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

func hud_on_skip_turn_pressed() -> void:
	# don't skip until after turn 4
	if _turn_count > 4:
		_cancel_piece_placement()
		match(_current_team):
			Globals.Team.LIGHT:
				_current_team = Globals.Team.DARK
			Globals.Team.DARK:
				_current_team = Globals.Team.LIGHT
		
		_turn_count += 1
	
######### Signals #########
func _input(event):
	if event is InputEventMouseButton:
		if !event.is_canceled() and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _placing_piece:
				_end_piece_placement()
			elif _hover_territory != - 1:
				# claim territory
				_claim_territory(_hover_territory)
				_hover_territory = -1
				

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
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _placing_piece:
		# update piece position
		var target_pos = _get_cell_world_position(selected_cell)
		_placing_piece.position = _placing_piece.position.lerp(target_pos, delta * 16)
		_placing_piece.rotation_degrees = _placing_piece.rotation_degrees.lerp(Vector3(0.0, _placing_piece_rotation, 0.0), delta * 16)
		
		# check tile validity
		var material = _get_piece_material(_current_team)
		if !_is_piece_tile_valid(selected_cell, _placing_piece, _placing_piece_rotation):
			if _placing_piece.material != error_material:
				_placing_piece.material = error_material
		elif _placing_piece.material != material:
			_placing_piece.material = material
		
		# check inputs
		if Input.is_action_just_pressed("piece_left") or Input.is_action_just_pressed("piece_right") or Input.is_action_just_pressed("piece_up") or Input.is_action_just_pressed("piece_down"):
			var input := Vector3.ZERO
			
			input.x = Input.get_axis("piece_left", "piece_right")
			input.z = Input.get_axis("piece_up", "piece_down")
			
			input = input.rotated(Vector3.UP, camera.rotation.y).normalized()

			_set_selected_cell(Vector2(clamp(round(selected_cell.x + input.x), 0, 9), clamp(round(selected_cell.y + input.z), 0, 9)))
		if Input.is_action_just_pressed("piece_rotate"):
			_placing_piece_rotation += 90.0
			_refresh_piece_bounds(_placing_piece, _placing_piece_rotation)
			_set_selected_cell(selected_cell)
		if Input.is_action_just_pressed("piece_place"):
			_end_piece_placement()
		if Input.is_action_just_pressed("cancel_placement"):
			_cancel_piece_placement()
	pass
