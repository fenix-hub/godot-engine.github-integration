# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends EditorPlugin
var doc

func _enter_tree():
	doc = preload("../scenes/GitHub.tscn").instance()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR,doc)
	add_autoload_singleton("UserData","res://addons/github-integration/scripts/user_data.gd")

func _exit_tree():
	remove_control_from_docks(doc)
	doc.queue_free()