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

var _turn_end_visible: bool = false

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

var _team_names = [
	"DARK",
	"LIGHT",
	"LIGHT"
]

var _piece_tile_colors = [
	Color("ffd28f"),
	Color("5f3900"),
	Color("7b7b7b")
]

# preload themes
var _themes = [
	preload("res://themes/dark_theme.tres"),
	preload("res://themes/light_theme.tres"),
	null
]

var _piece_button = preload("res://objects/hud/piece_button.tscn")
var _loaded_buttons: Array[Control] = []

var _turn_change_transition = preload("res://objects/hud/turn_change.tscn")
var _game_end_node = preload("res://objects/hud/game_end.tscn")

# format strings
var _turn_status_format_string = "%s - Turn %s"
var _turn_format_string = "Turn %s"

######### Children #########
@onready var _piece_buttons_container = $PieceButtons
@onready var _turn_status_label = $Stats/TurnStatus
@onready var _select_sound_player = $SelectSoundPlayer
@onready var _end_turn_animation_player = $EndTurnButtonContainer/EndTurnAnimationPlayer
@onready var _keybinds_container = $Keybinds
@onready var _camera_controls = $CameraControls
@onready var _stats_container = $Stats

######### Functions #########
func _refresh_theme() -> void:
	var new_theme = _themes[_current_team]
	if new_theme:
		theme = new_theme

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

func _create_piece_button(piece: Globals.Piece, enter_delay: float) -> void:
	var button = _piece_button.instantiate()
	
	# set properties
	button.piece_type = piece
	button.piece_name = _piece_names[piece]
	button.texture = _piece_tile_textures[piece]
	button.texture_color = _piece_tile_colors[_current_team]
	button.enter_animation_delay = enter_delay
	
	# add to the container
	_piece_buttons_container.add_child(button)
	
	# append to _loaded_buttons array
	_loaded_buttons.append(button)

func _delete_piece_buttons() -> void:
	# delete old piece buttons
	for button in _loaded_buttons:
		button.queue_free()
	_loaded_buttons = []
	
func _load_piece_buttons() -> void:
	# ensure that there is a _piece_counts array to iterate
	if !_piece_counts:
		return

	# load new piece buttons
	if _current_team == 2:
		_create_piece_button(Globals.Piece.CATHEDRAL, 0.0)
	else:
		var piece = 0
		var button_n = 0
		for count in _piece_counts:
			for n in range(count):
				_create_piece_button(piece, 0.02 * button_n)
				button_n += 1
			piece += 1

func _display_turn_change_transition() -> Control:
	var scene = _turn_change_transition.instantiate()
	
	scene.title = _team_names[_current_team]
	scene.subtitle = _turn_format_string % [ _turn_count + 1 ]
	
	add_child(scene)
	
	return scene
	
func _display_game_end(state: Globals.GameWinState, dark_points: int, light_points: int) -> void:
	var scene = _game_end_node.instantiate()
	
	scene.state = state
	scene.dark_points = dark_points
	scene.light_points = light_points
	
	# reset the hud
	_reset_hud()
	
	# hide the HUD
	_keybinds_container.visible = false
	_stats_container.visible = false
	_camera_controls.visible = false
	
	# add child to scene
	add_child(scene)

func _reset_hud() -> void:
	# delete old buttons
	_delete_piece_buttons()
	
	# hide turn end button if possible
	if _turn_end_visible:
		_turn_end_visible = false
		_end_turn_animation_player.play("end_turn_out")

func _update_hud() -> void:
	# set the theme to the one of the current team
	_refresh_theme()
	
	# show turn change transition
	var changer = _display_turn_change_transition()
	
	_turn_status_label.text = _turn_status_format_string % [_team_names[_current_team], _turn_count + 1]
	
	# reset the hud
	_reset_hud()
	
	await changer.tree_exited
	_load_piece_buttons()

######### Board Group Signals #########
func board_on_turn_begin(turn_count: int, team: Globals.Team, piece_counts: Array[int], is_cpu: bool):
	if is_cpu:
		return
		
	_turn_count = turn_count
	_current_team = team
	_piece_counts = piece_counts
	if _is_ready:
		_update_hud()

func board_on_game_end(win_state: Globals.GameWinState, dark_points: int, light_points: int) -> void:
	_display_game_end(win_state, dark_points, light_points)
	
func board_on_territory_phase_start() -> void:
	# delete old buttons
	_delete_piece_buttons()
		
	_turn_end_visible = true
	_end_turn_animation_player.play("end_turn_in")

######### HUD Group Signals #########
func hud_on_piece_button_down(piece_type: Globals.Piece):
	_begin_click(piece_type)
	
func hud_on_piece_button_up(piece_type: Globals.Piece):
	_select_sound_player.play()
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
	
	_end_turn_animation_player.play("DEFAULT")
	_update_hud()

# When the camera rotate left button is clicked.
func _on_left_pressed():
	_select_sound_player.play()
	get_tree().call_group("hud", "on_left_pressed")

# When the camera rotate right button is clicked.
func _on_right_pressed():
	_select_sound_player.play()
	get_tree().call_group("hud", "on_right_pressed")

# When the camera toggle button is clicked.
func _on_toggle_pressed():
	_select_sound_player.play()
	get_tree().call_group("hud", "on_toggle_camera_mode")

func _on_menu_pressed():
	_select_sound_player.play()
	SceneSwitcher.transition_to_main_menu()

func _on_end_turn_button_pressed():
	_select_sound_player.play()
	get_tree().call_group("hud", "hud_on_turn_end_pressed")
