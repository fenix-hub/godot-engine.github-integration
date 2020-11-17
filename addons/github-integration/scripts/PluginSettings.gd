tool
extends Node

var directory_name = "github_integration"
var plugin_path : String = ProjectSettings.globalize_path("user://").replace("app_userdata/"+ProjectSettings.get_setting('application/config/name')+"/",directory_name)+"/"

var setting_file : String = "settings.cfg"

var debug : bool = true
var auto_log : bool = false
var darkmode : bool = false
var auto_update_notifications : bool = true
var auto_update_timer : float = 300

func _ready():
	var config_file : ConfigFile = ConfigFile.new()
	var err = config_file.load(plugin_path+setting_file)
	if err == 0:
		debug = config_file.get_value("settings","debug", debug)
		auto_log = config_file.get_value("settings","auto_log", auto_log)
		darkmode = config_file.get_value("settings","darkmode", darkmode)
		auto_update_notifications = config_file.get_value("settings","auto_update_notifications", auto_update_notifications)
		auto_update_timer = config_file.get_value("settings","auto_update_timer",auto_update_timer)
	else:
		print("settings not found")
		config_file.save(plugin_path+setting_file)
		config_file.set_value("settings","debug",debug)
		config_file.set_value("settings","auto_log",auto_log)
		config_file.set_value("settings","darkmode",darkmode)
		config_file.set_value("settings","auto_update_notifications", auto_update_notifications)
		config_file.set_value("settings","auto_update_timer",auto_update_timer)
		config_file.save(plugin_path+setting_file)

func set_debug(d : bool):
	debug = d
	save_setting("debug", debug)

func set_auto_log(a : bool):
	auto_log = a
	save_setting("auto_log", auto_log)

func set_darkmode(d : bool):
	darkmode = d
	save_setting("darkmode", darkmode)

func set_auto_update_notifications(enabled : bool):
	auto_update_notifications = enabled
	save_setting("auto_update_notifications", enabled)

func set_auto_update_timer(timer : float):
	auto_update_timer = timer
	save_setting("auto_update_timer", timer)

func save_setting(key : String, value):
	var file : ConfigFile = ConfigFile.new()
	var err = file.load(plugin_path+setting_file)
	if err == OK:
		file.set_value("settings",key,value)
	file.save(plugin_path+setting_file)

func get_setting(key : String, default_value = ""):
	var file : ConfigFile = ConfigFile.new()
	var err = file.load(plugin_path+setting_file)
	if err == OK:
		if file.has_section_key("settings","key"):
			return file.get_value("settings","key")
		else:
			print("setting '%s' not found, now created" % key)
			file.set_value("settings", key, default_value)
