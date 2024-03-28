extends Control

######### Variables #########
var is_ready: bool = false
var default_toggle_text: String

######### Children #########
@onready var toggle_camera_button = $FlowContainer/Toggle

######### Camera Group Signals #########
func on_camera_mode_changed(new_mode: bool) -> void:
	default_toggle_text = "Top Down" if new_mode else "Isometric"
	if is_ready:
		toggle_camera_button.text = default_toggle_text

######### Signals #########
## Called when the node enters the scene tree for the first time.
func _ready():
	is_ready = true
	toggle_camera_button.text = default_toggle_text
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
func _on_tavern_pressed():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.TAVERN)
	pass # Replace with function body.

func _on_stable_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.STABLE)
	pass # Replace with function body.

func _on_inn_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.INN)
	pass # Replace with function body.

func _on_bridge_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.BRIDGE)
	pass # Replace with function body.

func _on_square_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.SQUARE)
	pass # Replace with function body.
	
func _on_manor_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.MANOR)
	pass # Replace with function body.

func _on_abbey_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.LIGHT_ABBEY)
	pass # Replace with function body.

func _on_academy_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.LIGHT_ACADEMY)
	pass # Replace with function body.

func _on_infirmary_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.INFIRMARY)
	pass # Replace with function body.

func _on_castle_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.CASTLE)
	pass # Replace with function body.
	
func _on_tower_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.TOWER)
	pass # Replace with function body.

func _on_cathedral_button_down():
	get_tree().call_group("board", "hud_begin_piece_placement", Globals.Piece.CATHEDRAL)
	pass # Replace with function body.
