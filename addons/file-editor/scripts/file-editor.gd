tool
extends EditorPlugin

var doc = preload("../scenes/FileEditor.tscn").instance()

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()

func _enter_tree():
	add_autoload_singleton("IconLoader","res://addons/file-editor/scripts/IconLoader.gd")
	add_autoload_singleton("LastOpenedFiles","res://addons/file-editor/scripts/LastOpenedFiles.gd")
	get_editor_interface().get_editor_viewport().add_child(doc)
	doc.hide()

func _exit_tree():
	doc.clean_editor()
	get_editor_interface().get_editor_viewport().remove_child(doc)
	remove_autoload_singleton("IconLoader")
	remove_autoload_singleton("LastOpenedFiles")

func has_main_screen():
	return true

func get_plugin_name():
	return "File"

func get_plugin_icon():
	return IconLoader.load_icon_from_name("file")

func make_visible(visible):
	doc.visible = visible
