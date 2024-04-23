extends Control

@export_group("Properties")
@export var piece_type: Globals.Piece
@export var piece_name: String
@export var texture: CompressedTexture2D
@export var texture_color: Color = Color.WHITE

@export_group("Animations")
@export var enter_animation_delay: float = 0.0

# children
@onready var _button = $Button
@onready var _piece_name_label = $Button/BoxContainer/PieceName
@onready var _piece_texture_rect = $Button/BoxContainer/PieceTexture
@onready var _animator = $AnimationPlayer
@onready var _enter_timer = $EnterTimer

var _entered: bool = false

func _enter():
	_animator.play("piece_button_enter")
	_button.visible = true
	_entered = true
	_enter_timer.queue_free()

func _ready():
	_button.visible = false
	_piece_name_label.text = piece_name
	_piece_texture_rect.texture = texture
	_piece_texture_rect.modulate = texture_color
	
	_animator.play("piece_button_enter_default")
	if enter_animation_delay == 0.0:
		_enter()
	else:
		# set timer properties
		_enter_timer.wait_time = enter_animation_delay
		_enter_timer.start()

######### Signals #########
func _on_button_button_up():
	if _entered:
		get_tree().call_group("hud", "hud_on_piece_button_up", piece_type)

func _on_button_button_down():
	if _entered:
		get_tree().call_group("hud", "hud_on_piece_button_down", piece_type)

func _on_button_focus_entered():
	if _entered:
		_animator.play("piece_button_hover_start")

func _on_button_focus_exited():
	if _entered:
		_animator.play("piece_button_hover_end")

func _on_button_mouse_entered():
	if _entered:
		_animator.play("piece_button_hover_start")

func _on_button_mouse_exited():
	if _entered:
		_animator.play("piece_button_hover_end")

func _on_enter_timer_timeout():
	_enter()
