extends Control

######### Variables #########
var _is_ready: bool = false
var _default_toggle_text: String

var _clicking_piece: bool = false
var _dragging_piece: bool = false
var _click_piece_type: Globals.Piece
var _click_piece_start_mouse_pos: Vector2

######### Children #########
@onready var toggle_camera_button = $FlowContainer/Toggle

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

######### Camera Group Signals #########
func on_camera_mode_changed(new_mode: bool) -> void:
	_default_toggle_text = "Top Down" if new_mode else "Isometric"
	if _is_ready:
		toggle_camera_button.text = _default_toggle_text

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
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

# When the camera rotate left button is clicked.
func _on_left_pressed():
	get_tree().call_group("hud", "on_left_pressed")

# When the camera rotate right button is clicked.
func _on_right_pressed():
	get_tree().call_group("hud", "on_right_pressed")

# When the camera toggle button is clicked.
func _on_toggle_pressed():
	get_tree().call_group("hud", "on_toggle_camera_mode")

######### Piece Button Signals #########
func _on_tavern_button_down():
	_begin_click(Globals.Piece.TAVERN)
	pass

func _on_tavern_button_up():
	_end_click()
	pass

func _on_stable_button_down():
	_begin_click(Globals.Piece.STABLE)
	pass # Replace with function body.
	
func _on_stable_button_up():
	_end_click()
	pass

func _on_inn_button_down():
	_begin_click(Globals.Piece.INN)
	pass # Replace with function body.

func _on_inn_button_up():
	_end_click()
	pass

func _on_bridge_button_down():
	_begin_click(Globals.Piece.BRIDGE)
	pass # Replace with function body.

func _on_bridge_button_up():
	_end_click()
	pass

func _on_square_button_down():
	_begin_click(Globals.Piece.SQUARE)
	pass # Replace with function body.

func _on_square_button_up():
	_end_click()
	pass

func _on_manor_button_down():
	_begin_click(Globals.Piece.MANOR)
	pass # Replace with function body.

func _on_manor_button_up():
	_end_click()
	pass

func _on_abbey_button_down():
	_begin_click(Globals.Piece.LIGHT_ABBEY)
	pass # Replace with function body.

func _on_abbey_button_up():
	_end_click()
	pass

func _on_academy_button_down():
	_begin_click(Globals.Piece.LIGHT_ACADEMY)
	pass # Replace with function body.

func _on_academy_button_up():
	_end_click()
	pass

func _on_infirmary_button_down():
	_begin_click(Globals.Piece.INFIRMARY)
	pass # Replace with function body.

func _on_infirmary_button_up():
	_end_click()
	pass

func _on_castle_button_down():
	_begin_click(Globals.Piece.CASTLE)
	pass # Replace with function body.

func _on_castle_button_up():
	_end_click()
	pass
	
func _on_tower_button_down():
	_begin_click(Globals.Piece.TOWER)
	pass # Replace with function body.

func _on_tower_button_up():
	_end_click()
	pass

func _on_cathedral_button_down():
	_begin_click(Globals.Piece.CATHEDRAL)
	pass # Replace with function body.

func _on_cathedral_button_up():
	_end_click()
	pass
