tool
extends HBoxContainer

const ADDONS_PATH = "res://addons/"
const PLUGIN_PATH = "godot-plugin-refresher"

signal request_refresh_plugin(p_name)
signal confirm_refresh_plugin(p_name)

onready var options = $OptionButton

func _ready():
	$RefreshButton.icon = get_icon('Reload', 'EditorIcons')
	reload_items()

func reload_items():
	if not options:
		return
	var dir = Directory.new()
	dir.change_dir(ADDONS_PATH)
	dir.list_dir_begin(true, true)
	var file = dir.get_next()
	options.clear()
	while file:
		if dir.dir_exists(ADDONS_PATH.plus_file(file)) and file != PLUGIN_PATH:
			options.add_item(file)
		file = dir.get_next()

func select_plugin(p_name):
	if not options:
		return
	if p_name == null or p_name.empty():
		return

	for idx in options.get_item_count():
		var plugin = options.get_item_text(idx)
		if plugin == p_name:
			options.selected = options.get_item_id(idx)
			break

func _on_RefreshButton_pressed():
	if options.selected == -1:
		return # nothing selected

	var plugin = options.get_item_text(options.selected)
	if not plugin or plugin.empty():
		return
	emit_signal("request_refresh_plugin", plugin)

func show_warning(p_name):
	$ConfirmationDialog.dialog_text = """
		Plugin `%s` is currently disabled.\n
		Do you want to enable it now?
	""" % [p_name]
	$ConfirmationDialog.popup_centered()

func _on_ConfirmationDialog_confirmed():
	var plugin = options.get_item_text(options.selected)
	emit_signal('confirm_refresh_plugin', plugin)

