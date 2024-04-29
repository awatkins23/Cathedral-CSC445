extends Control

@export_group("Properties")
@export var title: String
@export var subtitle: String

@export_group("Animation")
@export var read_time: float = 1
@export var animator: AnimationPlayer
const ease_time: float = 0.25

# enums
enum State {
	NONE,
	IN,
	READ,
	OUT
}

var _current_state = State.NONE

# children
@onready var timer = $AnimationTimer
@onready var title_label = $Container/Title
@onready var subtitle_label = $Container/Subtitle

# functions
func _start_timer(time: float) -> void:
	timer.wait_time = time
	timer.start()

# Called when the node enters the scene tree for the first time.
func _ready():
	title_label.text = title
	subtitle_label.text = subtitle
	
	animator.play("DEFAULT")
	_on_animation_timer_timeout()

func _on_animation_timer_timeout():
	match _current_state:
		State.NONE:
			_current_state = State.IN
			animator.play("turn_in")
			_start_timer(ease_time)
		State.IN:
			_current_state = State.READ
			_start_timer(read_time)
		State.READ:
			_current_state = State.OUT
			animator.play("turn_out")
			_start_timer(ease_time)
		State.OUT:
			queue_free()
			
