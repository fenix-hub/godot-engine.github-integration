# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends EditorPlugin
var doc = preload("../scenes/GitHub.tscn")
var IconLoaderGithub = preload("res://addons/github-integration/scripts/IconLoaderGithub.gd").new()
var UserData = preload("res://addons/github-integration/scripts/user_data.gd").new()
var GitHubDoc

func _enter_tree():
	self.add_autoload_singleton("UserData","res://addons/github-integration/scripts/user_data.gd")
	self.add_autoload_singleton("IconLoaderGithub","res://addons/github-integration/scripts/IconLoaderGithub.gd")
	GitHubDoc = doc.instance()
	get_editor_interface().get_editor_viewport().add_child(GitHubDoc)
	GitHubDoc.hide()


func _exit_tree():
	self.remove_autoload_singleton("UserData")
	self.remove_autoload_singleton("IconLoaderGithub")
	get_editor_interface().get_editor_viewport().remove_child(GitHubDoc)

func has_main_screen():
	return true

func get_plugin_name():
	return "GitHub"

func get_plugin_icon():
	return IconLoaderGithub.load_icon_from_name("githubicon")

func make_visible(visible):
	GitHubDoc.visible = visible

