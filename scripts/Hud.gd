extends Control

######### Variables #########
var _is_ready: bool = false
var _default_toggle_text: String

var _clicking_piece: bool = false
var _dragging_piece: bool = false
var _click_piece_type: Globals.Piece
var _click_piece_start_mouse_pos: Vector2

var _turn_count: int
var _current_team: Globals.Team
var _piece_counts: Array[int]

######### Preload Piece Tile Textures #########
var _piece_tile_textures: Array[CompressedTexture2D] = [
	preload("res://imports/textures/tavern_tiles.png"), 		# Tavern
	preload("res://imports/textures/stable_tiles.png"), 		# Stable
	preload("res://imports/textures/inn_tiles.png"), 			# Inn
	preload("res://imports/textures/bridge_tiles.png"), 		# Bridge
	preload("res://imports/textures/square_tiles.png"), 		# Square
	preload("res://imports/textures/manor_tiles.png"), 		# Manor
	preload("res://imports/textures/light_abbey_tiles.png"), 	# Light Abbey
	preload("res://imports/textures/dark_abbey_tiles.png"), 	# Dark Abbey
	preload("res://imports/textures/light_academy_tiles.png"), # Light Academy
	preload("res://imports/textures/dark_academy_tiles.png"), 	# Dark Academy
	preload("res://imports/textures/infirmary_tiles.png"), 	# Infirmary
	preload("res://imports/textures/castle_tiles.png"), 		# Castle
	preload("res://imports/textures/tower_tiles.png"), 		# Tower
	preload("res://imports/textures/cathedral_tiles.png"), 	# Cathedral
]

var _piece_names = [
	"Tavern",
	"Stable",
	"Inn",
	"Bridge",
	"Square",
	"Manor",
	"Abbey",
	"Abbey",
	"Academy",
	"Academy",
	"Infirmary",
	"Castle",
	"Tower",
	"Cathedral"
]

var _piece_tile_colors = [
	Color("ffd28f"),
	Color("5f3900"),
	Color("7b7b7b")
]

var _piece_button = preload("res://objects/hud/piece_button.tscn")
var _loaded_buttons: Array[Control] = []

######### Children #########
@onready var toggle_camera_button = $FlowContainer/Toggle
@onready var _piece_buttons_container = $PieceButtons

######### Functions #########
func _begin_click(piece_type: Globals.Piece) -> void:
	# debounce
	if _clicking_piece:
		return
	
	_clicking_piece = true
	_click_piece_type = piece_type
	
	# set start mouse position
	var viewport = get_viewport()
	_click_piece_start_mouse_pos = viewport.get_mouse_position()
	
func _end_click() -> void:
	if !_clicking_piece:
		return
		
	if _dragging_piece:
		var viewport = get_viewport()
		var mouse_pos = viewport.get_mouse_position()
		if (_click_piece_start_mouse_pos - mouse_pos).x >= 200:
			get_tree().call_group("board", "hud_end_piece_placement")
		else:
			get_tree().call_group("board", "hud_cancel_piece_placement")
		_dragging_piece = false
	else:
		get_tree().call_group("board", "hud_begin_piece_placement", _click_piece_type)
		
	_clicking_piece = false

func _create_piece_button(piece: Globals.Piece) -> void:
	var button = _piece_button.instantiate()
	
	# set properties
	button.piece_type = piece
	button.piece_name = _piece_names[piece]
	button.texture = _piece_tile_textures[piece]
	button.texture_color = _piece_tile_colors[_current_team]
	
	# add to the container
	_piece_buttons_container.add_child(button)
	
	# append to _loaded_buttons array
	_loaded_buttons.append(button)

func _load_piece_buttons() -> void:
	# ensure that there is a _piece_counts array to iterate
	if !_piece_counts:
		return
	
	# delete old piece buttons
	for button in _loaded_buttons:
		button.queue_free()
			
	_loaded_buttons = []
		
	# load new piece buttons
	if _current_team == 2:
		_create_piece_button(Globals.Piece.CATHEDRAL)
	else:
		var piece = 0
		for count in _piece_counts:
			for n in range(count):
				_create_piece_button(piece)
			piece += 1

######### Camera Group Signals #########
func on_camera_mode_changed(new_mode: bool) -> void:
	_default_toggle_text = "Top Down" if new_mode else "Isometric"
	if _is_ready:
		toggle_camera_button.text = _default_toggle_text

######### Board Group Signals #########
func board_on_turn_begin(turn_count: int, team: Globals.Team, piece_counts: Array[int]):
	_turn_count = turn_count
	_current_team = team
	_piece_counts = piece_counts
	
	if _is_ready:
		_load_piece_buttons()

######### HUD Group Signals #########
func hud_on_piece_button_down(piece_type: Globals.Piece):
	_begin_click(piece_type)
	
func hud_on_piece_button_up(piece_type: Globals.Piece):
	_end_click()

######### Signals #########
func _input(event):
	if event is InputEventMouseMotion and _clicking_piece and !_dragging_piece:
		var viewport = get_viewport()
		var mouse_pos = viewport.get_mouse_position()
		
		var diff = _click_piece_start_mouse_pos - mouse_pos
		if diff.x >= 200 and !_dragging_piece:
			#start dragging
			_dragging_piece = true
			get_tree().call_group("board", "hud_begin_piece_placement", _click_piece_type)
		

## Called when the node enters the scene tree for the first time.
func _ready():
	_is_ready = true
	toggle_camera_button.text = _default_toggle_text
	
	_load_piece_buttons()

# When the camera rotate left button is clicked.
func _on_left_pressed():
	get_tree().call_group("hud", "on_left_pressed")

# When the camera rotate right button is clicked.
func _on_right_pressed():
	get_tree().call_group("hud", "on_right_pressed")

# When the camera toggle button is clicked.
func _on_toggle_pressed():
	get_tree().call_group("hud", "on_toggle_camera_mode")

func _on_skip_pressed():
	get_tree().call_group("hud", "hud_on_skip_turn_pressed")
