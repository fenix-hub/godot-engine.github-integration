# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends EditorPlugin
var doc = preload("../scenes/GitHub.tscn").instance()
var IconLoaderGithub = preload("res://addons/github-integration/scripts/IconLoaderGithub.gd").new()

func _enter_tree():
	add_autoload_singleton("UserData","res://addons/github-integration/scripts/user_data.gd")
	add_autoload_singleton("IconLoaderGithub","res://addons/github-integration/scripts/IconLoaderGithub.gd")
	get_editor_interface().get_editor_viewport().add_child(doc)
	doc.hide()


func _exit_tree():
	get_editor_interface().get_editor_viewport().remove_child(doc)
	remove_autoload_singleton("UserData")
	remove_autoload_singleton("IconLoaderGithub")

func has_main_screen():
	return true

func get_plugin_name():
	return "GitHub"

func get_plugin_icon():
	return IconLoaderGithub.load_icon_from_name("githubicon")

func make_visible(visible):
	doc.visible = visible

