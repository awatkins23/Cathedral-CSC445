extends Control

# children
@onready var _select_sound_player = $SelectSoundPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_singleplayer_button_pressed():
	_select_sound_player.play()
	SceneSwitcher.transition_to_level('singleplayer')

func _on_singleplayer_button_2_pressed():
	_select_sound_player.play()
	SceneSwitcher.transition_to_level('multiplayer')
