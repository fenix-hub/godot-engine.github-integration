tool
extends ColorRect

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var Progress = $VBoxContainer/ProgressBar
onready var Number = $VBoxContainer/Number
onready var message : Label = $VBoxContainer/Message
# Called when the node enters the scene tree for the first time.
func _ready():
	Progress.hide()
	Number.hide()
	RestHandler.loading = self

func _on_loading_visibility_changed():
	if visible:
		$VBoxContainer/loading2.show()
		$VBoxContainer/loading2.material.set_shader_param("speed",5)
	else:
		Progress.hide()
		Progress.set_value(0)
		Number.hide()
		Number.set_text("...")
		$VBoxContainer/loading2.material.set_shader_param("speed",0)

func show_progress(value : float , max_value : float):
	Progress.show()
	Progress.set_value(range_lerp(value,0,max_value,0,100))

func hide_progress():
	Progress.hide()

func show_number(value : float , ref_value : float, type : String):
	Number.show()
	Number.set_text(str(value)+" "+type+" downloaded (of ~"+str(ref_value)+" "+type+")")

func hide_number():
	Number.hide()
