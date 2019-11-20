tool
extends ColorRect

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_loading_visibility_changed():
	if visible:
		$loading2.material.set_shader_param("speed",5)
	else:
		$loading2.material.set_shader_param("speed",0)
