class_name Piece
extends Node3D

@export_category("Piece Data")
@export var type: Globals.Piece = Globals.Piece.TAVERN
@export var shape: Array[Vector2] = []
@export var mesh: MeshInstance3D
@export var material: Material:
	set(value):
		mesh.set_surface_override_material(0, value)
		material = value
@export var animator: AnimationPlayer

@export_category("Board Data")
@export var team: Globals.Team = Globals.Team.LIGHT
@export var column: int = 0
@export var row: int = 0

######### Private Functions #########
#func _refresh_material():
	#match team:
		#Globals.Team.LIGHT:
			#mesh.set_surface_override_material(0, load("res://materials/LightPiece.tres"))
		#Globals.Team.DARK:
			#mesh.set_surface_override_material(0, load("res://materials/DarkPiece.tres"))
		#Globals.Team.CATHEDRAL:
			#mesh.set_surface_override_material(0, load("res://materials/Cathedral.tres"))

######### Public Functions #########
func get_shape_rotated(rotation: float) -> Array[Vector2]:
	var rotated: Array[Vector2] = []
	for n in shape.size():
		var rotated_offset = shape[n]
		match fmod(rotation, 360.0):
			90.0:
				rotated_offset = Vector2(rotated_offset[1], -rotated_offset[0])
			180.0:
				rotated_offset = Vector2(-rotated_offset[0], -rotated_offset[1])
			270.0:
				rotated_offset = Vector2(-rotated_offset[1], rotated_offset[0])
		rotated.append(rotated_offset)
	return rotated
		
func _ready():
	#_refresh_material()
	pass # Replace with function body.

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass
