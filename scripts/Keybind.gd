extends BoxContainer

@export_group("Properties")
@export var hotkey: String
@export var hint: String

# children
@onready var keybind_label = $Keybind/Label
@onready var hint_label = $Label

func _ready():
	keybind_label.text = hotkey
	hint_label.text = hint
