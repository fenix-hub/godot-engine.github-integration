tool
extends EditorPlugin

# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot.git-integration
# [version] 0.0.1
# [date] 2019 - 





# -----------------------------------------------

var doc

func _enter_tree():
	doc = preload("../scenes/GitHub.tscn").instance()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR,doc)

func _exit_tree():
	remove_control_from_docks(doc)
	doc.queue_free()