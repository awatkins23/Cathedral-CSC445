extends Node
# Manages loading of and transition between major scenes.
# Credit: https://github.com/thelastflapjack/godot_open_star_fighter/blob/master/src/autoloads/scene_switcher/scene_switcher.gd

### Private variables ###
var _load_target_path: String
const _poll_time: float = 0.02
const _level_dir_path: String = "res://scenes/"
const _main_menu_file_path: String = "res://scenes/main_menu.tscn"

### Children ###
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _fade_rect: ColorRect = $UI/FadeRect
@onready var _poll_timer := $PollTimer

############################
#      Public Methods      #
############################
func transition_to_level(level_name: String) -> void:
	_change_scene_background("%s%s.tscn" % [_level_dir_path, level_name])

func transition_to_main_menu() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_change_scene_background(_main_menu_file_path)

func _ready():
	_poll_timer.one_shot = true
	_poll_timer.wait_time = _poll_time

# Fades in the Fade ColorRect
func _fade_in() -> void:
	_animation_player.play("fade_in")

func _fade_out() -> void:
	_animation_player.play_backwards("fade_in")

############################
# Signal Connected Methods #
############################
func _on_change_scene_request(scene_res_path: String) -> void:
	call_deferred("_change_scene_background", scene_res_path)

func _on_poll_timer_timeout():
	var load_progress: Array[float] = []
	var load_status: int = ResourceLoader.load_threaded_get_status(_load_target_path, load_progress)

	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene_res: PackedScene = ResourceLoader.load_threaded_get(_load_target_path)
		_set_current_scene(scene_res.instantiate())
	elif load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_poll_timer.start()
	else:
		@warning_ignore("assert_always_false")
		assert(false, "ResourceInteractiveLoader Error: " + str(load_status))

func _set_current_scene(new_scene: Node) -> void:
	get_tree().get_root().add_child(new_scene)
	get_tree().current_scene = new_scene
	
	if _animation_player.is_playing():
		await _animation_player.animation_finished
	_fade_in()

func _change_scene_background(new_scene_path: String) -> void:
	_load_target_path = new_scene_path
	
	# fade out animation
	_fade_out()
	await _animation_player.animation_finished
	
	# delete the current scene
	var current_scene: Node = get_tree().current_scene
	if (current_scene != null):
		current_scene.queue_free()
	get_tree().current_scene = null

	var err: int = ResourceLoader.load_threaded_request(_load_target_path, "PackedScene")
	assert(err == OK, "ResourceLoader.LoadThreadedRequest failed. Attemped load target path: " + _load_target_path)
	_poll_timer.start()

