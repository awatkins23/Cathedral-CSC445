extends Control

@export_group("Properties")
@export var piece_type: Globals.Piece
@export var piece_name: String
@export var texture: CompressedTexture2D
@export var texture_color: Color = Color.WHITE

# children
@onready var _piece_name_label = $Button/BoxContainer/PieceName
@onready var _piece_texture_rect = $Button/BoxContainer/PieceTexture
@onready var _animator = $AnimationPlayer

## Called when the node enters the scene tree for the first time.
func _ready():
	_piece_name_label.text = piece_name
	_piece_texture_rect.texture = texture
	_piece_texture_rect.modulate = texture_color

######### Signals #########
func _on_button_button_up():
	get_tree().call_group("hud", "hud_on_piece_button_up", piece_type)

func _on_button_button_down():
	get_tree().call_group("hud", "hud_on_piece_button_down", piece_type)

func _on_button_focus_entered():
	_animator.play("piece_button_hover_start")

func _on_button_focus_exited():
	_animator.play("piece_button_hover_end")

func _on_button_mouse_entered():
	_animator.play("piece_button_hover_start")

func _on_button_mouse_exited():
	_animator.play("piece_button_hover_end")
