# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot.git-integration
# [version] 0.0.1
# [date] 2019 - 
# 
# {versioning: <grandi-cambiamenti>.<nuovi-contenuti>.<fix-patch> }





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
	remove_autoload_singleton("UserData")
	doc.queue_free()