extends Control

@export_group("Properties")
@export var state: Globals.GameWinState
@export var light_points: int
@export var dark_points: int

@export_group("Animation")
@export var read_time: float = 1
@export var animator: AnimationPlayer
const ease_time: float = 0.25

@export_group("Labels")
@export var dark_label_settings: LabelSettings
@export var light_label_settings: LabelSettings
@export var draw_label_settings: LabelSettings

# children
@onready var _title_label: Label = $Container/TitleContainer/Title
@onready var _light_points_label: Label = $Container/LightPointsContainer/LightPoints
@onready var _dark_points_label: Label = $Container/DarkPointsContainer/DarkPoints
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

# patterns
var _points_pattern = "%s Points: %s"

# Called when the node enters the scene tree for the first time.
func _ready():
	# set title
	match state:
		Globals.GameWinState.DARK:
			_title_label.label_settings = dark_label_settings
			_title_label.text = "DARK VICTORY"
		Globals.GameWinState.LIGHT:
			_title_label.label_settings = light_label_settings
			_title_label.text = "LIGHT VICTORY"
		Globals.GameWinState.DRAW:
			_title_label.label_settings = draw_label_settings
			_title_label.text = "DRAW"
	
	# set points
	_light_points_label.text = _points_pattern % ["Light", light_points]
	_dark_points_label.text = _points_pattern % ["Dark", dark_points]
	
	_animation_player.play("game_end_in")
	
func _on_main_menu_button_pressed():
	SceneSwitcher.transition_to_main_menu()
